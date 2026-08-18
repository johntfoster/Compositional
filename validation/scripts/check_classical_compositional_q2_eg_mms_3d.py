#!/usr/bin/env python3
"""Check the genuinely 3D two-phase/two-component classical compositional MMS."""

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
    / "registered_phase_flash"
    / "classical_compositional_q2_eg_mms_3d.i"
)
TOLERANCE = 1.0e-10

ERROR_COLUMNS = (
    "ux_l2",
    "uy_l2",
    "uz_l2",
    "solid_reference_jacobian_l2",
    "oil_pressure_backbone_l2",
    "oil_pressure_reconstructed_l2",
    "oil_pressure_enrichment_l2",
    "gas_pressure_backbone_l2",
    "gas_pressure_reconstructed_l2",
    "gas_pressure_enrichment_l2",
    "oil_intrinsic_density_l2",
    "gas_intrinsic_density_l2",
    "component0_primary_l2",
    "component1_primary_l2",
    "component0_direct_storage_l2",
    "component1_direct_storage_l2",
    "component0_flash_storage_l2",
    "component1_flash_storage_l2",
    "flash_volume_constraint_l2",
    "flash_oil_composition_closure_l2",
    "flash_gas_composition_closure_l2",
    "flash_component0_overall_closure_l2",
    "flash_component1_overall_closure_l2",
    "flash_gas_pressure_equilibrium_l2",
    "flash_gas_component0_chemical_equilibrium_l2",
    "flash_gas_component1_chemical_equilibrium_l2",
    "oil_saturation_l2",
    "gas_saturation_l2",
    "oil_component0_composition_l2",
    "oil_component1_composition_l2",
    "gas_component0_composition_l2",
    "gas_component1_composition_l2",
    "oil_reference_relative_mass_flux_l2",
    "gas_reference_relative_mass_flux_l2",
    "oil_component0_reference_flux_l2",
    "oil_component1_reference_flux_l2",
    "gas_component0_reference_flux_l2",
    "gas_component1_reference_flux_l2",
    "component0_reference_flux_l2",
    "component1_reference_flux_l2",
    "component0_reference_source_l2",
    "component1_reference_source_l2",
    "direct_summed_eq32_component0_global_balance",
    "direct_summed_eq32_component1_global_balance",
)

# Analytic face and volume integrals for
# W_oil=W_gas=(-0.936,-0.7865,-0.67015384615384615385) and phase
# compositions varying along s=0.936*x+0.7865*y+0.67015384615384615385*z.
EXPECTED_INTEGRALS = {
    "oil_component0_left_reference_flux": -0.7233714,
    "oil_component0_right_reference_flux": -0.810981,
    "oil_component0_bottom_reference_flux": -0.613712,
    "oil_component0_top_reference_flux": -0.675570225,
    "oil_component0_back_reference_flux": -0.5268246923076922,
    "oil_component0_front_reference_flux": -0.5717353100591716,
    "oil_component1_left_reference_flux": -0.2126286,
    "oil_component1_right_reference_flux": -0.125019,
    "oil_component1_bottom_reference_flux": -0.172788,
    "oil_component1_top_reference_flux": -0.110929775,
    "oil_component1_back_reference_flux": -0.1433291538461538,
    "oil_component1_front_reference_flux": -0.09841853609467453,
    "gas_component0_left_reference_flux": -0.2212857,
    "gas_component0_right_reference_flux": -0.2650905,
    "gas_component0_bottom_reference_flux": -0.188881,
    "gas_component0_top_reference_flux": -0.2198101125,
    "gas_component0_back_reference_flux": -0.1628892692307692,
    "gas_component0_front_reference_flux": -0.1853445781065089,
    "gas_component1_left_reference_flux": -0.7147143,
    "gas_component1_right_reference_flux": -0.6709095,
    "gas_component1_bottom_reference_flux": -0.597619,
    "gas_component1_top_reference_flux": -0.5666898875,
    "gas_component1_back_reference_flux": -0.5072645769230769,
    "gas_component1_front_reference_flux": -0.4848092680473373,
    "component0_left_reference_flux": -0.9446571,
    "component0_right_reference_flux": -1.0760715,
    "component0_bottom_reference_flux": -0.802593,
    "component0_top_reference_flux": -0.8953803375,
    "component0_back_reference_flux": -0.6897139615384614,
    "component0_front_reference_flux": -0.7570798881656804,
    "component1_left_reference_flux": -0.9273429,
    "component1_right_reference_flux": -0.7959285,
    "component1_bottom_reference_flux": -0.770407,
    "component1_top_reference_flux": -0.6776196625,
    "component1_back_reference_flux": -0.6505937307692308,
    "component1_front_reference_flux": -0.5832278041420118,
    "component0_net_outward_reference_flux": -0.29156766412721896,
    "component1_net_outward_reference_flux": 0.29156766412721896,
    "component0_reference_storage_rate_integral": 0.0,
    "component1_reference_storage_rate_integral": 0.0,
    "component0_reference_source_integral": -0.29156766412721896,
    "component1_reference_source_integral": 0.29156766412721896,
}


def main() -> int:
    if not APP.exists():
        raise SystemExit(f"missing optimized executable: {APP}")

    with tempfile.TemporaryDirectory(prefix="classical_compositional_q2_eg_mms_3d_") as tmp:
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
        raise SystemExit("classical compositional MMS produced no CSV rows")
    final = {name: float(value) for name, value in rows[-1].items()}
    required = ERROR_COLUMNS + tuple(EXPECTED_INTEGRALS)
    missing = [name for name in required if name not in final]
    if missing:
        raise SystemExit("classical compositional MMS omitted: " + ", ".join(missing))

    failures = [
        f"{name}={abs(final[name]):.6e} > {TOLERANCE:.1e}"
        for name in ERROR_COLUMNS
        if abs(final[name]) > TOLERANCE
    ]
    for name, expected in EXPECTED_INTEGRALS.items():
        error = abs(final[name] - expected)
        if error > TOLERANCE:
            failures.append(f"{name}_error={error:.6e} > {TOLERANCE:.1e}")

    # Guard against a fluxless, one-dimensional, single-phase, or
    # one-component diagnostic being mislabeled as this 3D acceptance solve.
    phase_component_faces = tuple(
        f"{phase}_component{component}_{face}_reference_flux"
        for phase in ("oil", "gas")
        for component in (0, 1)
        for face in ("left", "right", "bottom", "top", "front", "back")
    )
    for name in phase_component_faces:
        if abs(final[name]) <= TOLERANCE:
            failures.append(f"{name} is not quantitatively nonzero")
    for component in ("component0", "component1"):
        if abs(final[f"{component}_reference_source_integral"]) <= TOLERANCE:
            failures.append(f"{component} source is not quantitatively nonzero")
        if abs(final[f"{component}_net_outward_reference_flux"]) <= TOLERANCE:
            failures.append(f"{component} net outward flux is not quantitatively nonzero")

    if failures:
        raise SystemExit("3D classical compositional Q2/EG MMS failed: " + "; ".join(failures))

    maximum_error = max(abs(final[name]) for name in ERROR_COLUMNS)
    maximum_integral_error = max(
        abs(final[name] - expected) for name, expected in EXPECTED_INTEGRALS.items()
    )
    print(
        "classical_compositional_q2_eg_mms_3d: "
        f"maximum_error={maximum_error:.6e}, "
        f"maximum_integral_error={maximum_integral_error:.6e}, "
        f"component0_balance={final['direct_summed_eq32_component0_global_balance']:.12e}, "
        f"component1_balance={final['direct_summed_eq32_component1_global_balance']:.12e}, "
        f"component0_net_flux={final['component0_net_outward_reference_flux']:.12e}, "
        f"component1_net_flux={final['component1_net_outward_reference_flux']:.12e}, "
        f"component0_x_face={final['component0_right_reference_flux']:.12e}, "
        f"component0_y_face={final['component0_top_reference_flux']:.12e}, "
        f"component0_z_face={final['component0_front_reference_flux']:.12e}, "
        f"tolerance={TOLERANCE:.1e}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
