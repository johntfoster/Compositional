#!/usr/bin/env python3
"""Quantitatively check the 3D nonlinear charged/nonisothermal TET10 Q2/EG MMS."""

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
    / "charged_nonisothermal_nonlinear_flux_3d.i"
)

TOLERANCE = 1.0e-10
ERROR_COLUMNS = (
    "ux_l2",
    "uy_l2",
    "uz_l2",
    "neutral_potential_backbone_l2",
    "neutral_potential_enrichment_l2",
    "neutral_potential_total_l2",
    "neutral_potential_gradient_l2",
    "electric_potential_backbone_l2",
    "electric_potential_enrichment_l2",
    "electric_potential_total_l2",
    "electric_potential_gradient_l2",
    "temperature_backbone_l2",
    "temperature_enrichment_l2",
    "temperature_total_l2",
    "temperature_gradient_l2",
    "mobility_l2",
    "summed_reference_component_storage_l2",
    "transport_force_vector_l2",
    "transport_force_x_l2",
    "transport_force_y_l2",
    "transport_force_z_l2",
    "current_flux_vector_l2",
    "current_flux_x_l2",
    "current_flux_y_l2",
    "current_flux_z_l2",
    "reference_flux_vector_l2",
    "reference_flux_x_l2",
    "reference_flux_y_l2",
    "reference_flux_z_l2",
    "charge_flux_vector_l2",
    "charge_flux_x_l2",
    "charge_flux_y_l2",
    "charge_flux_z_l2",
    "electric_work_l2",
    "reference_component_source_l2",
    "direct_reference_component_balance",
)
EXPECTED_INTEGRALS = {
    "transport_force_x_integral": 2.0,
    "transport_force_y_integral": 4.0,
    "transport_force_z_integral": 6.0,
    "current_flux_x_integral": -287.0 / 30.0,
    "current_flux_y_integral": -287.0 / 15.0,
    "current_flux_z_integral": -287.0 / 10.0,
    "reference_flux_x_integral": -34727.0 / 3000.0,
    "reference_flux_y_integral": -34727.0 / 1500.0,
    "reference_flux_z_integral": -34727.0 / 1000.0,
    "charge_flux_x_integral": -287.0 / 15.0,
    "charge_flux_y_integral": -574.0 / 15.0,
    "charge_flux_z_integral": -287.0 / 5.0,
    "left_reference_component_flux_x": -5687.0 / 600.0,
    "right_reference_component_flux_x": -41503.0 / 3000.0,
    "bottom_reference_component_flux_y": -22627.0 / 1500.0,
    "top_reference_component_flux_y": -48763.0 / 1500.0,
    "back_reference_component_flux_z": -17303.0 / 1000.0,
    "front_reference_component_flux_z": -56507.0 / 1000.0,
    "net_outward_reference_component_flux": -7623.0 / 125.0,
    "reference_component_source_integral": -7623.0 / 125.0,
}

NONZERO_COMPONENT_INTEGRALS = (
    "transport_force_x_integral",
    "transport_force_y_integral",
    "transport_force_z_integral",
    "current_flux_x_integral",
    "current_flux_y_integral",
    "current_flux_z_integral",
    "reference_flux_x_integral",
    "reference_flux_y_integral",
    "reference_flux_z_integral",
    "charge_flux_x_integral",
    "charge_flux_y_integral",
    "charge_flux_z_integral",
)


def main() -> int:
    if not APP.exists():
        raise SystemExit(f"missing optimized executable: {APP}")

    with tempfile.TemporaryDirectory(
        prefix="charged_nonisothermal_nonlinear_flux_mms_3d_"
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
        raise SystemExit("3D nonlinear charged/nonisothermal MMS produced no CSV rows")
    final = {name: float(value) for name, value in rows[-1].items()}
    required = ERROR_COLUMNS + tuple(EXPECTED_INTEGRALS)
    missing = [name for name in required if name not in final]
    if missing:
        raise SystemExit(
            "3D nonlinear charged/nonisothermal MMS omitted: " + ", ".join(missing)
        )

    failures = [
        f"{name}={abs(final[name]):.6e} > {TOLERANCE:.1e}"
        for name in ERROR_COLUMNS
        if abs(final[name]) > TOLERANCE
    ]
    integral_errors = {}
    for name, expected in EXPECTED_INTEGRALS.items():
        error = abs(final[name] - expected)
        integral_errors[name] = error
        if error > TOLERANCE:
            failures.append(f"{name}_error={error:.6e} > {TOLERANCE:.1e}")
    for name in NONZERO_COMPONENT_INTEGRALS:
        if abs(final[name]) <= TOLERANCE:
            failures.append(f"{name}={final[name]:.6e} is not demonstrably nonzero")
    if failures:
        raise SystemExit(
            "3D nonlinear charged/nonisothermal TET10 Q2/EG MMS failed: "
            + "; ".join(failures)
        )

    maximum_error = max(abs(final[name]) for name in ERROR_COLUMNS)
    maximum_integral_error = max(integral_errors.values())
    print(
        "charged_nonisothermal_nonlinear_flux_mms_3d: "
        f"maximum_error={maximum_error:.6e}, "
        f"maximum_integral_error={maximum_integral_error:.6e}, "
        "net_outward_flux=-60.984, source_integral=-60.984, "
        f"tolerance={TOLERANCE:.1e}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
