#!/usr/bin/env python3
"""Generate candidate SPE2 history and depth-profile figures from run artifacts."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np


def read_rows(path: Path) -> list[dict[str, float]]:
    with path.open(newline="", encoding="utf-8") as stream:
        return [
            {key: float(value) for key, value in row.items() if value not in (None, "")}
            for row in csv.DictReader(stream)
        ]


def values(rows: list[dict[str, float]], name: str) -> np.ndarray:
    if not rows or name not in rows[0]:
        raise SystemExit(f"required CSV column is missing: {name}")
    return np.asarray([row[name] for row in rows])


def save(fig: plt.Figure, output: Path, stem: str) -> None:
    fig.savefig(output / f"{stem}.png", dpi=190, bbox_inches="tight")
    fig.savefig(output / f"{stem}.svg", bbox_inches="tight")
    plt.close(fig)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("artifact", type=Path)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--allow-incomplete", action="store_true")
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    summary = json.loads((args.artifact / "verification_summary.json").read_text(encoding="utf-8"))
    if not args.allow_incomplete and summary.get("status") != "candidate_pass":
        raise SystemExit("candidate coupled gates have not passed; use --allow-incomplete for diagnosis")
    rows = read_rows(args.artifact / "result.csv")
    days = values(rows, "time") / 86400.0
    oil_rate = values(rows, "spe2_total_oil_surface_rate") * 86400.0 / 0.158987294928
    water_rate = (
        values(rows, "spe2_completion_7_water_surface_rate")
        + values(rows, "spe2_completion_8_water_surface_rate")
    )
    gas_rate = (
        values(rows, "spe2_completion_7_gas_surface_rate")
        + values(rows, "spe2_completion_8_gas_surface_rate")
    )
    water_cut = np.divide(water_rate, water_rate + values(rows, "spe2_total_oil_surface_rate"),
                          out=np.zeros_like(water_rate), where=(water_rate + values(rows, "spe2_total_oil_surface_rate")) != 0)
    gor = np.divide(gas_rate, values(rows, "spe2_total_oil_surface_rate"),
                    out=np.zeros_like(gas_rate), where=values(rows, "spe2_total_oil_surface_rate") != 0)
    bhp_psi = values(rows, "spe2_datum_bhp") / 6894.757293168

    plt.style.use("seaborn-v0_8-whitegrid")
    fig, axes = plt.subplots(2, 2, figsize=(11, 7.5), sharex=True)
    axes[0, 0].step(days, oil_rate, where="post")
    axes[0, 0].set(ylabel="oil rate [STB/day]", title="producer control")
    axes[0, 1].plot(days, water_cut)
    axes[0, 1].set(ylabel="water cut [-]", title="water coning")
    axes[1, 0].plot(days, gor)
    axes[1, 0].set(xlabel="time [day]", ylabel="surface gas/oil ratio [-]", title="gas coning")
    axes[1, 1].plot(days, bhp_psi)
    axes[1, 1].axhline(3000.0, color="black", linestyle="--", label="minimum BHP")
    axes[1, 1].set(xlabel="time [day]", ylabel="datum BHP [psia]", title="rate/BHP switch")
    axes[1, 1].legend()
    save(fig, args.output_dir, "spe2_well_histories")

    balance_names = ("water_relative_balance", "oil_relative_balance", "gas_relative_balance")
    fig, axes = plt.subplots(1, 2, figsize=(11, 4.5))
    for name in balance_names:
        if name in rows[0]:
            axes[0].semilogy(days, np.maximum(np.abs(values(rows, name)), 1e-18), label=name.split("_")[0])
    axes[0].axhline(1e-6, color="black", linestyle="--", label="gate")
    axes[0].set(xlabel="time [day]", ylabel="relative defect", title="component conservation")
    axes[0].legend()
    for name, label in (
        ("minimum_solid_reference_jacobian", "minimum J"),
        ("minimum_water_saturation", "minimum water saturation"),
        ("minimum_gas_saturation", "minimum gas saturation"),
        ("minimum_oil_saturation", "minimum oil saturation"),
    ):
        if name in rows[0]:
            axes[1].plot(days, values(rows, name), label=label)
    axes[1].set(xlabel="time [day]", ylabel="minimum value", title="admissibility")
    axes[1].legend()
    save(fig, args.output_dir, "spe2_conservation_admissibility")

    profile_path = args.artifact / "initial_saturation_profile.csv"
    if profile_path.is_file():
        profile = read_rows(profile_path)
        depth_ft = values(profile, "depth_m") / 0.3048
        fig, ax = plt.subplots(figsize=(5.5, 7))
        ax.plot(values(profile, "water_saturation"), depth_ft, label="water")
        ax.plot(values(profile, "gas_saturation"), depth_ft, label="gas")
        ax.invert_yaxis()
        ax.set(xlabel="saturation [-]", ylabel="depth [ft]", title="initial SPE2 saturation profile")
        ax.legend()
        save(fig, args.output_dir, "spe2_initial_saturation_profile")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
