#!/usr/bin/env python3
"""Check the genuinely 2D two-component Q2/EG Onsager-matrix MMS."""

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
    / "charged_nonisothermal_onsager_matrix_2d.i"
)

TOLERANCE = 1.0e-10
DISSIPATION_TOLERANCE = 1.0e-12
ERROR_COLUMNS = (
    "ux_l2",
    "uy_l2",
    "neutral_potential_0_backbone_l2",
    "neutral_potential_0_enrichment_l2",
    "neutral_potential_0_total_l2",
    "neutral_potential_0_gradient_l2",
    "neutral_potential_1_backbone_l2",
    "neutral_potential_1_enrichment_l2",
    "neutral_potential_1_total_l2",
    "neutral_potential_1_gradient_l2",
    "electric_potential_backbone_l2",
    "electric_potential_enrichment_l2",
    "electric_potential_total_l2",
    "electric_potential_gradient_l2",
    "temperature_backbone_l2",
    "temperature_enrichment_l2",
    "temperature_total_l2",
    "temperature_gradient_l2",
    "transport_force_0_l2",
    "transport_force_1_l2",
    "current_component_0_flux_l2",
    "current_component_1_flux_l2",
    "reference_component_0_flux_l2",
    "reference_component_1_flux_l2",
    "onsager_reciprocity_l2",
    "onsager_positive_definite_determinant_l2",
    "onsager_dissipation_l2",
    "direct_summed_reference_component_0_l2",
    "direct_summed_reference_component_1_l2",
    "summed_reference_component_0_balance_l2",
    "summed_reference_component_1_balance_l2",
    "direct_summed_reference_component_0_global_balance",
    "direct_summed_reference_component_1_global_balance",
)
EXPECTED_VALUES = {
    "left_reference_component_0_flux_x": -2.2,
    "right_reference_component_0_flux_x": -2.2,
    "bottom_reference_component_0_flux_y": -3.575,
    "top_reference_component_0_flux_y": -3.575,
    "left_reference_component_1_flux_x": 0.9625,
    "right_reference_component_1_flux_x": 0.9625,
    "bottom_reference_component_1_flux_y": -7.7,
    "top_reference_component_1_flux_y": -7.7,
    "onsager_dissipation_average": 36.5,
}


def main() -> int:
    if not APP.exists():
        raise SystemExit(f"missing optimized executable: {APP}")

    with tempfile.TemporaryDirectory(prefix="charged_onsager_matrix_mms_2d_") as tmp:
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
        raise SystemExit("2D two-component Onsager MMS produced no CSV rows")
    final = {name: float(value) for name, value in rows[-1].items()}
    required = ERROR_COLUMNS + tuple(EXPECTED_VALUES)
    missing = [name for name in required if name not in final]
    if missing:
        raise SystemExit("2D two-component Onsager MMS omitted: " + ", ".join(missing))

    failures = [
        f"{name}={abs(final[name]):.6e} > {TOLERANCE:.1e}"
        for name in ERROR_COLUMNS
        if abs(final[name]) > TOLERANCE
    ]
    value_errors = {}
    for name, expected in EXPECTED_VALUES.items():
        error = abs(final[name] - expected)
        value_errors[name] = error
        if error > TOLERANCE:
            failures.append(f"{name}_error={error:.6e} > {TOLERANCE:.1e}")
    if final["onsager_dissipation_average"] < -DISSIPATION_TOLERANCE:
        failures.append(
            "onsager_dissipation_average="
            f"{final['onsager_dissipation_average']:.6e} "
            f"< -{DISSIPATION_TOLERANCE:.1e}"
        )
    if failures:
        raise SystemExit(
            "2D two-component Onsager Q2/EG MMS failed: " + "; ".join(failures)
        )

    maximum_error = max(abs(final[name]) for name in ERROR_COLUMNS)
    maximum_value_error = max(value_errors.values())
    print(
        "charged_nonisothermal_onsager_matrix_mms_2d: "
        f"maximum_error={maximum_error:.6e}, "
        f"maximum_face_or_value_error={maximum_value_error:.6e}, "
        "f0=(1.25,0.5), f1=(-1,4.5), "
        "L=(2,0.5;0.5,1.5), w0=(-2,-3.25), w1=(0.875,-7), "
        f"dissipation={final['onsager_dissipation_average']:.6e}, "
        "global_balances=("
        f"{final['direct_summed_reference_component_0_global_balance']:.6e},"
        f"{final['direct_summed_reference_component_1_global_balance']:.6e}), "
        f"tolerance={TOLERANCE:.1e}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
