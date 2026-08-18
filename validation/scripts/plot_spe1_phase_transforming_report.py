#!/usr/bin/env python3
"""Generate report-grade SPE1 CG/EG phase-transformation figures."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path

import matplotlib.colors as colors
import matplotlib.pyplot as plt
import numpy as np

LAYERS = (
    ("layer 1", 2537.46, 2543.556),
    ("layer 2", 2543.556, 2552.7),
    ("layer 3", 2552.7, 2567.94),
)

def read_rows(path: Path) -> list[dict[str, float]]:
    with path.open(newline="", encoding="utf-8") as stream:
        return [{k: float(v) for k, v in row.items()} for row in csv.DictReader(stream)]

def latest_nonempty(directory: Path, stem: str) -> Path:
    candidates = sorted(directory.glob(f"result_{stem}_*.csv"))
    nonempty = [p for p in candidates if sum(1 for _ in p.open(encoding="utf-8")) > 1]
    if not nonempty:
        raise SystemExit(f"no nonempty {stem} output in {directory}")
    return nonempty[-1]

def save(fig: plt.Figure, out: Path, stem: str) -> None:
    fig.savefig(out / f"{stem}.png", dpi=190, bbox_inches="tight")
    fig.savefig(out / f"{stem}.svg", bbox_inches="tight")
    plt.close(fig)

def layer_rows(rows: list[dict[str, float]], z0: float, z1: float) -> list[dict[str, float]]:
    return [r for r in rows if z0 <= r["z"] <= z1]

def scatter(ax, rows, field, norm=None, cmap="viridis", title=""):
    artist = ax.scatter([r["x"] for r in rows], [r["y"] for r in rows],
                        c=[r[field] for r in rows], s=12, marker="s",
                        linewidths=0, cmap=cmap, norm=norm)
    ax.scatter([152.4], [152.4], marker="^", color="white", edgecolor="black", s=45)
    ax.scatter([2895.6], [2895.6], marker="v", color="white", edgecolor="black", s=45)
    ax.set_title(title)
    ax.set_aspect("equal")
    ax.set_xlim(0, 3048)
    ax.set_ylim(0, 3048)
    ax.set_xlabel("x [m]")
    return artist

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("artifact", type=Path)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--allow-incomplete", action="store_true")
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    summary = json.loads((args.artifact / "verification_summary.json").read_text())
    provenance = json.loads((args.artifact / "provenance.json").read_text())
    if not args.allow_incomplete:
        if summary.get("status") != "pass":
            raise SystemExit("artifact is not accepted")
        if provenance.get("unchanged_during_run") is not True:
            raise SystemExit("artifact provenance changed during execution")

    history = read_rows(args.artifact / "result.csv")
    physical = read_rows(latest_nonempty(args.artifact, "physical_element_fields"))
    rates = read_rows(latest_nonempty(args.artifact, "phase_rate_element_field"))
    mechanics = read_rows(latest_nonempty(args.artifact, "nodal_mechanics"))
    temperature = read_rows(latest_nonempty(args.artifact, "nodal_temperature"))
    rate_by_id = {int(r["id"]): r["gas_phase_transformation_rate"] for r in rates}
    for row in physical:
        row["phase_rate"] = rate_by_id[int(row["id"])]

    plt.style.use("seaborn-v0_8-whitegrid")

    pmin = min(r["sample_oil_pressure"] for r in physical) / 1e6
    pmax = max(r["sample_oil_pressure"] for r in physical) / 1e6
    sgmax = max(r["sample_gas_saturation"] for r in physical)
    fig, axes = plt.subplots(2, 3, figsize=(13, 8), sharex=True, sharey=True)
    pressure_artist = saturation_artist = None
    for col, (name, z0, z1) in enumerate(LAYERS):
        rows = layer_rows(physical, z0, z1)
        pressure_rows = [dict(r, pressure_mpa=r["sample_oil_pressure"] / 1e6) for r in rows]
        pressure_artist = scatter(axes[0, col], pressure_rows, "pressure_mpa",
                                  norm=colors.Normalize(pmin, pmax),
                                  cmap="viridis", title=f"{name}: oil pressure")
        saturation_artist = scatter(axes[1, col], rows, "sample_gas_saturation",
                                    norm=colors.Normalize(0, max(sgmax, 1e-12)),
                                    cmap="magma", title=f"{name}: gas saturation")
        axes[1, col].set_ylabel("y [m]" if col == 0 else "")
    axes[0, 0].set_ylabel("y [m]")
    fig.colorbar(pressure_artist, ax=axes[0, :], fraction=0.02, pad=0.02,
                 label="oil pressure [MPa]")
    fig.colorbar(saturation_artist, ax=axes[1, :], fraction=0.02, pad=0.02,
                 label="gas saturation [-]")
    fig.suptitle("SPE1 reconstructed CG/EG fields by physical layer\n"
                 "triangles: injector; inverted triangles: producer")
    save(fig, args.output_dir, "spe1_spatial_pressure_gas")

    active_layer = layer_rows(physical, LAYERS[0][1], LAYERS[0][2])
    fields = (
        ("sample_tau", "transfer potential τ", "coolwarm"),
        ("phase_rate", "phase-transformation rate", "coolwarm"),
        ("sample_generalized_conversion", "generalized conversion force", "coolwarm"),
        ("sample_reaction_power", "reaction power / dissipation", "coolwarm"),
    )
    fig, axes = plt.subplots(2, 2, figsize=(10.5, 9), sharex=True, sharey=True)
    for ax, (field, title, cmap) in zip(axes.flat, fields):
        vals = np.array([r[field] for r in active_layer])
        vmax = max(float(np.max(np.abs(vals))), 1e-30)
        linthresh = max(vmax * 1e-6, 1e-30)
        norm = colors.SymLogNorm(linthresh=linthresh, vmin=-vmax, vmax=vmax)
        artist = scatter(ax, active_layer, field, norm=norm, cmap=cmap, title=title)
        fig.colorbar(artist, ax=ax, fraction=0.045)
    fig.suptitle("SPE1 nonequilibrium thermodynamics in injector layer")
    save(fig, args.output_dir, "spe1_spatial_nonequilibrium")

    max_z_mech = max(r["z"] for r in mechanics)
    top_mech = [r for r in mechanics if abs(r["z"] - max_z_mech) < 1e-8]
    for r in top_mech:
        r["u_mm"] = 1000.0 * np.sqrt(r["ux"]**2 + r["uy"]**2 + r["uz"]**2)
    max_z_temp = max(r["z"] for r in temperature)
    top_temp = [r for r in temperature if abs(r["z"] - max_z_temp) < 1e-8]
    for r in top_temp:
        r["delta_temperature"] = r["fluid_temperature"] - r["solid_temperature"]
    fig, axes = plt.subplots(1, 2, figsize=(11, 4.8))
    artist = scatter(axes[0], top_mech, "u_mm", cmap="viridis",
                     title="top-surface displacement magnitude")
    fig.colorbar(artist, ax=axes[0], label="|u| [mm]")
    artist = scatter(axes[1], top_temp, "delta_temperature", cmap="coolwarm",
                     title="top-surface fluid-solid temperature difference")
    fig.colorbar(artist, ax=axes[1], label="T fluid - T solid [K]")
    save(fig, args.output_dir, "spe1_spatial_mechanics_temperature")

    accepted = [r for r in history if r["time"] > 0]
    hours = np.array([r["time"] / 3600 for r in accepted])
    fig, axes = plt.subplots(2, 2, figsize=(11, 7.5))
    ax = axes[0, 0]
    for field, label in (("average_gas_saturation", "average"),
                         ("maximum_gas_saturation", "maximum")):
        ax.plot(hours, [r[field] for r in accepted], marker="o", label=label)
    ax.set(xlabel="time [h]", ylabel="gas saturation [-]", title="phase appearance")
    ax.legend()
    ax = axes[0, 1]
    for component in ("water", "oil", "gas"):
        ax.semilogy(hours, [max(abs(r[f"{component}_global_balance"]), 1e-18)
                           for r in accepted], marker="o", label=component)
    ax.axhline(1e-6, color="black", linestyle="--", label="gate")
    ax.set(xlabel="time [h]", ylabel="absolute balance defect", title="global conservation")
    ax.legend()
    ax = axes[1, 0]
    gates = (("matrix_component_balance_l2", 1e-6, "matrix"),
             ("phase_volume_constraint_l2", 1e-8, "volume"),
             ("phase_transform_kinetic_residual_l2", 1e-7, "kinetic"))
    for field, gate, label in gates:
        ax.semilogy(hours, [max(abs(r[field]) / gate, 1e-14) for r in accepted],
                    marker="o", label=label)
    ax.axhline(1, color="black", linestyle="--")
    ax.set(xlabel="time [h]", ylabel="residual / gate", title="normalized verification gates")
    ax.legend()
    ax = axes[1, 1]
    ax.plot(hours, [r["average_tau"] for r in accepted], marker="o", label="average τ")
    ax2 = ax.twinx()
    ax2.plot(hours, [r["average_gas_phase_transformation_rate"] for r in accepted],
             marker="s", color="C3", label="phase rate")
    ax.set(xlabel="time [h]", ylabel="average τ", title="nonequilibrium evolution")
    ax2.set_ylabel("average phase rate")
    lines = ax.lines + ax2.lines
    ax.legend(lines, [line.get_label() for line in lines])
    save(fig, args.output_dir, "spe1_phase_transforming_history")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
