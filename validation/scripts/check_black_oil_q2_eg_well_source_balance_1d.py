#!/usr/bin/env python3
"""Check the 1D Q2/EG black-oil well/source summed Eq. (32) MMS."""

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
    / "black_oil_well"
    / "q2_eg_three_component_well_source_balance_1d.i"
)

TOLERANCE = 1.0e-10
ERROR_COLUMNS = (
    "ux_l2",
    "solid_reference_jacobian_l2",
    "reconstructed_p1_plus_p0_eg_pressure_l2",
    "pressure_enrichment_l2",
    "water_saturation_l2",
    "gas_saturation_l2",
    "sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_water_component_l2",
    "sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_oil_component_l2",
    "sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_gas_component_l2",
    "sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_water_component_rate_l2",
    "sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_oil_component_rate_l2",
    "sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_gas_component_rate_l2",
    "summed_eq32_water_component_well_source_l2",
    "summed_eq32_stock_tank_oil_component_well_source_l2",
    "summed_eq32_stock_tank_gas_component_well_source_l2",
    "water_reservoir_rate_l2",
    "oil_reservoir_rate_l2",
    "gas_reservoir_rate_l2",
    "water_surface_rate_l2",
    "oil_surface_rate_l2",
    "gas_surface_rate_l2",
    "effective_bottom_hole_pressure_l2",
    "direct_summed_eq32_water_component_global_balance",
    "direct_summed_eq32_stock_tank_oil_component_global_balance",
    "direct_summed_eq32_stock_tank_gas_component_global_balance",
)
EXPECTED_INTEGRALS = {
    "sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_water_component_rate_integral":
        -2.0 * (0.01 * 0.2 / 1.2),
    "sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_oil_component_rate_integral":
        -3.0 * (0.01 * 0.3 / 1.4),
    "sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_gas_component_rate_integral":
        -(0.01 * 0.4 / 0.6 + 1.4 * 0.01 * 0.3 / 1.4),
    "summed_eq32_water_component_well_source_integral":
        -2.0 * (0.01 * 0.2 / 1.2),
    "summed_eq32_stock_tank_oil_component_well_source_integral":
        -3.0 * (0.01 * 0.3 / 1.4),
    "summed_eq32_stock_tank_gas_component_well_source_integral":
        -(0.01 * 0.4 / 0.6 + 1.4 * 0.01 * 0.3 / 1.4),
}


def main() -> int:
    if not APP.exists():
        raise SystemExit(f"missing optimized executable: {APP}")

    with tempfile.TemporaryDirectory(prefix="black_oil_q2_eg_well_source_mms_1d_") as tmp:
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
        raise SystemExit("black-oil Q2/EG well/source MMS produced no CSV rows")
    final = {name: float(value) for name, value in rows[-1].items()}
    required = ERROR_COLUMNS + tuple(EXPECTED_INTEGRALS)
    missing = [name for name in required if name not in final]
    if missing:
        raise SystemExit("black-oil Q2/EG well/source MMS omitted: " + ", ".join(missing))

    failures = [
        f"{name}={abs(final[name]):.6e} > {TOLERANCE:.1e}"
        for name in ERROR_COLUMNS
        if abs(final[name]) > TOLERANCE
    ]
    for name, expected in EXPECTED_INTEGRALS.items():
        error = abs(final[name] - expected)
        if error > TOLERANCE:
            failures.append(f"{name}_error={error:.6e} > {TOLERANCE:.1e}")
        if abs(final[name]) <= TOLERANCE:
            failures.append(f"{name} is not quantitatively nonzero")
    if failures:
        raise SystemExit("1D black-oil Q2/EG well/source MMS failed: " + "; ".join(failures))

    maximum_error = max(abs(final[name]) for name in ERROR_COLUMNS)
    maximum_integral_error = max(
        abs(final[name] - expected) for name, expected in EXPECTED_INTEGRALS.items()
    )
    print(
        "black_oil_q2_eg_well_source_balance_1d: "
        f"maximum_error={maximum_error:.6e}, "
        f"maximum_integral_error={maximum_integral_error:.6e}, "
        "water_oil_gas_source_integrals="
        f"{final['summed_eq32_water_component_well_source_integral']:.12e}/"
        f"{final['summed_eq32_stock_tank_oil_component_well_source_integral']:.12e}/"
        f"{final['summed_eq32_stock_tank_gas_component_well_source_integral']:.12e}, "
        f"tolerance={TOLERANCE:.1e}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
