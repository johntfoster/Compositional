#!/usr/bin/env python3
"""Report CG/EG SPE1 observables against the pinned OPM reference.

The comparison is descriptive evidence.  It is deliberately separate from
the governing-equation acceptance gates and never turns an OPM discrepancy
into permission to alter physics, tolerances, or discretization.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
from pathlib import Path

import matplotlib.pyplot as plt

from compare_spe1_fv_to_opm import MAPPINGS, SECONDS_PER_DAY, interpolate, read_csv


def write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    temporary.replace(path)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--moose-csv", required=True, type=Path)
    parser.add_argument("--opm-csv", required=True, type=Path)
    parser.add_argument("--comparison-csv", required=True, type=Path)
    parser.add_argument("--summary-json", required=True, type=Path)
    parser.add_argument("--figure-base", required=True, type=Path)
    parser.add_argument("--expected-end-day", default=3650.0, type=float)
    args = parser.parse_args()

    moose = read_csv(args.moose_csv)
    opm = read_csv(args.opm_csv)
    expected_end_time = args.expected_end_day * SECONDS_PER_DAY
    if not math.isclose(moose[-1]["time"], expected_end_time, abs_tol=1.0e-8):
        raise ValueError(f"MOOSE output does not end at SPE1 day {args.expected_end_day:g}")
    reference_rows = [row for row in opm if row["time_days"] <= args.expected_end_day]
    if not reference_rows or not math.isclose(
        reference_rows[-1]["time_days"], args.expected_end_day, abs_tol=1.0e-12
    ):
        raise ValueError("pinned OPM reference does not contain the requested final report day")

    comparisons: list[dict[str, float | str]] = []
    series: dict[str, dict[str, list[float]]] = {}
    metrics: dict[str, dict[str, float | int]] = {}
    for metric, (moose_field, scale) in MAPPINGS.items():
        times: list[float] = []
        moose_values: list[float] = []
        opm_values: list[float] = []
        absolute_errors: list[float] = []
        relative_errors: list[float] = []
        for reference in reference_rows:
            time_days = reference["time_days"]
            moose_value = interpolate(moose, time_days * SECONDS_PER_DAY, moose_field) * scale
            opm_value = reference[metric]
            absolute_error = moose_value - opm_value
            relative_error = (
                abs(absolute_error) / abs(opm_value) if abs(opm_value) > 0.0 else math.nan
            )
            times.append(time_days)
            moose_values.append(moose_value)
            opm_values.append(opm_value)
            absolute_errors.append(absolute_error)
            relative_errors.append(relative_error)
            comparisons.append(
                {
                    "time_days": time_days,
                    "metric": metric,
                    "moose_cg_eg": moose_value,
                    "opm": opm_value,
                    "absolute_error": absolute_error,
                    "relative_error": relative_error,
                }
            )
        finite_relative = [value for value in relative_errors if math.isfinite(value)]
        reference_scale = max(max(abs(value) for value in opm_values), 1.0e-300)
        metrics[metric] = {
            "samples": len(times),
            "maximum_absolute_error": max(abs(value) for value in absolute_errors),
            "maximum_relative_error_nonzero_reference": max(finite_relative, default=math.nan),
            "normalized_root_mean_square_error": (
                math.sqrt(sum(value * value for value in absolute_errors) / len(absolute_errors))
                / reference_scale
            ),
            "final_moose_cg_eg": moose_values[-1],
            "final_opm": opm_values[-1],
        }
        series[metric] = {"time_days": times, "moose": moose_values, "opm": opm_values}

    args.comparison_csv.parent.mkdir(parents=True, exist_ok=True)
    with args.comparison_csv.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=comparisons[0].keys())
        writer.writeheader()
        writer.writerows(comparisons)

    write_json(
        args.summary_json,
        {
            "benchmark": "SPE1 Case 1",
            "comparison_role": "physical-result comparison; not an acceptance gate",
            "discretization": "Q2 displacement, P1+P0 EG pressure, P2+P0 CG/EG saturations",
            "end_day": args.expected_end_day,
            "opm_report_rows": len(reference_rows),
            "metrics": metrics,
        },
    )

    figure, axes = plt.subplots(4, 3, figsize=(14, 12), constrained_layout=True)
    for axis, (metric, values) in zip(axes.flat, series.items()):
        axis.plot(values["time_days"], values["opm"], color="black", lw=1.8, label="OPM Flow 2021.10")
        axis.plot(values["time_days"], values["moose"], color="#0072B2", lw=1.4, label="MOOSE CG/EG")
        axis.set_title(metric.replace("_", " "), fontsize=9)
        axis.set_xlabel("time (days)")
        axis.grid(alpha=0.25)
    axes.flat[0].legend(fontsize=8)
    figure.suptitle("SPE1 Case 1: finite-deformation CG/EG result versus pinned OPM", fontsize=13)
    args.figure_base.parent.mkdir(parents=True, exist_ok=True)
    figure.savefig(args.figure_base.with_suffix(".png"), dpi=180)
    figure.savefig(args.figure_base.with_suffix(".svg"))
    plt.close(figure)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
