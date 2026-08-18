#!/usr/bin/env python3
"""Extract benchmark-ready black-oil data from an ECLIPSE-style DATA deck as JSON."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path


TARGET_KEYWORDS = ("PVTW", "PVDG", "PVTO", "DENSITY", "SWOF", "SGOF")
GRID_KEYWORDS = ("DX", "DY", "DZ", "TOPS", "PORO", "PERMX", "PERMY", "PERMZ")
KEYWORD_LINE = re.compile(r"^[A-Z][A-Z0-9_-]*$")
NUMBER = re.compile(r"^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[EeDd][+-]?\d+)?$")

FT_TO_M = 0.3048
PSI_TO_PA = 6894.757293168
MD_TO_M2 = 9.869233e-16
LBFT3_TO_KGM3 = 16.01846337396014
RB_TO_M3 = 0.158987294928
MSCF_TO_SM3 = 28.316846592
DAY_TO_S = 86400.0
BG_FIELD_TO_SI = RB_TO_M3 / MSCF_TO_SM3
RS_FIELD_TO_SI = MSCF_TO_SM3 / RB_TO_M3


def cleaned_lines(path: Path) -> list[str]:
    lines: list[str] = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.split("--", 1)[0].strip()
        if line:
            lines.append(line)
    return lines


def section(lines: list[str], keyword: str) -> list[str]:
    try:
        start = next(i for i, line in enumerate(lines) if line == keyword) + 1
    except StopIteration as error:
        raise ValueError(f"required keyword {keyword} is absent") from error
    end = len(lines)
    for i in range(start, len(lines)):
        if KEYWORD_LINE.fullmatch(lines[i]):
            end = i
            break
    return lines[start:end]


def expand_token(token: str) -> list[float]:
    if "*" in token:
        count_text, value_text = token.split("*", 1)
        if count_text.isdigit() and NUMBER.fullmatch(value_text):
            return [float(value_text.replace("D", "E").replace("d", "e"))] * int(count_text)
    if not NUMBER.fullmatch(token):
        raise ValueError(f"non-numeric token {token!r} in numeric table")
    return [float(token.replace("D", "E").replace("d", "e"))]


def numeric_records(lines: list[str]) -> list[list[float]]:
    records: list[list[float]] = []
    current: list[float] = []
    for token in re.findall(r"/|[^\s/]+", " ".join(lines)):
        if token == "/":
            if current:
                records.append(current)
                current = []
        else:
            current.extend(expand_token(token))
    if current:
        records.append(current)
    return records


def raw_records(lines: list[str]) -> list[list[str | float | None]]:
    records: list[list[str | float | None]] = []
    current: list[str | float | None] = []
    for token in re.findall(r"/|'[^']*'|[^\s/]+", " ".join(lines)):
        if token == "/":
            if current:
                records.append(current)
                current = []
            continue
        default_match = re.fullmatch(r"(\d+)\*", token)
        if default_match:
            current.extend([None] * int(default_match.group(1)))
        elif NUMBER.fullmatch(token):
            current.append(float(token.replace("D", "E").replace("d", "e")))
        elif token.startswith("'") and token.endswith("'"):
            current.append(token[1:-1])
        else:
            current.append(token)
    if current:
        records.append(current)
    return records


def rows(values: list[float], width: int, keyword: str) -> list[list[float]]:
    if len(values) % width:
        raise ValueError(f"{keyword} contains {len(values)} values, not a multiple of {width}")
    return [values[i : i + width] for i in range(0, len(values), width)]


def convert_to_si(data: dict[str, object]) -> dict[str, object]:
    pvtw = data["pvtw"]
    density = data["density"]
    grid_properties = data["grid"]["properties"]
    equil = data["initialization"]["equil"]
    well_specs = data["wells"]["specifications"]
    completions = data["wells"]["completions"]
    producer = data["wells"]["producer_controls"][0]
    injector = data["wells"]["injector_controls"][0]
    return {
        "conversion_constants": {
            "ft_to_m": FT_TO_M,
            "psi_to_pa": PSI_TO_PA,
            "md_to_m2": MD_TO_M2,
            "lb_ft3_to_kg_m3": LBFT3_TO_KGM3,
            "rb_to_m3": RB_TO_M3,
            "mscf_to_standard_m3": MSCF_TO_SM3,
            "day_to_s": DAY_TO_S,
            "bg_rb_per_mscf_to_reservoir_m3_per_standard_m3": BG_FIELD_TO_SI,
            "rs_mscf_per_stb_to_standard_m3_per_stock_tank_m3": RS_FIELD_TO_SI,
        },
        "pvtw": [
            pvtw[0] * PSI_TO_PA,
            pvtw[1],
            pvtw[2] / PSI_TO_PA,
            pvtw[3] * 1e-3,
            pvtw[4] / PSI_TO_PA,
        ],
        "density": [value * LBFT3_TO_KGM3 for value in density],
        "pvdg": [
            [pressure * PSI_TO_PA, fvf * BG_FIELD_TO_SI, viscosity * 1e-3]
            for pressure, fvf, viscosity in data["pvdg"]
        ],
        "pvto": [
            {
                "solution_gas_oil_ratio": branch["solution_gas_oil_ratio"] * RS_FIELD_TO_SI,
                "rows": [
                    [pressure * PSI_TO_PA, fvf, viscosity * 1e-3]
                    for pressure, fvf, viscosity in branch["rows"]
                ],
            }
            for branch in data["pvto"]
        ],
        "swof": [
            [saturation, krw, krow, capillary_pressure * PSI_TO_PA]
            for saturation, krw, krow, capillary_pressure in data["swof"]
        ],
        "sgof": [
            [saturation, krg, krog, capillary_pressure * PSI_TO_PA]
            for saturation, krg, krog, capillary_pressure in data["sgof"]
        ],
        "grid": {
            "dimensions": [int(value) for value in data["grid"]["dimensions"]],
            "properties": {
                "dx": [value * FT_TO_M for value in grid_properties["dx"]],
                "dy": [value * FT_TO_M for value in grid_properties["dy"]],
                "dz": [value * FT_TO_M for value in grid_properties["dz"]],
                "tops": [value * FT_TO_M for value in grid_properties["tops"]],
                "poro": grid_properties["poro"],
                "permx": [value * MD_TO_M2 for value in grid_properties["permx"]],
                "permy": [value * MD_TO_M2 for value in grid_properties["permy"]],
                "permz": [value * MD_TO_M2 for value in grid_properties["permz"]],
            },
        },
        "rock": {
            "reference_pressure_pa": data["rock"]["reference_pressure"] * PSI_TO_PA,
            "compressibility_per_pa": data["rock"]["compressibility"] / PSI_TO_PA,
        },
        "initialization": {
            "equil": [
                equil[0] * FT_TO_M,
                equil[1] * PSI_TO_PA,
                equil[2] * FT_TO_M,
                equil[3] * PSI_TO_PA,
                equil[4] * FT_TO_M,
                equil[5] * PSI_TO_PA,
                int(equil[6]),
                int(equil[7]),
                int(equil[8]),
            ],
            "rsvd": [[depth * FT_TO_M, rs * RS_FIELD_TO_SI] for depth, rs in data["initialization"]["rsvd"]],
        },
        "wells": {
            "specifications": [
                {
                    "name": record[0],
                    "group": record[1],
                    "i": int(record[2]),
                    "j": int(record[3]),
                    "reference_depth_m": record[4] * FT_TO_M,
                    "preferred_phase": record[5],
                }
                for record in well_specs
            ],
            "completions": [
                {
                    "name": record[0],
                    "i": int(record[1]),
                    "j": int(record[2]),
                    "k_top": int(record[3]),
                    "k_bottom": int(record[4]),
                    "status": record[5],
                    "saturation_table": record[6],
                    "connection_transmissibility": record[7],
                    "diameter_m": record[8] * FT_TO_M,
                }
                for record in completions
            ],
            "producer_control": {
                "name": producer[0],
                "status": producer[1],
                "mode": producer[2],
                "oil_surface_rate_m3_s": producer[3] * RB_TO_M3 / DAY_TO_S,
                "minimum_bhp_pa": producer[8] * PSI_TO_PA,
            },
            "injector_control": {
                "name": injector[0],
                "phase": injector[1],
                "status": injector[2],
                "mode": injector[3],
                "gas_surface_rate_standard_m3_s": injector[4] * MSCF_TO_SM3 / DAY_TO_S,
                "maximum_bhp_pa": injector[6] * PSI_TO_PA,
            },
        },
        "schedule": {
            "time_steps_s": [value * DAY_TO_S for value in data["schedule"]["time_steps_days"]],
            "end_time_s": data["schedule"]["end_time_days"] * DAY_TO_S,
        },
    }


def extract(path: Path) -> dict[str, object]:
    lines = cleaned_lines(path)
    records = {keyword: numeric_records(section(lines, keyword)) for keyword in TARGET_KEYWORDS}
    if len(records["PVTW"]) != 1 or len(records["PVTW"][0]) != 5:
        raise ValueError("PVTW must contain one five-value record")
    if len(records["DENSITY"]) != 1 or len(records["DENSITY"][0]) != 3:
        raise ValueError("DENSITY must contain one three-value record")

    pvto: list[dict[str, object]] = []
    for record in records["PVTO"]:
        if len(record) < 4 or (len(record) - 1) % 3:
            raise ValueError("each PVTO branch must contain R_s followed by pressure/B_o/mu triples")
        pvto.append({"solution_gas_oil_ratio": record[0], "rows": rows(record[1:], 3, "PVTO")})

    dimensions = numeric_records(section(lines, "DIMENS"))[0]
    grid = {
        keyword.lower(): numeric_records(section(lines, keyword))[0]
        for keyword in GRID_KEYWORDS
    }
    rock = numeric_records(section(lines, "ROCK"))[0]
    equil = numeric_records(section(lines, "EQUIL"))[0]
    rsvd = rows(numeric_records(section(lines, "RSVD"))[0], 2, "RSVD")
    well_specs = raw_records(section(lines, "WELSPECS"))
    completions = raw_records(section(lines, "COMPDAT"))
    producer_controls = raw_records(section(lines, "WCONPROD"))
    injector_controls = raw_records(section(lines, "WCONINJE"))
    time_steps = numeric_records(section(lines, "TSTEP"))[0]

    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    data = {
        "source": {"path": str(path), "sha256": digest},
        "pvtw": records["PVTW"][0],
        "density": records["DENSITY"][0],
        "pvdg": rows(records["PVDG"][0], 3, "PVDG"),
        "pvto": pvto,
        "swof": rows(records["SWOF"][0], 4, "SWOF"),
        "sgof": rows(records["SGOF"][0], 4, "SGOF"),
        "grid": {"dimensions": dimensions, "properties": grid},
        "rock": {"reference_pressure": rock[0], "compressibility": rock[1]},
        "initialization": {"equil": equil, "rsvd": rsvd},
        "wells": {
            "specifications": well_specs,
            "completions": completions,
            "producer_controls": producer_controls,
            "injector_controls": injector_controls,
        },
        "schedule": {
            "time_steps_days": time_steps,
            "end_time_days": sum(time_steps),
        },
    }
    data["si"] = convert_to_si(data)
    return data


def validate_spe1_case1(data: dict[str, object]) -> None:
    if data["pvtw"] != [4017.55, 1.038, 3.22e-6, 0.318, 0.0]:
        raise ValueError("SPE1 PVTW values differ from the pinned Case 1 deck")
    if data["density"] != [53.66, 64.49, 0.0533]:
        raise ValueError("SPE1 surface densities differ from the pinned Case 1 deck")
    if len(data["pvdg"]) != 10 or len(data["pvto"]) != 9:
        raise ValueError("SPE1 PVDG/PVTO row counts differ from the pinned Case 1 deck")
    if len(data["swof"]) != 15 or len(data["sgof"]) != 15:
        raise ValueError("SPE1 SWOF/SGOF row counts differ from the pinned Case 1 deck")
    pvto = data["pvto"]
    if pvto[7]["solution_gas_oil_ratio"] != 1.27 or len(pvto[7]["rows"]) != 2:
        raise ValueError("SPE1 R_s=1.27 undersaturated PVTO branch is missing")
    if data["grid"]["dimensions"] != [10.0, 10.0, 3.0]:
        raise ValueError("SPE1 grid dimensions differ from the pinned Case 1 deck")
    expected_counts = {
        "dx": 300,
        "dy": 300,
        "dz": 300,
        "tops": 100,
        "poro": 300,
        "permx": 300,
        "permy": 300,
        "permz": 300,
    }
    for keyword, count in expected_counts.items():
        if len(data["grid"]["properties"][keyword]) != count:
            raise ValueError(f"SPE1 {keyword.upper()} count differs from the pinned Case 1 deck")
    if data["rock"] != {"reference_pressure": 14.7, "compressibility": 3e-6}:
        raise ValueError("SPE1 ROCK values differ from the pinned Case 1 deck")
    if data["initialization"]["equil"] != [8400.0, 4800.0, 8450.0, 0.0, 8300.0, 0.0, 1.0, 0.0, 0.0]:
        raise ValueError("SPE1 EQUIL values differ from the pinned Case 1 deck")
    if data["initialization"]["rsvd"] != [[8300.0, 1.27], [8450.0, 1.27]]:
        raise ValueError("SPE1 RSVD values differ from the pinned Case 1 deck")
    if len(data["wells"]["specifications"]) != 2 or len(data["wells"]["completions"]) != 2:
        raise ValueError("SPE1 well/completion counts differ from the pinned Case 1 deck")
    if data["wells"]["producer_controls"] != [["PROD", "OPEN", "ORAT", 20000.0, None, None, None, None, 1000.0]]:
        raise ValueError("SPE1 producer control differs from the pinned Case 1 deck")
    if data["wells"]["injector_controls"] != [["INJ", "GAS", "OPEN", "RATE", 100000.0, None, 9014.0]]:
        raise ValueError("SPE1 injector control differs from the pinned Case 1 deck")
    if len(data["schedule"]["time_steps_days"]) != 120 or data["schedule"]["end_time_days"] != 3650.0:
        raise ValueError("SPE1 TSTEP schedule differs from the pinned Case 1 deck")
    si = data["si"]
    if si["grid"]["properties"]["dz"][::100] != [6.096, 9.144, 15.24]:
        raise ValueError("SPE1 SI layer thickness conversion is inconsistent")
    if si["grid"]["properties"]["permx"][0] != 4.9346165e-13:
        raise ValueError("SPE1 SI permeability conversion is inconsistent")
    if abs(si["initialization"]["rsvd"][0][1] - 1.27 * RS_FIELD_TO_SI) > 1e-12:
        raise ValueError("SPE1 SI R_s conversion is inconsistent")
    if abs(si["wells"]["producer_control"]["oil_surface_rate_m3_s"] -
           20000.0 * RB_TO_M3 / DAY_TO_S) > 1e-15:
        raise ValueError("SPE1 SI producer-rate conversion is inconsistent")
    if abs(si["wells"]["injector_control"]["gas_surface_rate_standard_m3_s"] -
           100000.0 * MSCF_TO_SM3 / DAY_TO_S) > 1e-12:
        raise ValueError("SPE1 SI injector-rate conversion is inconsistent")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("deck", type=Path)
    parser.add_argument("--validate-spe1-case1", action="store_true")
    args = parser.parse_args()
    data = extract(args.deck)
    if args.validate_spe1_case1:
        validate_spe1_case1(data)
    print(json.dumps(data, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
