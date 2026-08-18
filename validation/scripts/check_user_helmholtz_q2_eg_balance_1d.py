#!/usr/bin/env python3
"""Quantitatively check the coupled 1D user-Helmholtz Q2/EG acceptance leaf."""

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
    / "user_helmholtz_eos"
    / "user_helmholtz_q2_eg_balance_1d.i"
)

TOLERANCE = 1.0e-10
ERROR_COLUMNS = (
    "ux_l2",
    "rho0_l2",
    "rho1_l2",
    "temperature_total_l2",
    "pressure_total_l2",
    "pressure_gradient_l2",
    "pressure_enrichment_l2",
    "neutral_potential_0_total_l2",
    "neutral_potential_0_gradient_l2",
    "neutral_potential_0_enrichment_l2",
    "neutral_potential_1_total_l2",
    "neutral_potential_1_gradient_l2",
    "neutral_potential_1_enrichment_l2",
    "helmholtz_density_l2",
    "eos_pressure_l2",
    "eos_neutral_potential_0_l2",
    "eos_neutral_potential_1_l2",
    "intrinsic_density_l2",
    "bulk_phase_density_l2",
    "specific_helmholtz_l2",
    "entropy_density_l2",
    "legendre_relation_l2",
    "direct_summed_reference_component_0_l2",
    "direct_summed_reference_component_1_l2",
    "summed_reference_component_0_balance_l2",
    "summed_reference_component_1_balance_l2",
    "oil_reference_relative_mass_flux_l2",
    "current_component_0_extra_flux_l2",
    "current_component_1_extra_flux_l2",
    "reference_component_0_flux_l2",
    "reference_component_1_flux_l2",
    "reference_component_0_source_l2",
    "reference_component_1_source_l2",
    "direct_summed_eq32_component_0_global_balance",
    "direct_summed_eq32_component_1_global_balance",
)
EXPECTED_INTEGRALS = {
    "summed_reference_component_0_rate_integral": 0.01375,
    "summed_reference_component_1_rate_integral": 0.0275,
    "left_reference_component_0_flux": -0.72,
    "right_reference_component_0_flux": -0.76,
    "left_reference_component_1_flux": -1.24,
    "right_reference_component_1_flux": -1.32,
    "net_outward_reference_component_0_flux": -0.04,
    "net_outward_reference_component_1_flux": -0.08,
    "reference_component_0_source_integral": -0.02625,
    "reference_component_1_source_integral": -0.0525,
}


def main() -> int:
    if not APP.exists():
        raise SystemExit(f"missing optimized executable: {APP}")

    with tempfile.TemporaryDirectory(prefix="user_helmholtz_q2_eg_1d_") as tmp:
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
        raise SystemExit("user-Helmholtz Q2/EG acceptance leaf produced no CSV rows")
    final = {name: float(value) for name, value in rows[-1].items()}
    required = ERROR_COLUMNS + tuple(EXPECTED_INTEGRALS)
    missing = [name for name in required if name not in final]
    if missing:
        raise SystemExit("user-Helmholtz Q2/EG acceptance leaf omitted: " + ", ".join(missing))

    failures = [
        f"{name}={abs(final[name]):.6e} > {TOLERANCE:.1e}"
        for name in ERROR_COLUMNS
        if abs(final[name]) > TOLERANCE
    ]
    for name, expected in EXPECTED_INTEGRALS.items():
        error = abs(final[name] - expected)
        if error > TOLERANCE:
            failures.append(f"{name}_error={error:.6e} > {TOLERANCE:.1e}")
    for component in ("0", "1"):
        for side in ("left", "right"):
            name = f"{side}_reference_component_{component}_flux"
            if abs(final[name]) <= TOLERANCE:
                failures.append(f"{name} is not quantitatively nonzero")
    if failures:
        raise SystemExit("1D user-Helmholtz Q2/EG acceptance failed: " + "; ".join(failures))

    maximum_error = max(abs(final[name]) for name in ERROR_COLUMNS)
    maximum_integral_error = max(
        abs(final[name] - expected) for name, expected in EXPECTED_INTEGRALS.items()
    )
    print(
        "user_helmholtz_q2_eg_balance_1d: "
        f"maximum_error={maximum_error:.6e}, "
        f"maximum_integral_error={maximum_integral_error:.6e}, "
        f"component_0_global_balance={final['direct_summed_eq32_component_0_global_balance']:.12e}, "
        f"component_1_global_balance={final['direct_summed_eq32_component_1_global_balance']:.12e}, "
        f"tolerance={TOLERANCE:.1e}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
