#!/usr/bin/env python3
"""Quantitatively check the genuinely 2D black-oil Q2/EG spatial-flux MMS."""

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
    / "black_oil_pvt"
    / "black_oil_three_component_spatial_flux_balance_2d.i"
)

TOLERANCE = 1.0e-10
ERROR_COLUMNS = (
    "ux_l2",
    "uy_l2",
    "solid_reference_jacobian_l2",
    "pressure_l2",
    "pressure_enrichment_l2",
    "water_saturation_l2",
    "gas_saturation_l2",
    "water_pressure_closure_l2",
    "gas_pressure_closure_l2",
    "water_relative_permeability_l2",
    "oil_relative_permeability_l2",
    "gas_relative_permeability_l2",
    "water_reference_component_storage_l2",
    "oil_reference_component_storage_l2",
    "gas_reference_component_storage_l2",
    "water_reference_component_storage_rate_l2",
    "oil_reference_component_storage_rate_l2",
    "gas_reference_component_storage_rate_l2",
    "water_phase_flux_x_l2",
    "water_phase_flux_y_l2",
    "oil_phase_flux_x_l2",
    "oil_phase_flux_y_l2",
    "gas_phase_flux_x_l2",
    "gas_phase_flux_y_l2",
    "water_reference_component_flux_x_l2",
    "water_reference_component_flux_y_l2",
    "oil_reference_component_flux_x_l2",
    "oil_reference_component_flux_y_l2",
    "gas_reference_component_flux_x_l2",
    "gas_reference_component_flux_y_l2",
    "water_reference_component_source_l2",
    "oil_reference_component_source_l2",
    "gas_reference_component_source_l2",
    "direct_summed_eq32_water_component_global_balance",
    "direct_summed_eq32_oil_component_global_balance",
    "direct_summed_eq32_gas_component_global_balance",
)

water_x_factor = -2.0 * 0.1 * 0.9 * (1.2 / 1.1)
water_y_factor = -2.0 * 0.1 * 1.92 * (1.1 / 1.2)
gas_x_factor = -0.1 * 1.09 * (1.2 / 1.1)
gas_y_factor = -0.1 * 2.06 * (1.1 / 1.2)
water_divergence = water_x_factor * 0.02 + water_y_factor * 0.016
gas_divergence = gas_x_factor * 0.006 + gas_y_factor * 0.004

EXPECTED_INTEGRALS = {
    "water_left_reference_component_flux": water_x_factor * (0.28 + 0.016 * 0.5),
    "water_right_reference_component_flux": water_x_factor * (0.28 + 0.02 + 0.016 * 0.5),
    "water_bottom_reference_component_flux": water_y_factor * (0.28 + 0.02 * 0.5),
    "water_top_reference_component_flux": water_y_factor * (0.28 + 0.02 * 0.5 + 0.016),
    "water_net_outward_reference_component_flux": water_divergence,
    "water_reference_component_storage_rate_integral": 0.0,
    "water_reference_component_source_integral": water_divergence,
    "oil_left_reference_component_flux": -3.0 * 0.1 * (1.2 / 1.1) * 0.5,
    "oil_right_reference_component_flux": -3.0 * 0.1 * (1.2 / 1.1) * 0.5,
    "oil_bottom_reference_component_flux": -3.0 * 0.1 * 2.0 * (1.1 / 1.2) * 0.5,
    "oil_top_reference_component_flux": -3.0 * 0.1 * 2.0 * (1.1 / 1.2) * 0.5,
    "oil_net_outward_reference_component_flux": 0.0,
    "oil_reference_component_storage_rate_integral": 0.0,
    "oil_reference_component_source_integral": 0.0,
    "gas_left_reference_component_flux": gas_x_factor * (0.34 + 0.004 * 0.5),
    "gas_right_reference_component_flux": gas_x_factor * (0.34 + 0.006 + 0.004 * 0.5),
    "gas_bottom_reference_component_flux": gas_y_factor * (0.34 + 0.006 * 0.5),
    "gas_top_reference_component_flux": gas_y_factor * (0.34 + 0.006 * 0.5 + 0.004),
    "gas_net_outward_reference_component_flux": gas_divergence,
    "gas_reference_component_storage_rate_integral": 0.0,
    "gas_reference_component_source_integral": gas_divergence,
}


def main() -> int:
    if not APP.exists():
        raise SystemExit(f"missing optimized executable: {APP}")

    with tempfile.TemporaryDirectory(prefix="black_oil_spatial_flux_mms_2d_") as tmp:
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
        raise SystemExit("2D black-oil spatial-flux MMS produced no CSV rows")
    final = {name: float(value) for name, value in rows[-1].items()}
    required = ERROR_COLUMNS + tuple(EXPECTED_INTEGRALS)
    missing = [name for name in required if name not in final]
    if missing:
        raise SystemExit("2D black-oil spatial-flux MMS omitted: " + ", ".join(missing))

    failures = [
        f"{name}={abs(final[name]):.6e} > {TOLERANCE:.1e}"
        for name in ERROR_COLUMNS
        if abs(final[name]) > TOLERANCE
    ]
    for name, expected in EXPECTED_INTEGRALS.items():
        error = abs(final[name] - expected)
        if error > TOLERANCE:
            failures.append(f"{name}_error={error:.6e} > {TOLERANCE:.1e}")
    for component in ("water", "oil", "gas"):
        for side in ("left", "right", "bottom", "top"):
            name = f"{component}_{side}_reference_component_flux"
            if abs(final[name]) <= TOLERANCE:
                failures.append(f"{name} is not quantitatively nonzero")
        for direction in ("x", "y"):
            for path in ("phase_flux", "reference_component_flux"):
                name = f"{component}_{path}_{direction}_l2"
                if name not in final:
                    failures.append(f"missing {name}")
    if failures:
        raise SystemExit("2D black-oil Q2/EG spatial-flux MMS failed: " + "; ".join(failures))

    maximum_error = max(abs(final[name]) for name in ERROR_COLUMNS)
    maximum_integral_error = max(
        abs(final[name] - expected) for name, expected in EXPECTED_INTEGRALS.items()
    )
    balances = ", ".join(
        f"{component}_balance={final[f'direct_summed_eq32_{component}_component_global_balance']:.12e}"
        for component in ("water", "oil", "gas")
    )
    print(
        "black_oil_three_component_spatial_flux_balance_2d: "
        f"maximum_error={maximum_error:.6e}, "
        f"maximum_integral_error={maximum_integral_error:.6e}, "
        f"water_net_outward_flux={final['water_net_outward_reference_component_flux']:.12e}, "
        f"gas_net_outward_flux={final['gas_net_outward_reference_component_flux']:.12e}, "
        f"{balances}, tolerance={TOLERANCE:.1e}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
