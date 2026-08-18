#!/usr/bin/env python3
"""Quantitatively check the 1D nonlinear charged/nonisothermal Q2/EG MMS."""

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
    / "charged_nonisothermal_nonlinear_flux_1d.i"
)

TOLERANCE = 1.0e-10
ERROR_COLUMNS = (
    "ux_l2",
    "neutral_potential_total_l2",
    "neutral_potential_gradient_l2",
    "electric_potential_total_l2",
    "electric_potential_gradient_l2",
    "temperature_total_l2",
    "temperature_gradient_l2",
    "mobility_l2",
    "component_balance_l2",
    "transport_force_x_l2",
    "current_flux_x_l2",
    "reference_flux_x_l2",
    "charge_flux_x_l2",
    "electric_work_l2",
    "reference_component_source_l2",
    "direct_reference_component_balance",
)
EXPECTED_INTEGRALS = {
    "net_outward_reference_component_flux": -3.8,
    "reference_component_source_integral": -3.8,
}


def main() -> int:
    if not APP.exists():
        raise SystemExit(f"missing optimized executable: {APP}")

    with tempfile.TemporaryDirectory(
        prefix="charged_nonisothermal_nonlinear_flux_mms_1d_"
    ) as tmp:
        output_base = Path(tmp) / "result"
        subprocess.run(
            [str(APP), "-i", str(DECK), f"Outputs/file_base={output_base}"],
            cwd=APP_DIR,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        with Path(str(output_base) + ".csv").open(newline="") as handle:
            rows = list(csv.DictReader(handle))

    if not rows:
        raise SystemExit("nonlinear charged/nonisothermal MMS produced no CSV rows")
    final = {name: float(value) for name, value in rows[-1].items()}
    required = ERROR_COLUMNS + tuple(EXPECTED_INTEGRALS)
    missing = [name for name in required if name not in final]
    if missing:
        raise SystemExit("nonlinear charged/nonisothermal MMS omitted: " + ", ".join(missing))

    failures = [
        f"{name}={abs(final[name]):.6e} > {TOLERANCE:.1e}"
        for name in ERROR_COLUMNS
        if abs(final[name]) > TOLERANCE
    ]
    for name, expected in EXPECTED_INTEGRALS.items():
        error = abs(final[name] - expected)
        if error > TOLERANCE:
            failures.append(f"{name}_error={error:.6e} > {TOLERANCE:.1e}")
    if failures:
        raise SystemExit(
            "1D nonlinear charged/nonisothermal Q2/EG MMS failed: "
            + "; ".join(failures)
        )

    maximum_error = max(abs(final[name]) for name in ERROR_COLUMNS)
    print(
        "charged_nonisothermal_nonlinear_flux_mms_1d: "
        f"maximum_error={maximum_error:.6e}, "
        "net_outward_flux=-3.8, source_integral=-3.8, "
        f"tolerance={TOLERANCE:.1e}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
