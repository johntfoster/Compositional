#!/usr/bin/env python3
"""Compare MOOSE SPE1 FV output with pinned OPM report-step results."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path


SECONDS_PER_DAY = 86400.0
M3_PER_STB = 0.158987294928
SCF_PER_SM3 = 35.3146667215
PA_PER_PSI = 6894.757293168
SCF_PER_STB_PER_SM3_PER_SM3 = 5.614583333333
MINIMUM_GAS_SATURATION = -1e-12
GLOBAL_BALANCE_ABSOLUTE_TOLERANCE = 1e-8
RATE_CONTROL_ABSOLUTE_TOLERANCE = 1e-8
BHP_CONTROL_ABSOLUTE_TOLERANCE_PA = 1.0
TARGET_GAS_INJECTION_M3_PER_S = 32.774128
TARGET_OIL_PRODUCTION_M3_PER_S = 0.03680261456666667
INJECTOR_MAXIMUM_BHP_PA = 62149342.24061635
PRODUCER_MINIMUM_BHP_PA = 6894757.293168

MAPPINGS = {
    "field_oil_rate_stb_per_day": (
        "producer_oil_surface_rate",
        SECONDS_PER_DAY / M3_PER_STB,
    ),
    "field_gor_mscf_per_stb": (
        "field_gas_oil_ratio",
        SCF_PER_STB_PER_SM3_PER_SM3 / 1000.0,
    ),
    "injector_cell_pressure_psia": ("injector_cell_pressure", 1.0 / PA_PER_PSI),
    "producer_cell_pressure_psia": ("producer_cell_pressure", 1.0 / PA_PER_PSI),
    "producer_cell_gas_saturation": ("gas_saturation_10_10_3", 1.0),
    "injector_bhp_psia": ("injector_bhp", 1.0 / PA_PER_PSI),
    "producer_bhp_psia": ("producer_bhp", 1.0 / PA_PER_PSI),
    "injector_gas_rate_mscf_per_day": (
        "injected_gas_surface_rate",
        SECONDS_PER_DAY * SCF_PER_SM3 / 1000.0,
    ),
    "producer_oil_rate_stb_per_day": (
        "producer_oil_surface_rate",
        SECONDS_PER_DAY / M3_PER_STB,
    ),
    "producer_gas_rate_mscf_per_day": (
        "producer_gas_surface_rate",
        SECONDS_PER_DAY * SCF_PER_SM3 / 1000.0,
    ),
    "produced_oil_volume_stb": ("produced_oil_surface_volume", 1.0 / M3_PER_STB),
    "produced_gas_volume_mscf": (
        "produced_gas_surface_volume",
        SCF_PER_SM3 / 1000.0,
    ),
}


def read_csv(path: Path) -> list[dict[str, float]]:
    with path.open(newline="", encoding="utf-8") as stream:
        return [
            {name: float(value) for name, value in row.items()}
            for row in csv.DictReader(stream)
        ]


def interpolate(rows: list[dict[str, float]], time: float, field: str) -> float:
    if time < rows[0]["time"] or time > rows[-1]["time"]:
        raise ValueError(f"time {time} lies outside MOOSE output")
    upper = 0
    while upper < len(rows) and rows[upper]["time"] < time:
        upper += 1
    if rows[upper]["time"] == time or upper == 0:
        return rows[upper][field]
    lower = upper - 1
    fraction = (time - rows[lower]["time"]) / (
        rows[upper]["time"] - rows[lower]["time"]
    )
    return rows[lower][field] + fraction * (
        rows[upper][field] - rows[lower][field]
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--moose-csv", required=True, type=Path)
    parser.add_argument("--opm-csv", required=True, type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--expected-end-day", default=3650.0, type=float)
    parser.add_argument("--cumulative-relative-tolerance", default=5e-3, type=float)
    parser.add_argument("--rate-pressure-relative-tolerance", default=2e-2, type=float)
    parser.add_argument(
        "--bhp-relative-tolerance",
        default=2e-2,
        type=float,
        help=(
            "Relative tolerance for injector/producer BHP against the pinned OPM rows.  "
            "The FV-diagnostic deck inherits its default from the rate/pressure bound "
            "(2e-2); callers that document a known cell-state mismatch may widen only "
            "this BHP bound without relaxing rate, pressure, volume, or GOR gates."
        ),
    )
    args = parser.parse_args()

    moose = read_csv(args.moose_csv)
    opm = read_csv(args.opm_csv)
    expected_end_time = args.expected_end_day * SECONDS_PER_DAY
    if moose[-1]["time"] != expected_end_time:
        raise ValueError(f"MOOSE output does not end at SPE1 day {args.expected_end_day:g}")

    comparison: list[dict[str, float | str]] = []
    maxima: dict[str, float] = {}
    compared_reference_rows = [
        reference for reference in opm if reference["time_days"] <= args.expected_end_day
    ]
    if not compared_reference_rows or compared_reference_rows[-1]["time_days"] != args.expected_end_day:
        raise ValueError(f"OPM reference has no report row at day {args.expected_end_day:g}")
    for reference in compared_reference_rows:
        time_seconds = reference["time_days"] * SECONDS_PER_DAY
        for metric, (moose_field, scale) in MAPPINGS.items():
            moose_value = interpolate(moose, time_seconds, moose_field) * scale
            opm_value = reference[metric]
            absolute_error = moose_value - opm_value
            relative_error = (
                abs(absolute_error) / abs(opm_value) if opm_value != 0.0 else 0.0
            )
            maxima[metric] = max(maxima.get(metric, 0.0), relative_error)
            comparison.append(
                {
                    "time_days": reference["time_days"],
                    "metric": metric,
                    "moose": moose_value,
                    "opm": opm_value,
                    "absolute_error": absolute_error,
                    "relative_error": relative_error,
                }
            )

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with args.output.open("w", newline="", encoding="utf-8") as stream:
            writer = csv.DictWriter(stream, fieldnames=comparison[0].keys())
            writer.writeheader()
            writer.writerows(comparison)
    for metric, error in maxima.items():
        print(f"{metric}: max_relative_error={error:.8e}")
    failures: list[str] = []
    for row in moose:
        time_days = row["time"] / SECONDS_PER_DAY
        if row["minimum_gas_saturation"] < MINIMUM_GAS_SATURATION:
            failures.append(
                f"day {time_days:g} minimum_gas_saturation="
                f"{row['minimum_gas_saturation']:.8e} < {MINIMUM_GAS_SATURATION:.8e}"
            )
        for component in ("water", "oil", "gas"):
            defect = abs(row[f"{component}_global_balance"])
            if defect > GLOBAL_BALANCE_ABSOLUTE_TOLERANCE:
                failures.append(
                    f"day {time_days:g} {component}_global_balance="
                    f"{defect:.8e} > {GLOBAL_BALANCE_ABSOLUTE_TOLERANCE:.8e}"
                )
        injector_rate_error = abs(
            abs(row["injected_gas_surface_rate"]) - TARGET_GAS_INJECTION_M3_PER_S
        )
        producer_rate_error = abs(
            abs(row["producer_oil_surface_rate"]) - TARGET_OIL_PRODUCTION_M3_PER_S
        )
        injector_on_bhp = (
            row["injector_bhp"] >= INJECTOR_MAXIMUM_BHP_PA - BHP_CONTROL_ABSOLUTE_TOLERANCE_PA
        )
        producer_on_bhp = (
            row["producer_bhp"] <= PRODUCER_MINIMUM_BHP_PA + BHP_CONTROL_ABSOLUTE_TOLERANCE_PA
        )
        if not injector_on_bhp and injector_rate_error > RATE_CONTROL_ABSOLUTE_TOLERANCE:
            failures.append(
                f"day {time_days:g} injector_rate_control_error="
                f"{injector_rate_error:.8e} > {RATE_CONTROL_ABSOLUTE_TOLERANCE:.8e}"
            )
        if not producer_on_bhp and producer_rate_error > RATE_CONTROL_ABSOLUTE_TOLERANCE:
            failures.append(
                f"day {time_days:g} producer_rate_control_error="
                f"{producer_rate_error:.8e} > {RATE_CONTROL_ABSOLUTE_TOLERANCE:.8e}"
            )
        if row["injector_bhp"] > INJECTOR_MAXIMUM_BHP_PA + BHP_CONTROL_ABSOLUTE_TOLERANCE_PA:
            failures.append(
                f"day {time_days:g} injector_bhp={row['injector_bhp']:.8e} exceeds "
                f"{INJECTOR_MAXIMUM_BHP_PA:.8e}"
            )
        if row["producer_bhp"] < PRODUCER_MINIMUM_BHP_PA - BHP_CONTROL_ABSOLUTE_TOLERANCE_PA:
            failures.append(
                f"day {time_days:g} producer_bhp={row['producer_bhp']:.8e} is below "
                f"{PRODUCER_MINIMUM_BHP_PA:.8e}"
            )
    for metric, error in maxima.items():
        if metric.startswith("produced_") and metric.endswith(("_volume_stb", "_volume_mscf")):
            tolerance = args.cumulative_relative_tolerance
        elif "bhp" in metric:
            tolerance = args.bhp_relative_tolerance
        elif "rate" in metric or "pressure" in metric or "gor" in metric:
            tolerance = args.rate_pressure_relative_tolerance
        else:
            continue
        if error > tolerance:
            failures.append(f"{metric}={error:.8e} > {tolerance:.8e}")
    if failures:
        print("SPE1 OPM comparison failed: " + "; ".join(failures))
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
