#!/usr/bin/env python3
"""Audit the SPE2 transcription, units, density identities, and SI geometry."""

from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "validation/reference_data/spe2_primary_tables.yml"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def main() -> None:
    raw = SOURCE.read_bytes()
    data = yaml.safe_load(raw)
    require(data["benchmark"] == "SPE2 three-phase coning study", "wrong benchmark")

    geometry = data["geometry_field_units"]
    layers = data["layer_table_field_units"]["rows"]
    pvt = data["pvt_table_field_units"]
    require(len(layers) == 15, "SPE2 must contain 15 vertical layers")
    require(len(geometry["radial_block_boundaries_ft"]) == 11,
            "SPE2 must contain 10 radial cells")
    require(len(pvt["rows"]) == 14, "SPE2 must contain 14 PVT rows")
    require(pvt["columns"][8] == "gas_fvf_rb_per_mscf",
            "the primary gas FVF is RB/Mscf")
    require(len(data["water_oil_saturation_functions_field_units"]["rows"]) == 8,
            "SPE2 must contain 8 water-oil saturation rows")
    require(len(data["gas_oil_saturation_functions_field_units"]["rows"]) == 10,
            "SPE2 must contain 10 gas-oil saturation rows")

    constants = data["rock_and_fluid_constants_field_units"]
    oil_surface_density = constants["stock_tank_oil_density_lbm_per_ft3"]
    water_surface_density = constants["stock_tank_water_density_lbm_per_ft3"]
    gas_surface_density = constants["standard_gas_density_lbm_per_ft3"]
    scf_per_stb_to_ratio = 1.0 / 5.614583333333333
    rb_per_mscf_to_ratio = 5.614583333333333 / 1000.0

    regular_oil_density_errors = []
    regular_gas_density_errors = []
    maximum_water_density_error = 0.0
    published_oil_density_outlier = None
    published_gas_density_outlier = None
    for row in pvt["rows"]:
        (pressure, bo, oil_density, _, rs_scf_stb, bw, water_density, _, bg_rb_mscf,
         gas_density, _) = row
        computed_oil_density = (
            oil_surface_density + gas_surface_density * rs_scf_stb * scf_per_stb_to_ratio
        ) / bo
        computed_water_density = water_surface_density / bw
        computed_gas_density = gas_surface_density / (bg_rb_mscf * rb_per_mscf_to_ratio)
        oil_error = abs(computed_oil_density - oil_density)
        gas_error = abs(computed_gas_density - gas_density)
        if pressure == 800:
            published_oil_density_outlier = oil_error
        else:
            regular_oil_density_errors.append(oil_error)
        if pressure == 1200:
            published_gas_density_outlier = gas_error
        else:
            regular_gas_density_errors.append(gas_error)
        maximum_water_density_error = max(
            maximum_water_density_error, abs(computed_water_density - water_density)
        )

    # Two printed density entries are inconsistent with the other columns. Preserve and expose
    # those source values; all remaining rows must satisfy the identities to table precision.
    require(max(regular_oil_density_errors) < 0.011,
            "oil density identity exceeds table rounding outside the published 800-psia outlier")
    require(maximum_water_density_error < 0.006,
            "water density identity exceeds table rounding")
    require(max(regular_gas_density_errors) < 0.002,
            "gas density identity exceeds table rounding outside the published 1200-psia outlier")
    require(published_oil_density_outlier is not None and
            0.13 < published_oil_density_outlier < 0.14,
            "the preserved 800-psia oil-density outlier changed")
    require(published_gas_density_outlier is not None and
            0.017 < published_gas_density_outlier < 0.019,
            "the preserved 1200-psia gas-density outlier changed")

    require(abs(sum(row[1] for row in layers) - 359.0) < 1.0e-12,
            "layer thicknesses must sum to 359 ft")
    ft_to_m = 0.3048
    radii = [value * ft_to_m for value in geometry["radial_block_boundaries_ft"]]
    total_height = sum(row[1] for row in layers) * ft_to_m
    physical_volume = math.pi * (radii[-1] ** 2 - radii[0] ** 2) * total_height
    completion_height = 8.0 * ft_to_m
    completion_volume = math.pi * (radii[1] ** 2 - radii[0] ** 2) * completion_height
    require(abs(physical_volume - 134213723.41921999) / physical_volume < 1.0e-14,
            "converted annular volume mismatch")
    require(abs(completion_volume - 2.8022399126270758) / completion_volume < 1.0e-14,
            "converted completion volume mismatch")

    result = {
        "status": "pass",
        "source_sha256": hashlib.sha256(raw).hexdigest(),
        "layer_count": len(layers),
        "radial_cell_count": len(radii) - 1,
        "pvt_row_count": len(pvt["rows"]),
        "maximum_regular_oil_density_error_lbm_per_ft3": max(regular_oil_density_errors),
        "maximum_water_density_error_lbm_per_ft3": maximum_water_density_error,
        "maximum_regular_gas_density_error_lbm_per_ft3": max(regular_gas_density_errors),
        "published_800_psia_oil_density_outlier_lbm_per_ft3": published_oil_density_outlier,
        "published_1200_psia_gas_density_outlier_lbm_per_ft3": published_gas_density_outlier,
        "physical_volume_m3": physical_volume,
        "completion_volume_m3": completion_volume,
    }
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
