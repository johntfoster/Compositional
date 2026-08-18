#!/usr/bin/env python3
"""Quantitatively check the coupled 1D ideal-mixture Q2/EG acceptance leaf."""

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
    / "ideal_mixture_eos"
    / "ideal_mixture_q2_eg_balance_1d.i"
)

TOLERANCE = 1.0e-10
ERROR_COLUMNS = (
    "ux_l2",
    "pressure_total_l2",
    "pressure_gradient_l2",
    "pressure_enrichment_l2",
    "intrinsic_density_l2",
    "current_phase_mass_density_l2",
    "component_partial_density_0_l2",
    "component_partial_density_1_l2",
    "specific_helmholtz_l2",
    "mass_fraction_sum_l2",
    "pressure_identity_l2",
    "pressure_identity_residual_l2",
    "fluid_legendre_relation_l2",
    "neutral_component_euler_l2",
    "eos_neutral_potential_0_l2",
    "eos_neutral_potential_1_l2",
    "neutral_potential_0_total_l2",
    "neutral_potential_1_total_l2",
    "neutral_potential_0_gradient_l2",
    "neutral_potential_1_gradient_l2",
    "neutral_potential_0_enrichment_l2",
    "neutral_potential_1_enrichment_l2",
    "eos_sum_component_0_l2",
    "eos_sum_component_1_l2",
    "solved_sum_component_0_l2",
    "solved_sum_component_1_l2",
    "reference_relative_mass_flux_l2",
    "reference_component_0_flux_l2",
    "reference_component_1_flux_l2",
    "reference_component_0_source_l2",
    "reference_component_1_source_l2",
    "direct_summed_eq32_component_0_global_balance",
    "direct_summed_eq32_component_1_global_balance",
)
EXPECTED_INTEGRALS = {
    "sum_component_0_rate_integral": 0.005163536472025944,
    "sum_component_1_rate_integral": 0.015490609416077834,
    "left_reference_component_0_flux": -1.3469373309949e-06,
    "right_reference_component_0_flux": -1.3469386775740e-06,
    "left_reference_component_1_flux": -4.0408119929846e-06,
    "right_reference_component_1_flux": -4.0408160327220e-06,
    "net_outward_reference_component_0_flux": -1.3469380045147596e-12,
    "net_outward_reference_component_1_flux": -4.040814013544279e-12,
    "reference_component_0_source_integral": 0.005163536470679006,
    "reference_component_1_source_integral": 0.01549060941203702,
}


def main() -> int:
    if not APP.exists():
        raise SystemExit(f"missing optimized executable: {APP}")

    with tempfile.TemporaryDirectory(prefix="ideal_mixture_q2_eg_1d_") as tmp:
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
        raise SystemExit("ideal-mixture Q2/EG acceptance leaf produced no CSV rows")
    final = {name: float(value) for name, value in rows[-1].items()}
    required = ERROR_COLUMNS + tuple(EXPECTED_INTEGRALS)
    missing = [name for name in required if name not in final]
    if missing:
        raise SystemExit("ideal-mixture Q2/EG acceptance leaf omitted: " + ", ".join(missing))

    failures = [
        f"{name}={abs(final[name]):.6e} > {TOLERANCE:.1e}"
        for name in ERROR_COLUMNS
        if abs(final[name]) > TOLERANCE
    ]
    for name, expected in EXPECTED_INTEGRALS.items():
        error = abs(final[name] - expected)
        if error > TOLERANCE:
            failures.append(f"{name}_error={error:.6e} > {TOLERANCE:.1e}")

    # Reject a vacuous balance: both components must carry nonzero storage
    # rate, source, and left/right reference flux at the accepted state.
    for component in ("0", "1"):
        evidence = (
            f"sum_component_{component}_rate_integral",
            f"reference_component_{component}_source_integral",
            f"left_reference_component_{component}_flux",
            f"right_reference_component_{component}_flux",
        )
        for name in evidence:
            if abs(final[name]) <= TOLERANCE:
                failures.append(f"{name} is not quantitatively nonzero")

    if failures:
        raise SystemExit("1D ideal-mixture Q2/EG acceptance failed: " + "; ".join(failures))

    maximum_error = max(abs(final[name]) for name in ERROR_COLUMNS)
    maximum_integral_error = max(
        abs(final[name] - expected) for name, expected in EXPECTED_INTEGRALS.items()
    )
    print(
        "ideal_mixture_q2_eg_balance_1d: "
        f"maximum_error={maximum_error:.6e}, "
        f"maximum_integral_error={maximum_integral_error:.6e}, "
        f"component_0_global_balance={final['direct_summed_eq32_component_0_global_balance']:.12e}, "
        f"component_1_global_balance={final['direct_summed_eq32_component_1_global_balance']:.12e}, "
        f"tolerance={TOLERANCE:.1e}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
