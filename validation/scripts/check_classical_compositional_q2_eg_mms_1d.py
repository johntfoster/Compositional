#!/usr/bin/env python3
"""Check the two-phase/two-component 1D classical compositional MMS."""

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
    / "classical_compositional_q2_eg_mms_1d.i"
)
TOLERANCE = 1.0e-10

ERROR_COLUMNS = (
    "ux_l2",
    "solid_reference_jacobian_l2",
    "oil_pressure_backbone_l2",
    "oil_pressure_reconstructed_l2",
    "oil_pressure_enrichment_l2",
    "gas_pressure_reconstructed_l2",
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

# These are the analytic values for W_oil = W_gas = -0.6 and
# eta_oil=(0.7+0.1x,0.3-0.1x), eta_gas=(0.2+0.05x,0.8-0.05x).
EXPECTED_INTEGRALS = {
    "oil_component0_left_reference_flux": -0.42,
    "oil_component0_right_reference_flux": -0.48,
    "oil_component1_left_reference_flux": -0.18,
    "oil_component1_right_reference_flux": -0.12,
    "gas_component0_left_reference_flux": -0.12,
    "gas_component0_right_reference_flux": -0.15,
    "gas_component1_left_reference_flux": -0.48,
    "gas_component1_right_reference_flux": -0.45,
    "component0_left_reference_flux": -0.54,
    "component0_right_reference_flux": -0.63,
    "component1_left_reference_flux": -0.66,
    "component1_right_reference_flux": -0.57,
    "component0_net_outward_reference_flux": -0.09,
    "component1_net_outward_reference_flux": 0.09,
    "component0_reference_storage_rate_integral": 0.0,
    "component1_reference_storage_rate_integral": 0.0,
    "component0_reference_source_integral": -0.09,
    "component1_reference_source_integral": 0.09,
}


def main() -> int:
    if not APP.exists():
        raise SystemExit(f"missing optimized executable: {APP}")

    with tempfile.TemporaryDirectory(prefix="classical_compositional_q2_eg_mms_1d_") as tmp:
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

    # Guard against a fluxless, single-phase, or one-component diagnostic being
    # mislabeled as this classical compositional-flow acceptance solve.
    phase_component_faces = (
        "oil_component0_left_reference_flux",
        "oil_component1_left_reference_flux",
        "gas_component0_left_reference_flux",
        "gas_component1_left_reference_flux",
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
        raise SystemExit("1D classical compositional Q2/EG MMS failed: " + "; ".join(failures))

    maximum_error = max(abs(final[name]) for name in ERROR_COLUMNS)
    maximum_integral_error = max(
        abs(final[name] - expected) for name, expected in EXPECTED_INTEGRALS.items()
    )
    print(
        "classical_compositional_q2_eg_mms_1d: "
        f"maximum_error={maximum_error:.6e}, "
        f"maximum_integral_error={maximum_integral_error:.6e}, "
        f"component0_balance={final['direct_summed_eq32_component0_global_balance']:.12e}, "
        f"component1_balance={final['direct_summed_eq32_component1_global_balance']:.12e}, "
        f"component0_net_flux={final['component0_net_outward_reference_flux']:.12e}, "
        f"component1_net_flux={final['component1_net_outward_reference_flux']:.12e}, "
        f"tolerance={TOLERANCE:.1e}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
