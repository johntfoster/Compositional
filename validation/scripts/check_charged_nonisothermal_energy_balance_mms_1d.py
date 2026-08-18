#!/usr/bin/env python3
"""Check the stationary 1D solid-reference thermal energy-balance MMS."""

from __future__ import annotations

import csv
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
APP_DIR = ROOT / "moose_app"
APP = APP_DIR / "multicomponent_reactive_flow-opt"
DECK = (
    APP_DIR
    / "test"
    / "tests"
    / "charged_nonisothermal_transport"
    / "charged_nonisothermal_energy_balance_1d.i"
)

TOLERANCE = 1.0e-10
ERROR_COLUMNS = (
    "ux_l2",
    "temperature_backbone_l2",
    "temperature_total_l2",
    "temperature_gradient_l2",
    "neutral_potential_total_l2",
    "neutral_potential_gradient_l2",
    "electric_potential_gradient_l2",
    "thermal_conductivity_l2",
    "current_heat_flux_l2",
    "reference_heat_flux_l2",
    "reference_heat_flux_divergence_l2",
    "reference_electric_work_l2",
    "reference_heat_supply_l2",
    "reference_energy_source_l2",
    "local_energy_balance_residual_l2",
    "local_energy_balance_residual_integral",
    "direct_global_energy_balance",
)
EXPECTED_VALUES = {
    "reference_heat_flux_divergence_integral": -1.0,
    "reference_electric_work_integral": 10.45,
    "reference_heat_supply_integral": -11.45,
    "reference_energy_source_integral": -1.0,
    "left_reference_heat_flux_x": -3.5,
    "right_reference_heat_flux_x": -4.5,
    "net_outward_reference_heat_flux": -1.0,
}
GAUGE_INVARIANT_COLUMNS = ERROR_COLUMNS + tuple(EXPECTED_VALUES)


def run_case(output_base: Path, gauge_shift: float) -> dict[str, float]:
    subprocess.run(
        [
            str(APP),
            "-i",
            str(DECK),
            f"Outputs/file_base={output_base}",
            "Functions/electric_potential_enrichment_exact/expression="
            + str(5.0 + gauge_shift),
        ],
        cwd=APP_DIR,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    with Path(str(output_base) + ".csv").open(newline="") as handle:
        rows = list(csv.DictReader(handle))
    if not rows:
        raise SystemExit("stationary energy-balance MMS produced no CSV rows")
    return {name: float(value) for name, value in rows[-1].items()}


def main() -> int:
    if not APP.exists():
        raise SystemExit(f"missing optimized executable: {APP}")

    with tempfile.TemporaryDirectory(prefix="charged_nonisothermal_energy_mms_1d_") as tmp:
        tmp_path = Path(tmp)
        base = run_case(tmp_path / "base", 0.0)
        shifted = run_case(tmp_path / "shifted", 100.0)

    required = ERROR_COLUMNS + tuple(EXPECTED_VALUES)
    missing = [name for name in required if name not in base or name not in shifted]
    if missing:
        raise SystemExit("stationary energy-balance MMS omitted: " + ", ".join(missing))

    failures = [
        f"{name}={abs(base[name]):.6e} > {TOLERANCE:.1e}"
        for name in ERROR_COLUMNS
        if abs(base[name]) > TOLERANCE
    ]
    value_errors: dict[str, float] = {}
    for name, expected in EXPECTED_VALUES.items():
        value_errors[name] = abs(base[name] - expected)
        if value_errors[name] > TOLERANCE:
            failures.append(
                f"{name}_error={value_errors[name]:.6e} > {TOLERANCE:.1e}"
            )

    nonzero_terms = (
        "reference_heat_flux_divergence_integral",
        "reference_electric_work_integral",
        "reference_heat_supply_integral",
        "left_reference_heat_flux_x",
        "right_reference_heat_flux_x",
    )
    for name in nonzero_terms:
        if abs(base[name]) <= TOLERANCE:
            failures.append(f"{name} must be independently nonzero")

    gauge_errors = {
        name: abs(base[name] - shifted[name]) for name in GAUGE_INVARIANT_COLUMNS
    }
    for name, error in gauge_errors.items():
        if error > TOLERANCE:
            failures.append(f"{name}_gauge_error={error:.6e} > {TOLERANCE:.1e}")

    if failures:
        raise SystemExit("1D stationary thermal energy-balance MMS failed: " + "; ".join(failures))

    maximum_error = max(
        max(abs(base[name]) for name in ERROR_COLUMNS),
        max(value_errors.values()),
        max(gauge_errors.values()),
    )
    print(
        "charged_nonisothermal_energy_balance_mms_1d: "
        f"maximum_error={maximum_error:.6e}, "
        "DivQ_integral=-1, electric_work_integral=10.45, "
        "heat_supply_integral=-11.45, left_Qx=-3.5, right_Qx=-4.5, "
        "direct_global_balance=0, gauge_shift=100, "
        f"tolerance={TOLERANCE:.1e}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
