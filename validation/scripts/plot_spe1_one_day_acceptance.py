#!/usr/bin/env python3
"""Plot the provenance-locked SPE1 one-day coupled-acceptance artifact.

The accepted artifact writes scalar history only.  These figures intentionally
do not fabricate spatial fields or claim a like-for-like OPM comparison.
"""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path

import matplotlib.pyplot as plt


SECONDS_PER_HOUR = 3600.0
PSI_PER_PA = 1.0 / 6894.757293168


def rows(path: Path) -> list[dict[str, float]]:
    with path.open(newline="", encoding="utf-8") as stream:
        return [{key: float(value) for key, value in row.items()} for row in csv.DictReader(stream)]


def save(figure: plt.Figure, output_dir: Path, stem: str) -> None:
    figure.savefig(output_dir / f"{stem}.svg", bbox_inches="tight")
    figure.savefig(output_dir / f"{stem}.png", dpi=190, bbox_inches="tight")
    figure.savefig(output_dir / f"{stem}.pgf", bbox_inches="tight")
    plt.close(figure)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("artifact", type=Path)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--opm", type=Path,
                        default=Path("validation/reference_data/spe1_case1_opm_flow_2021_10.csv"))
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    summary = json.loads((args.artifact / "verification_summary.json").read_text(encoding="utf-8"))
    provenance = json.loads((args.artifact / "provenance.json").read_text(encoding="utf-8"))
    if summary.get("status") != "pass" or provenance.get("unchanged_during_run") is not True:
        raise SystemExit("artifact is not a provenance-locked passing acceptance run")

    history = [row for row in rows(args.artifact / "result.csv") if row["time"] > 0]
    hours = [row["time"] / SECONDS_PER_HOUR for row in history]
    plt.style.use("seaborn-v0_8-whitegrid")

    figure, axes = plt.subplots(2, 2, figsize=(11.5, 7.8))
    axes[0, 0].plot(hours, [row["average_gas_saturation"] for row in history], "o-", label="domain average")
    axes[0, 0].plot(hours, [row["maximum_gas_saturation"] for row in history], "o-", label="domain maximum")
    axes[0, 0].set(title="Gas-phase appearance", xlabel="time [h]", ylabel="gas saturation [-]")
    axes[0, 0].legend()
    for field, label in (("water_global_balance", "water"), ("oil_global_balance", "oil"),
                         ("gas_global_balance", "gas")):
        axes[0, 1].semilogy(hours, [max(abs(row[field]), 1.0e-18) for row in history], "o-", label=label)
    axes[0, 1].axhline(1.0e-6, color="black", linestyle="--", label="balance gate")
    axes[0, 1].set(title="Component-balance defects", xlabel="time [h]", ylabel="absolute defect [kg/s]")
    axes[0, 1].legend()
    for field, limit, label in (("gas_appearance_equilibrium_residual_l2", 1.0e-7, "gas appearance"),
                                ("tau_evolution_residual_l2", 1.0e-7, "transfer coordinate"),
                                ("matrix_momentum_z_scaled_weak_residual_linf", 1.0e-7, "momentum"),
                                ("fluid_energy_scaled_weak_residual_linf", 1.0e-7, "fluid energy"),
                                ("solid_energy_scaled_weak_residual_linf", 1.0e-7, "solid energy")):
        axes[1, 0].semilogy(hours, [max(abs(row[field]) / limit, 1.0e-16) for row in history], "o-", label=label)
    axes[1, 0].axhline(1.0, color="black", linestyle="--", label="acceptance limit")
    axes[1, 0].set(title="Physical residuals normalized by their gates", xlabel="time [h]", ylabel="residual / limit")
    axes[1, 0].legend(fontsize=8)
    axes[1, 1].plot(hours, [row["injected_gas_surface_rate"] for row in history], "o-", label="gas injection")
    axes[1, 1].plot(hours, [row["producer_oil_surface_rate"] for row in history], "o-", label="oil production")
    axes[1, 1].set(title="Active-well controls", xlabel="time [h]", ylabel="surface rate [m³/s]")
    axes[1, 1].legend()
    figure.suptitle("SPE1 Case 1: one-day coupled CG/EG acceptance history")
    save(figure, args.output_dir, "spe1_one_day_acceptance_history")

    opm = rows(args.opm)
    final = history[-1]
    figure, axes = plt.subplots(1, 2, figsize=(11.5, 4.3))
    axes[0].plot([row["time_days"] for row in opm], [row["injector_bhp_psia"] for row in opm], label="OPM injector BHP")
    axes[0].plot([row["time_days"] for row in opm], [row["producer_bhp_psia"] for row in opm], label="OPM producer BHP")
    axes[0].scatter([1.0], [final["injector_bhp"] * PSI_PER_PA], marker="^", label="CG/EG day 1 injector")
    axes[0].scatter([1.0], [final["producer_bhp"] * PSI_PER_PA], marker="v", label="CG/EG day 1 producer")
    axes[0].set(title="Pressure schedule context", xlabel="time [day]", ylabel="BHP [psia]")
    axes[0].legend(fontsize=8)
    axes[1].bar(["gas injection", "oil production"],
                [final["injected_gas_surface_rate"] / 32.774128,
                 final["producer_oil_surface_rate"] / 0.03680261456666667])
    axes[1].axhline(1.0, color="black", linestyle="--", label="specified control")
    axes[1].set(title="Day-1 control agreement", ylabel="CG/EG / specified rate")
    axes[1].legend()
    figure.suptitle("SPE1 reference context only: the first like-for-like OPM report is day 31")
    save(figure, args.output_dir, "spe1_one_day_opm_context")
    print("pass: generated one-day acceptance figures")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
