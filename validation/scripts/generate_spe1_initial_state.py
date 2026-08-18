#!/usr/bin/env python3
"""Generate the pinned SPE1 Case 1 hydrostatic black-oil initial state in SI units."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from extract_eclipse_black_oil import extract


GRAVITY = 9.80665


def linear_interpolate(x: float, coordinates: list[float], values: list[float]) -> float:
    if x <= coordinates[0]:
        lower = 0
    elif x >= coordinates[-1]:
        lower = len(coordinates) - 2
    else:
        lower = next(i for i in range(len(coordinates) - 1) if coordinates[i + 1] >= x)
    weight = (x - coordinates[lower]) / (coordinates[lower + 1] - coordinates[lower])
    return values[lower] + weight * (values[lower + 1] - values[lower])


def oil_fvf(pressure_pa: float, rs: float, pvto: list[dict[str, object]]) -> float:
    branch = min(pvto, key=lambda item: abs(item["solution_gas_oil_ratio"] - rs))
    if abs(branch["solution_gas_oil_ratio"] - rs) > 1e-10:
        raise ValueError("SPE1 initialization R_s must coincide with a PVTO branch")
    pressure = [row[0] for row in branch["rows"]]
    fvf = [row[1] for row in branch["rows"]]
    if len(pressure) == 1:
        return fvf[0]
    return linear_interpolate(pressure_pa, pressure, fvf)


def hydrostatic_pressure(
    target_depth_m: float,
    datum_depth_m: float,
    datum_pressure_pa: float,
    rs: float,
    oil_surface_density: float,
    gas_surface_density: float,
    pvto: list[dict[str, object]],
) -> float:
    distance = target_depth_m - datum_depth_m
    steps = max(1, int(abs(distance) / 0.05) + 1)
    step = distance / steps

    def derivative(pressure: float) -> float:
        density = (oil_surface_density + gas_surface_density * rs) / oil_fvf(
            pressure, rs, pvto
        )
        return density * GRAVITY

    pressure = datum_pressure_pa
    for _ in range(steps):
        k1 = derivative(pressure)
        k2 = derivative(pressure + 0.5 * step * k1)
        k3 = derivative(pressure + 0.5 * step * k2)
        k4 = derivative(pressure + step * k3)
        pressure += step * (k1 + 2.0 * k2 + 2.0 * k3 + k4) / 6.0
    return pressure


def generate(deck: Path) -> dict[str, object]:
    data = extract(deck)
    si = data["si"]
    equil = si["initialization"]["equil"]
    datum_depth_m, datum_pressure_pa = equil[0], equil[1]
    rs = si["initialization"]["rsvd"][0][1]
    oil_surface_density, _, gas_surface_density = si["density"]
    top_depth_m = si["grid"]["properties"]["tops"][0]
    layer_thicknesses_m = [
        si["grid"]["properties"]["dz"][0],
        si["grid"]["properties"]["dz"][100],
        si["grid"]["properties"]["dz"][200],
    ]

    layer_states: list[dict[str, float | int]] = []
    depth = top_depth_m
    for layer, thickness in enumerate(layer_thicknesses_m, start=1):
        center_depth = depth + 0.5 * thickness
        pressure = hydrostatic_pressure(
            center_depth,
            datum_depth_m,
            datum_pressure_pa,
            rs,
            oil_surface_density,
            gas_surface_density,
            si["pvto"],
        )
        layer_states.append(
            {
                "layer": layer,
                "center_depth_m": center_depth,
                "oil_pressure_pa": pressure,
                "water_saturation": si["swof"][0][0],
                "gas_saturation": 0.0,
                "solution_gas_oil_ratio_standard_m3_per_stock_tank_m3": rs,
            }
        )
        depth += thickness

    return {
        "source": data["source"],
        "gravity_m_s2": GRAVITY,
        "datum_depth_m": datum_depth_m,
        "datum_pressure_pa": datum_pressure_pa,
        "water_oil_contact_m": equil[2],
        "gas_oil_contact_m": equil[4],
        "layer_states": layer_states,
        "cell_order": "ECLIPSE layer-major order with 100 cells per layer",
        "oil_pressure_pa": [state["oil_pressure_pa"] for state in layer_states for _ in range(100)],
        "water_saturation": [state["water_saturation"] for state in layer_states for _ in range(100)],
        "gas_saturation": [state["gas_saturation"] for state in layer_states for _ in range(100)],
        "solution_gas_oil_ratio_standard_m3_per_stock_tank_m3": [
            state["solution_gas_oil_ratio_standard_m3_per_stock_tank_m3"]
            for state in layer_states
            for _ in range(100)
        ],
    }


def validate(state: dict[str, object]) -> None:
    if len(state["oil_pressure_pa"]) != 300:
        raise ValueError("SPE1 initial pressure must contain 300 cell values")
    layers = state["layer_states"]
    if abs(layers[2]["center_depth_m"] - state["datum_depth_m"]) > 1e-12:
        raise ValueError("SPE1 layer 3 center must coincide with the EQUIL datum depth")
    if abs(layers[2]["oil_pressure_pa"] - state["datum_pressure_pa"]) > 1e-8:
        raise ValueError("SPE1 datum pressure was not preserved")
    if not layers[0]["oil_pressure_pa"] < layers[1]["oil_pressure_pa"] < layers[2]["oil_pressure_pa"]:
        raise ValueError("SPE1 hydrostatic pressure must increase with depth")
    if set(state["water_saturation"]) != {0.12} or set(state["gas_saturation"]) != {0.0}:
        raise ValueError("SPE1 initial saturations differ from connate-water, no-free-gas state")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("deck", type=Path)
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    state = generate(args.deck)
    if args.validate:
        validate(state)
    print(json.dumps(state, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
