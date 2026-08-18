#!/usr/bin/env python3
"""Generate accepted SPE1 all-physics CG/EG verification figures."""

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
PSI_PER_PA = 1.0 / 6894.757293168
STB_PER_M3 = 6.289810770432105
MSCF_PER_M3 = 0.03531466672148859
SECONDS_PER_DAY = 86400.0


def read_rows(path: Path) -> list[dict[str, float]]:
    with path.open(newline="", encoding="utf-8") as stream:
        return [{key: float(value) for key, value in row.items()} for row in csv.DictReader(stream)]


def latest_nonempty(directory: Path, stem: str) -> Path:
    candidates = sorted(directory.glob(f"result_{stem}_*.csv"))
    nonempty = [path for path in candidates if sum(1 for _ in path.open(encoding="utf-8")) > 1]
    if not nonempty:
        raise SystemExit(f"no nonempty {stem} output in {directory}")
    return nonempty[-1]


def save(fig: plt.Figure, output_dir: Path, stem: str) -> None:
    fig.savefig(output_dir / f"{stem}.png", dpi=190, bbox_inches="tight")
    fig.savefig(output_dir / f"{stem}.svg", bbox_inches="tight")
    plt.close(fig)


def layer_rows(rows: list[dict[str, float]], z0: float, z1: float) -> list[dict[str, float]]:
    return [row for row in rows if z0 <= row["z"] <= z1]


def scatter(ax, rows, field, *, norm=None, cmap="viridis", title=""):
    artist = ax.scatter(
        [row["x"] for row in rows],
        [row["y"] for row in rows],
        c=[row[field] for row in rows],
        s=12,
        marker="s",
        linewidths=0,
        cmap=cmap,
        norm=norm,
    )
    ax.scatter([152.4], [152.4], marker="^", color="white", edgecolor="black", s=45)
    ax.scatter([2895.6], [2895.6], marker="v", color="white", edgecolor="black", s=45)
    ax.set_title(title)
    ax.set_aspect("equal")
    ax.set_xlim(0, 3048)
    ax.set_ylim(0, 3048)
    ax.set_xlabel("x [m]")
    return artist


def symmetric_norm(rows, field):
    values = np.asarray([row[field] for row in rows])
    maximum = max(float(np.max(np.abs(values))), 1.0e-30)
    return colors.SymLogNorm(linthresh=max(maximum * 1.0e-6, 1.0e-30),
                             vmin=-maximum, vmax=maximum)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("artifact", type=Path)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--opm", type=Path,
                        default=Path("validation/reference_data/spe1_case1_opm_flow_2021_10.csv"))
    parser.add_argument("--allow-incomplete", action="store_true")
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    summary = json.loads((args.artifact / "verification_summary.json").read_text())
    provenance = json.loads((args.artifact / "provenance.json").read_text())
    audit_path = args.artifact / "time_history_audit.json"
    if not args.allow_incomplete:
        if summary.get("status") != "pass":
            raise SystemExit("artifact endpoint verification did not pass")
        if provenance.get("unchanged_during_run") is not True:
            raise SystemExit("artifact provenance changed during execution")
        if not audit_path.exists() or json.loads(audit_path.read_text()).get("status") != "pass":
            raise SystemExit("all-timestep audit is absent or failed")

    history = read_rows(args.artifact / "result.csv")
    accepted = [row for row in history if row["time"] > 0]
    physical = read_rows(latest_nonempty(args.artifact, "physical_element_fields"))
    rates = read_rows(latest_nonempty(args.artifact, "phase_rate_element_field"))
    mechanics = read_rows(latest_nonempty(args.artifact, "nodal_mechanics"))
    temperature = read_rows(latest_nonempty(args.artifact, "nodal_temperature"))
    rate_by_id = {int(row["id"]): row["gas_phase_transformation_rate"] for row in rates}
    for row in physical:
        row["phase_rate"] = rate_by_id[int(row["id"])]

    plt.style.use("seaborn-v0_8-whitegrid")

    pressure = [row["sample_oil_pressure"] / 1.0e6 for row in physical]
    saturation = [row["sample_gas_saturation"] for row in physical]
    fig, axes = plt.subplots(2, 3, figsize=(13, 8), sharex=True, sharey=True)
    for column, (name, z0, z1) in enumerate(LAYERS):
        rows = layer_rows(physical, z0, z1)
        pressure_rows = [dict(row, pressure_mpa=row["sample_oil_pressure"] / 1.0e6)
                         for row in rows]
        p_artist = scatter(axes[0, column], pressure_rows, "pressure_mpa",
                           norm=colors.Normalize(min(pressure), max(pressure)),
                           title=f"{name}: oil pressure")
        s_artist = scatter(axes[1, column], rows, "sample_gas_saturation",
                           norm=colors.Normalize(0, max(max(saturation), 1.0e-12)), cmap="magma",
                           title=f"{name}: gas saturation")
    axes[0, 0].set_ylabel("y [m]")
    axes[1, 0].set_ylabel("y [m]")
    fig.colorbar(p_artist, ax=axes[0, :], fraction=0.02, pad=0.02, label="oil pressure [MPa]")
    fig.colorbar(s_artist, ax=axes[1, :], fraction=0.02, pad=0.02, label="gas saturation [-]")
    fig.suptitle("SPE1 reconstructed CG/EG fields by physical layer\n"
                 "triangles: injector; inverted triangles: producer")
    save(fig, args.output_dir, "spe1_spatial_pressure_gas")

    active_layer = layer_rows(physical, LAYERS[0][1], LAYERS[0][2])
    fields = (
        ("sample_tau", "transfer coordinate τ"),
        ("sample_dissolved_mu", "dissolved-gas μ"),
        ("sample_free_mu", "free-gas μ"),
        ("sample_affinity", "phase-transfer affinity"),
        ("phase_rate", "phase-transformation rate"),
        ("sample_generalized_conversion", "generalized conversion force"),
        ("sample_kinetic_residual", "kinetic residual"),
        ("sample_reaction_power", "conversion power / dissipation"),
    )
    fig, axes = plt.subplots(2, 4, figsize=(17, 8.2), sharex=True, sharey=True)
    for ax, (field, title) in zip(axes.flat, fields):
        artist = scatter(ax, active_layer, field, norm=symmetric_norm(active_layer, field),
                         cmap="coolwarm", title=title)
        fig.colorbar(artist, ax=ax, fraction=0.045)
    axes[0, 0].set_ylabel("y [m]")
    axes[1, 0].set_ylabel("y [m]")
    fig.suptitle("SPE1 nonequilibrium thermodynamics in the injector layer")
    save(fig, args.output_dir, "spe1_spatial_nonequilibrium")

    top_z = max(row["z"] for row in mechanics)
    top_mechanics = [row for row in mechanics if abs(row["z"] - top_z) < 1.0e-8]
    for row in top_mechanics:
        row["u_mm"] = 1000.0 * np.sqrt(row["ux"] ** 2 + row["uy"] ** 2 + row["uz"] ** 2)
    top_z = max(row["z"] for row in temperature)
    top_temperature = [row for row in temperature if abs(row["z"] - top_z) < 1.0e-8]
    for row in top_temperature:
        row["delta_temperature"] = row["fluid_temperature"] - row["solid_temperature"]
    fig, axes = plt.subplots(1, 2, figsize=(11, 4.8))
    artist = scatter(axes[0], top_mechanics, "u_mm", title="top displacement magnitude")
    fig.colorbar(artist, ax=axes[0], label="|u| [mm]")
    artist = scatter(axes[1], top_temperature, "delta_temperature", cmap="coolwarm",
                     title="top fluid-solid temperature difference")
    fig.colorbar(artist, ax=axes[1], label="T fluid - T solid [K]")
    save(fig, args.output_dir, "spe1_spatial_mechanics_temperature")

    hours = np.asarray([row["time"] / 3600.0 for row in accepted])
    fig, axes = plt.subplots(3, 2, figsize=(12, 11))
    axes[0, 0].plot(hours, [row["average_gas_saturation"] for row in accepted], "o-",
                          label="average")
    axes[0, 0].plot(hours, [row["maximum_gas_saturation"] for row in accepted], "o-",
                          label="maximum")
    axes[0, 0].set(title="phase appearance", ylabel="gas saturation [-]")
    axes[0, 0].legend()
    for component in ("water", "oil", "gas"):
        axes[0, 1].semilogy(hours, [max(abs(row[f"{component}_global_balance"]), 1.0e-18)
                                   for row in accepted], "o-", label=component)
    axes[0, 1].axhline(1.0e-6, color="black", linestyle="--", label="gate")
    axes[0, 1].set(title="global component conservation", ylabel="absolute defect [kg/s]")
    axes[0, 1].legend()
    equation_gates = (
        ("tau_evolution_residual_l2", 1.0e-7, "tau evolution"),
        ("phase_transform_kinetic_residual_l2", 1.0e-7, "kinetics"),
        ("matrix_momentum_z_scaled_weak_residual_linf", 1.0e-7, "momentum z"),
        ("fluid_energy_scaled_weak_residual_linf", 1.0e-7, "fluid energy"),
        ("solid_energy_scaled_weak_residual_linf", 1.0e-7, "solid energy"),
    )
    for field, gate, label in equation_gates:
        axes[1, 0].semilogy(hours, [max(abs(row[field]) / gate, 1.0e-16) for row in accepted],
                           "o-", label=label)
    axes[1, 0].axhline(1, color="black", linestyle="--")
    axes[1, 0].set(title="equation residual / gate", ylabel="normalized residual")
    axes[1, 0].legend()
    identity_gates = (
        "phase_transform_affinity_identity_l2",
        "phase_transform_generalized_force_identity_l2",
        "phase_transform_power_identity_l2",
    )
    for field in identity_gates:
        axes[1, 1].semilogy(hours, [max(abs(row[field]) / 1.0e-12, 1.0e-16)
                                   for row in accepted], "o-", label=field.replace("phase_transform_", "").replace("_identity_l2", ""))
    axes[1, 1].axhline(1, color="black", linestyle="--")
    axes[1, 1].set(title="thermodynamic identity residual / gate", ylabel="normalized residual")
    axes[1, 1].legend()
    axes[2, 0].plot(hours, [row["average_reconstructed_tau"] for row in accepted], "o-", label="τ")
    axes[2, 0].plot(hours, [row["average_phase_transform_dissolved_mu"] for row in accepted], "o-", label="dissolved μ")
    axes[2, 0].plot(hours, [row["average_phase_transform_free_mu"] for row in accepted], "o-", label="free μ")
    axes[2, 0].plot(hours, [row["average_phase_transform_affinity"] for row in accepted], "o-", label="affinity")
    axes[2, 0].set(title="nonequilibrium state averages", xlabel="time [h]")
    axes[2, 0].legend()
    axes[2, 1].plot(hours, [row["average_fluid_temperature"] for row in accepted], "o-", label="fluid T")
    axes[2, 1].plot(hours, [row["average_solid_temperature"] for row in accepted], "o-", label="solid T")
    twin = axes[2, 1].twinx()
    twin.plot(hours, [row["minimum_solid_reference_jacobian"] for row in accepted], "s-", color="C3", label="minimum J")
    axes[2, 1].set(title="thermal and deformation admissibility", xlabel="time [h]", ylabel="temperature [K]")
    twin.set_ylabel("minimum J")
    lines = axes[2, 1].lines + twin.lines
    axes[2, 1].legend(lines, [line.get_label() for line in lines])
    for ax in axes.flat[:4]:
        ax.set_xlabel("time [h]")
    save(fig, args.output_dir, "spe1_all_gates_history")

    opm = read_rows(args.opm)
    final = accepted[-1]
    fig, axes = plt.subplots(1, 3, figsize=(13.5, 4.2))
    axes[0].plot([row["time_days"] for row in opm], [row["injector_bhp_psia"] for row in opm],
                 label="OPM injector BHP")
    axes[0].plot([row["time_days"] for row in opm], [row["producer_bhp_psia"] for row in opm],
                 label="OPM producer BHP")
    axes[0].scatter([1], [final["injector_bhp"] * PSI_PER_PA], marker="^", label="CG/EG day-1 injector")
    axes[0].scatter([1], [final["producer_bhp"] * PSI_PER_PA], marker="v", label="CG/EG day-1 producer")
    axes[0].set(xlabel="time [day]", ylabel="BHP [psia]", title="pressure context")
    axes[0].legend(fontsize=8)
    target_gas = INJECTOR_TARGET_RATE = 32.774128
    target_oil = 0.03680261456666667
    gas_rate = final["injected_gas_surface_rate"]
    oil_rate = final["producer_oil_surface_rate"]
    axes[1].bar(["gas injection", "oil production"],
                [gas_rate / target_gas, oil_rate / target_oil])
    axes[1].axhline(1, color="black", linestyle="--")
    axes[1].set(ylabel="CG/EG / official target", title="day-1 control agreement")
    axes[2].plot([row["time_days"] for row in opm], [row["producer_cell_gas_saturation"] for row in opm],
                 label="OPM producer-cell gas saturation")
    axes[2].scatter([1], [final["maximum_gas_saturation"]], label="CG/EG domain maximum")
    axes[2].set(xlabel="time [day]", ylabel="gas saturation [-]", title="schedule context (not like-for-like)")
    axes[2].legend(fontsize=8)
    fig.suptitle("Pinned OPM schedule context; first comparable OPM row is day 31")
    save(fig, args.output_dir, "spe1_opm_reference_context")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
