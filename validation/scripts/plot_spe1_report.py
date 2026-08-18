#!/usr/bin/env python3
"""Generate reproducible SPE1 acceptance and reference-context figures."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path

import matplotlib.pyplot as plt


SECONDS_PER_DAY = 86400.0
M3_PER_STB = 0.158987294928
SCF_PER_SM3 = 35.3146667215
PA_PER_PSI = 6894.757293168
TARGET_GAS_M3_S = 32.774128
TARGET_OIL_M3_S = 0.03680261456666667
EXPECTED_END_TIME = 86400.0


def read_csv(path: Path) -> list[dict[str, float]]:
    with path.open(newline="", encoding="utf-8") as stream:
        return [
            {key: float(value) for key, value in row.items()}
            for row in csv.DictReader(stream)
        ]


def values(rows: list[dict[str, float]], name: str) -> list[float]:
    return [row[name] for row in rows]


def validate_artifact(csv_path: Path, rows: list[dict[str, float]]) -> None:
    summary_path = csv_path.parent / "verification_summary.json"
    provenance_path = csv_path.parent / "provenance.json"
    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    provenance = json.loads(provenance_path.read_text(encoding="utf-8"))
    if summary.get("status") != "pass":
        raise SystemExit(f"artifact is not accepted: {summary_path}")
    if provenance.get("unchanged_during_run") is not True:
        raise SystemExit(f"artifact changed during execution: {provenance_path}")
    if summary.get("provenance") != provenance.get("before"):
        raise SystemExit(f"summary/provenance mismatch: {csv_path.parent}")
    if not rows or abs(rows[-1]["time"] - EXPECTED_END_TIME) > 1.0e-8:
        raise SystemExit(f"artifact does not reach one day: {csv_path}")
    if abs(summary["final"]["time"] - rows[-1]["time"]) > 1.0e-8:
        raise SystemExit(f"summary/CSV final-time mismatch: {csv_path.parent}")


def save(fig: plt.Figure, output_dir: Path, stem: str) -> None:
    fig.tight_layout()
    fig.savefig(output_dir / f"{stem}.svg", bbox_inches="tight")
    fig.savefig(output_dir / f"{stem}.png", dpi=180, bbox_inches="tight")
    plt.close(fig)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--full", required=True, type=Path)
    parser.add_argument("--reduced", required=True, type=Path)
    parser.add_argument("--opm", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    full = read_csv(args.full)
    reduced = read_csv(args.reduced)
    validate_artifact(args.full, full)
    validate_artifact(args.reduced, reduced)
    opm = read_csv(args.opm)
    hours = [row["time"] / 3600.0 for row in full]
    accepted_full = [row for row in full if row["time"] > 0.0]
    accepted_hours = [row["time"] / 3600.0 for row in accepted_full]

    plt.style.use("seaborn-v0_8-whitegrid")
    fig, axes = plt.subplots(2, 2, figsize=(11, 7.5))
    ax = axes[0, 0]
    for field, label in (
        ("minimum_gas_saturation", "minimum"),
        ("average_gas_saturation", "average"),
        ("maximum_gas_saturation", "maximum"),
    ):
        ax.plot(hours, values(full, field), marker="o", label=label)
    ax.set(xlabel="time [h]", ylabel="gas saturation [-]", title="Gas-phase appearance")
    ax.legend()

    ax = axes[0, 1]
    ax.plot(
        accepted_hours,
        [1e6 * (abs(value) / TARGET_GAS_M3_S - 1.0) for value in values(accepted_full, "injected_gas_surface_rate")],
        marker="o",
        label="gas injection",
    )
    ax.plot(
        accepted_hours,
        [1e6 * (abs(value) / TARGET_OIL_M3_S - 1.0) for value in values(accepted_full, "producer_oil_surface_rate")],
        marker="s",
        label="oil production",
    )
    ax.axhline(0.0, color="black", linewidth=1, linestyle="--")
    ax.set(xlabel="time [h]", ylabel="relative target error [ppm]", title="Active well-control errors")
    ax.legend()

    ax = axes[1, 0]
    ax.plot(accepted_hours, [value / 1e6 for value in values(accepted_full, "injector_bhp")], marker="o", label="injector")
    ax.plot(accepted_hours, [value / 1e6 for value in values(accepted_full, "producer_bhp")], marker="s", label="producer")
    ax.axhline(62.14934224061635, color="C0", linestyle="--", label="injector max")
    ax.axhline(6.894757293168, color="C1", linestyle="--", label="producer min")
    ax.set(xlabel="time [h]", ylabel="BHP [MPa]", title="Well-pressure limits")
    ax.legend(ncol=2)

    ax = axes[1, 1]
    ax.plot(hours, values(full, "average_tau"), marker="o", color="C4", label="average tau")
    ax.set(xlabel="time [h]", ylabel="average tau [model units]", title="Nonequilibrium internal field")
    rate_ax = ax.twinx()
    rate_ax.plot(
        hours,
        values(full, "average_gas_phase_transformation_rate"),
        marker="s",
        color="C3",
        label="average transformation rate",
    )
    rate_ax.set_ylabel("average transformation rate [model units]")
    lines = ax.get_lines() + rate_ax.get_lines()
    ax.legend(lines, [line.get_label() for line in lines], loc="best")
    save(fig, args.output_dir, "spe1_active_solution")

    fig, axes = plt.subplots(2, 2, figsize=(11, 7.5))
    ax = axes[0, 0]
    for component in ("water", "oil", "gas"):
        defect = [max(abs(value), 1e-18) for value in values(full, f"{component}_global_balance")]
        ax.semilogy(hours, defect, marker="o", label=component)
    ax.axhline(1e-6, color="black", linestyle="--", label="gate")
    ax.set(xlabel="time [h]", ylabel="absolute defect [kg/s]", title="Global component conservation")
    ax.legend()

    ax = axes[0, 1]
    for field, label, limit in (
        ("phase_volume_constraint_l2", "phase-volume L2", 1e-8),
        ("matrix_component_balance_l2", "matrix-component L2", 1e-6),
        ("phase_transform_kinetic_residual_l2", "kinetic L2", 1e-7),
    ):
        ax.semilogy(
            hours,
            [max(abs(value) / limit, 1e-12) for value in values(full, field)],
            marker="o",
            label=label,
        )
    ax.axhline(1.0, color="black", linestyle="--", label="individual gate")
    ax.set(xlabel="time [h]", ylabel="absolute residual / gate", title="Normalized residual histories")
    ax.legend()

    ax = axes[1, 0]
    ax.plot(accepted_hours, [value - 333.15 for value in values(accepted_full, "average_fluid_temperature")], marker="o", label="fluid")
    ax.plot(accepted_hours, [value - 333.15 for value in values(accepted_full, "average_solid_temperature")], marker="s", label="solid")
    ax.set(xlabel="time [h]", ylabel="temperature change [K]", title="Adiabatic two-temperature check")
    ax.legend()

    ax = axes[1, 1]
    ax.plot(accepted_hours, values(accepted_full, "minimum_solid_reference_jacobian"), marker="o", label="minimum J")
    ax.plot(accepted_hours, values(accepted_full, "minimum_gas_saturation"), marker="s", label="minimum gas saturation")
    ax.plot(accepted_hours, values(accepted_full, "minimum_phase_transform_dissipation"), marker="^", label="minimum dissipation")
    ax.axhline(0.0, color="black", linewidth=1)
    ax.set(xlabel="time [h]", title="Admissibility and thermodynamic signs")
    ax.legend()
    save(fig, args.output_dir, "spe1_verification_gates")

    fig, axes = plt.subplots(2, 2, figsize=(11, 7.5))
    ax = axes[0, 0]
    for field, label, limit in (
        ("tau_evolution_residual_l2", "tau evolution", 1e-7),
        ("phase_transform_kinetic_residual_l2", "finite-rate kinetic law", 1e-7),
    ):
        ax.semilogy(
            hours,
            [max(abs(value) / limit, 1e-14) for value in values(full, field)],
            marker="o",
            label=label,
        )
    ax.axhline(1.0, color="black", linestyle="--", label="gate")
    ax.set(xlabel="time [h]", ylabel="absolute residual / gate", title="Nonequilibrium evolution laws")
    ax.legend()

    ax = axes[0, 1]
    for field, label in (
        ("phase_transform_affinity_identity_l2", "affinity from chemical potentials"),
        ("phase_transform_generalized_force_identity_l2", "tau-corrected force"),
        ("phase_transform_power_identity_l2", "force-rate power"),
    ):
        ax.semilogy(
            hours,
            [max(abs(value) / 1e-12, 1e-14) for value in values(full, field)],
            marker="o",
            label=label,
        )
    ax.axhline(1.0, color="black", linestyle="--", label="gate")
    ax.set(xlabel="time [h]", ylabel="identity defect / gate", title="Chemical-potential identities")
    ax.legend(fontsize=8)

    ax = axes[1, 0]
    for component in ("x", "y", "z"):
        field = f"matrix_momentum_{component}_scaled_weak_residual_linf"
        ax.semilogy(
            hours,
            [max(abs(value) / 1e-7, 1e-14) for value in values(full, field)],
            marker="o",
            label=component,
        )
    ax.axhline(1.0, color="black", linestyle="--", label="gate")
    ax.set(xlabel="time [h]", ylabel="scaled weak residual / gate", title="Overall momentum balance")
    ax.legend()

    ax = axes[1, 1]
    for field, label in (
        ("fluid_energy_scaled_weak_residual_linf", "fluid energy"),
        ("solid_energy_scaled_weak_residual_linf", "solid energy"),
    ):
        ax.semilogy(
            hours,
            [max(abs(value) / 1e-7, 1e-14) for value in values(full, field)],
            marker="o",
            label=label,
        )
    ax.axhline(1.0, color="black", linestyle="--", label="gate")
    ax.set(xlabel="time [h]", ylabel="scaled weak residual / gate", title="Two-temperature energy balances")
    ax.legend()
    save(fig, args.output_dir, "spe1_thermodynamic_coupling_gates")

    final_full = full[-1]
    final_reduced = reduced[-1]
    metrics = (
        ("kinetic", "phase_transform_kinetic_residual_l2", 1e-7),
        ("gas balance", "gas_global_balance", 1e-6),
        ("matrix balance", "matrix_component_balance_l2", 1e-6),
        ("phase volume", "phase_volume_constraint_l2", 1e-8),
    )
    fig, ax = plt.subplots(figsize=(9, 4.8))
    x = list(range(len(metrics)))
    width = 0.36
    ax.bar(
        [value - width / 2 for value in x],
        [abs(final_full[field]) / limit for _, field, limit in metrics],
        width,
        label="full 1800-element",
    )
    ax.bar(
        [value + width / 2 for value in x],
        [abs(final_reduced[field]) / limit for _, field, limit in metrics],
        width,
        label="reduced 18-element",
    )
    ax.axhline(1.0, color="black", linestyle="--", label="acceptance limit")
    ax.set_xticks(x, [name for name, _, _ in metrics])
    ax.set_yscale("log")
    ax.set_ylabel("absolute metric / acceptance limit")
    ax.set_title("Independent full/reduced endpoint margins")
    ax.legend()
    save(fig, args.output_dir, "spe1_full_reduced_gate_comparison")

    days = values(opm, "time_days")
    fig, axes = plt.subplots(1, 2, figsize=(11, 4.5))
    ax = axes[0]
    ax.plot(days, values(opm, "injector_gas_rate_mscf_per_day"), label="OPM gas injection")
    ax.plot(days, values(opm, "producer_oil_rate_stb_per_day"), label="OPM oil production")
    moose_gas = abs(final_full["injected_gas_surface_rate"]) * SECONDS_PER_DAY * SCF_PER_SM3 / 1000.0
    moose_oil = abs(final_full["producer_oil_surface_rate"]) * SECONDS_PER_DAY / M3_PER_STB
    ax.scatter([1.0], [moose_gas], marker="o", s=55, label="MOOSE day-1 gas")
    ax.scatter([1.0], [moose_oil], marker="s", s=55, label="MOOSE day-1 oil")
    ax.set(xlabel="time [day]", ylabel="surface rate [Mscf/day or stb/day]", title="Official schedule context")
    ax.legend(fontsize=8)

    ax = axes[1]
    ax.plot(days, values(opm, "injector_bhp_psia"), label="OPM injector BHP")
    ax.plot(days, values(opm, "producer_bhp_psia"), label="OPM producer BHP")
    ax.scatter([1.0], [final_full["injector_bhp"] / PA_PER_PSI], marker="o", s=55, label="MOOSE day-1 injector")
    ax.scatter([1.0], [final_full["producer_bhp"] / PA_PER_PSI], marker="s", s=55, label="MOOSE day-1 producer")
    ax.set(xlabel="time [day]", ylabel="BHP [psia]", title="Pressure-control context")
    ax.legend(fontsize=8)
    save(fig, args.output_dir, "spe1_opm_reference_context")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
