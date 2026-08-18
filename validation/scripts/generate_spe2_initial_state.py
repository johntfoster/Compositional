#!/usr/bin/env python3
"""Generate and audit the SPE2 hydrostatic/capillary initial state.

Depth is positive downward. Oil pressure is anchored at the gas-oil contact;
water and gas pressures are integrated from their contacts. Capillary pressure
is then inverted through the official SWOF and SGOF tables. Fluid-in-place
volumes use the same surface-density/FVF identities as the MOOSE benchmark PVT
material rather than the two inconsistent printed density cells.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
from pathlib import Path
from typing import Callable

import yaml


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "validation/reference_data/spe2_primary_tables.yml"
FT3_PER_RB = 5.614583333333333
FT3_TO_M3 = 0.028316846592


def linear(x: float, xs: list[float], ys: list[float]) -> float:
    if x <= xs[0]:
        return ys[0]
    if x >= xs[-1]:
        return ys[-1]
    upper = next(i for i, value in enumerate(xs) if value >= x)
    lower = upper - 1
    weight = (x - xs[lower]) / (xs[upper] - xs[lower])
    return ys[lower] + weight * (ys[upper] - ys[lower])


def invert_monotone(y: float, xs: list[float], ys: list[float]) -> float:
    increasing = ys[-1] > ys[0]
    if increasing:
        if y <= ys[0]:
            return xs[0]
        if y >= ys[-1]:
            return xs[-1]
        upper = next(i for i, value in enumerate(ys) if value >= y)
    else:
        if y >= ys[0]:
            return xs[0]
        if y <= ys[-1]:
            return xs[-1]
        upper = next(i for i, value in enumerate(ys) if value <= y)
    lower = upper - 1
    weight = (y - ys[lower]) / (ys[upper] - ys[lower])
    return xs[lower] + weight * (xs[upper] - xs[lower])


def integrate_pressure(
    pressure_psi: float,
    start_depth_ft: float,
    target_depth_ft: float,
    density_lbm_ft3: Callable[[float], float],
    maximum_step_ft: float = 0.1,
) -> float:
    count = max(1, math.ceil(abs(target_depth_ft - start_depth_ft) / maximum_step_ft))
    step = (target_depth_ft - start_depth_ft) / count
    pressure = pressure_psi
    for _ in range(count):
        def gradient(value: float) -> float:
            return density_lbm_ft3(value) / 144.0

        k1 = gradient(pressure)
        k2 = gradient(pressure + 0.5 * step * k1)
        k3 = gradient(pressure + 0.5 * step * k2)
        k4 = gradient(pressure + step * k3)
        pressure += step * (k1 + 2 * k2 + 2 * k3 + k4) / 6.0
    return pressure


class SPE2State:
    def __init__(self, source: dict) -> None:
        geometry = source["geometry_field_units"]
        constants = source["rock_and_fluid_constants_field_units"]
        pvt_rows = source["pvt_table_field_units"]["rows"]
        self.goc = float(geometry["gas_oil_contact_depth_ft"])
        self.woc = float(geometry["water_oil_contact_depth_ft"])
        self.contact_pressure = float(geometry["oil_pressure_at_gas_oil_contact_psia"])
        self.pressure_points = [float(row[0]) for row in pvt_rows]
        self.bo_sat = [float(row[1]) for row in pvt_rows]
        self.rs_sat = [float(row[4]) for row in pvt_rows]
        self.bg = [float(row[8]) for row in pvt_rows]
        self.oil_surface_density = float(constants["stock_tank_oil_density_lbm_per_ft3"])
        self.water_surface_density = float(constants["stock_tank_water_density_lbm_per_ft3"])
        self.gas_surface_density = float(constants["standard_gas_density_lbm_per_ft3"])
        self.water_base_pressure = float(constants["water_base_pressure_psia"])
        self.water_base_fvf = float(constants["water_fvf_at_base_pressure_rb_per_stb"])
        self.water_compressibility = float(constants["water_compressibility_per_psi"])
        self.oil_compressibility = float(constants["undersaturated_oil_compressibility_per_psi"])
        self.rs_contact = linear(self.contact_pressure, self.pressure_points, self.rs_sat)
        self.bo_contact = linear(self.contact_pressure, self.pressure_points, self.bo_sat)
        swof = source["water_oil_saturation_functions_field_units"]["rows"]
        sgof = source["gas_oil_saturation_functions_field_units"]["rows"]
        self.sw_points = [float(row[0]) for row in swof]
        self.pcow_points = [float(row[3]) for row in swof]
        self.sg_points = [float(row[0]) for row in sgof]
        self.pcgo_points = [float(row[3]) for row in sgof]
        self.oil_pressure_at_woc = self.oil_pressure(self.woc)

    def saturated_rs(self, pressure: float) -> float:
        return linear(pressure, self.pressure_points, self.rs_sat)

    def saturated_bo(self, pressure: float) -> float:
        return linear(pressure, self.pressure_points, self.bo_sat)

    def water_fvf(self, pressure: float) -> float:
        return self.water_base_fvf * math.exp(
            -self.water_compressibility * (pressure - self.water_base_pressure)
        )

    def oil_fvf(self, pressure: float, depth: float) -> float:
        if depth < self.goc:
            return self.saturated_bo(pressure)
        return self.bo_contact * math.exp(
            -self.oil_compressibility * (pressure - self.contact_pressure)
        )

    def solution_gas_ratio(self, pressure: float, depth: float) -> float:
        return self.saturated_rs(pressure) if depth < self.goc else self.rs_contact

    def oil_density(self, pressure: float, depth: float) -> float:
        rs = self.solution_gas_ratio(pressure, depth)
        # The oil datum is lbm/stock-tank ft3, whereas R_s is scf/STB.
        # Convert the stock-tank oil contribution to lbm/STB before combining
        # it with the dissolved-gas mass, then divide by reservoir ft3/STB.
        mass_per_stb = self.oil_surface_density * FT3_PER_RB + self.gas_surface_density * rs
        reservoir_ft3_per_stb = self.oil_fvf(pressure, depth) * FT3_PER_RB
        return mass_per_stb / reservoir_ft3_per_stb

    def gas_density(self, pressure: float) -> float:
        bg = linear(pressure, self.pressure_points, self.bg)
        return self.gas_surface_density * 1000.0 / (bg * FT3_PER_RB)

    def water_density(self, pressure: float) -> float:
        return self.water_surface_density / self.water_fvf(pressure)

    def oil_pressure(self, depth: float) -> float:
        region_depth = min(depth, self.goc)
        pressure = integrate_pressure(
            self.contact_pressure,
            self.goc,
            region_depth,
            lambda value: self.oil_density(value, region_depth),
        )
        if depth > self.goc:
            pressure = integrate_pressure(
                self.contact_pressure,
                self.goc,
                depth,
                lambda value: self.oil_density(value, depth),
            )
        return pressure

    def state(self, depth: float) -> dict[str, float]:
        po = self.oil_pressure(depth)
        pg = po
        if depth < self.goc:
            pg = integrate_pressure(
                self.contact_pressure, self.goc, depth, self.gas_density
            )
        pw = po
        if depth < self.woc:
            pw = integrate_pressure(
                self.oil_pressure_at_woc, self.woc, depth, self.water_density
            )
        pcgo = max(pg - po, 0.0)
        pcow = max(po - pw, 0.0)
        sg = invert_monotone(pcgo, self.sg_points, self.pcgo_points) if depth < self.goc else 0.0
        sw = invert_monotone(pcow, self.sw_points, self.pcow_points) if depth < self.woc else 1.0
        so = max(0.0, 1.0 - sw - sg)
        return {
            "depth_ft": depth,
            "oil_pressure_psia": po,
            "water_pressure_psia": pw,
            "gas_pressure_psia": pg,
            "water_saturation": sw,
            "oil_saturation": so,
            "gas_saturation": sg,
            "solution_gas_ratio_scf_stb": self.solution_gas_ratio(po, depth),
            "water_fvf_rb_stb": self.water_fvf(pw),
            "oil_fvf_rb_stb": self.oil_fvf(po, depth),
            "gas_fvf_rb_mscf": linear(pg, self.pressure_points, self.bg),
        }


def fluids_in_place(source: dict, model: SPE2State) -> dict[str, float]:
    geometry = source["geometry_field_units"]
    layers = source["layer_table_field_units"]["rows"]
    inner = float(geometry["wellbore_radius_ft"])
    outer = float(geometry["radial_extent_ft"])
    depth = float(geometry["depth_to_top_ft"])
    oil_stb = water_stb = free_gas_scf = dissolved_gas_scf = 0.0
    for row in layers:
        thickness = float(row[1])
        porosity = float(row[4])
        center = depth + 0.5 * thickness
        state = model.state(center)
        bulk_ft3 = math.pi * (outer * outer - inner * inner) * thickness
        reservoir_barrels = bulk_ft3 * porosity / FT3_PER_RB
        water_stb += reservoir_barrels * state["water_saturation"] / state["water_fvf_rb_stb"]
        layer_oil_stb = reservoir_barrels * state["oil_saturation"] / state["oil_fvf_rb_stb"]
        oil_stb += layer_oil_stb
        free_gas_scf += (
            reservoir_barrels * state["gas_saturation"] / state["gas_fvf_rb_mscf"] * 1000.0
        )
        dissolved_gas_scf += layer_oil_stb * state["solution_gas_ratio_scf_stb"]
        depth += thickness
    return {
        "oil_million_stb": oil_stb / 1.0e6,
        "water_million_stb": water_stb / 1.0e6,
        "free_gas_billion_scf": free_gas_scf / 1.0e9,
        "dissolved_gas_billion_scf": dissolved_gas_scf / 1.0e9,
        "gas_billion_scf": (free_gas_scf + dissolved_gas_scf) / 1.0e9,
    }


def participant_envelope(source: dict) -> dict[str, tuple[float, float]]:
    rows = source["participant_initial_fluids_in_place"]["rows"]
    return {
        "oil_million_stb": (min(float(row[1]) for row in rows), max(float(row[1]) for row in rows)),
        "water_million_stb": (min(float(row[2]) for row in rows), max(float(row[2]) for row in rows)),
        "gas_billion_scf": (min(float(row[3]) for row in rows), max(float(row[3]) for row in rows)),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--check-only", action="store_true")
    parser.add_argument("--profile-step-ft", type=float, default=1.0)
    parser.add_argument("--allow-outside-participant-envelope", action="store_true")
    args = parser.parse_args()
    if not args.check_only and args.output_dir is None:
        parser.error("--output-dir is required unless --check-only is supplied")
    if args.output_dir is not None:
        args.output_dir.mkdir(parents=True, exist_ok=True)
    source = yaml.safe_load(SOURCE.read_text(encoding="utf-8"))
    model = SPE2State(source)
    top = float(source["geometry_field_units"]["depth_to_top_ft"])
    bottom = top + sum(float(row[1]) for row in source["layer_table_field_units"]["rows"])
    depths = [top + index * args.profile_step_ft for index in range(math.ceil((bottom - top) / args.profile_step_ft) + 1)]
    depths.extend([model.goc, model.woc, bottom])
    profile = [model.state(depth) for depth in sorted(set(min(depth, bottom) for depth in depths))]
    profile_path = args.output_dir / "initial_saturation_profile.csv" if args.output_dir else None
    if profile_path is not None:
        with profile_path.open("w", newline="", encoding="utf-8") as stream:
            fieldnames = list(profile[0]) + ["depth_m", "oil_pressure_Pa"]
            writer = csv.DictWriter(stream, fieldnames=fieldnames)
            writer.writeheader()
            for row in profile:
                writer.writerow({
                    **row,
                    "depth_m": row["depth_ft"] * 0.3048,
                    "oil_pressure_Pa": row["oil_pressure_psia"] * 6894.757293168,
                })
    fip = fluids_in_place(source, model)
    envelope = participant_envelope(source)
    checks = {
        name: {"value": fip[name], "minimum": bounds[0], "maximum": bounds[1], "pass": bounds[0] <= fip[name] <= bounds[1]}
        for name, bounds in envelope.items()
    }
    summary = {
        "status": "pass" if all(item["pass"] for item in checks.values()) else "fail",
        "method": "hydrostatic phase pressures plus inverse official capillary tables at layer centers",
        "fluids_in_place": fip,
        "participant_envelope_checks": checks,
        "profile": str(profile_path) if profile_path is not None else None,
    }
    if args.output_dir is not None:
        (args.output_dir / "initial_state_summary.json").write_text(
            json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )
    print(json.dumps(summary, sort_keys=True))
    if summary["status"] != "pass" and not args.allow_outside_participant_envelope:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
