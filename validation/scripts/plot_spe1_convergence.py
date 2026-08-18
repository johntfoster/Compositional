#!/usr/bin/env python3
"""Summarize and plot the provenance-preserved SPE1 convergence study."""

from __future__ import annotations

import csv
import json
import math
from pathlib import Path

import matplotlib.pyplot as plt


ROOT = Path(__file__).resolve().parents[2]
RESULTS = ROOT / "validation/results/spe1_case1"
FIGURES = ROOT / "validation/reports/figures/spe1_case1"
OUTPUT = RESULTS / "convergence_summary_v1.json"

SPATIAL = (
    (1, 18, RESULTS / "reduced_active_full_thermo_momentum_energy_dt3h_v2"),
    (2, 72, RESULTS / "spatial_n2_active_full_thermo_dt3h_v1"),
    (4, 288, RESULTS / "spatial_n4_active_full_thermo_dt3h_v1"),
    (8, 1152, RESULTS / "spatial_n8_active_full_thermo_dt3h_v1"),
    (10, 1800, RESULTS / "full_active_full_thermo_momentum_energy_dt3h_v4"),
)
TEMPORAL = (
    (10800.0, RESULTS / "spatial_n4_active_full_thermo_dt3h_v1"),
    (5400.0, RESULTS / "time_n4_active_full_thermo_dt1p5h_v1"),
    (2700.0, RESULTS / "time_n4_active_full_thermo_dt0p75h_v2"),
)
ROBUSTNESS = (21600.0, RESULTS / "time_n4_active_full_thermo_dt6h_v1")

ABSOLUTE_LIMITS = {
    "tau_evolution_residual_l2": 1.0e-7,
    "phase_transform_kinetic_residual_l2": 1.0e-7,
    "gas_global_balance": 1.0e-6,
    "matrix_momentum_z_scaled_weak_residual_linf": 1.0e-7,
    "fluid_energy_scaled_weak_residual_linf": 1.0e-7,
}
OBSERVABLES = {
    "average oil pressure": "average_oil_pressure",
    "maximum gas saturation": "maximum_gas_saturation",
    "average gas saturation": "average_gas_saturation",
    "injector BHP": "injector_bhp",
    "producer BHP": "producer_bhp",
    "injected gas volume": "injected_gas_surface_volume",
    "produced gas volume": "produced_gas_surface_volume",
}


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def load_artifact(path: Path) -> dict:
    summary = load_json(path / "verification_summary.json")
    provenance = load_json(path / "provenance.json")
    history = load_json(path / "history_audit.json")
    if provenance.get("unchanged_during_run") is not True:
        raise SystemExit(f"provenance changed during run: {path}")
    if summary.get("provenance") != provenance.get("before"):
        raise SystemExit(f"summary/provenance mismatch: {path}")
    if history.get("accepted_nonzero_timesteps", 0) < 1:
        raise SystemExit(f"history audit has no accepted steps: {path}")
    return {"path": str(path.relative_to(ROOT)), "summary": summary, "history": history}


def history_maximum(artifact: dict, metric: str) -> float:
    return artifact["history"]["extrema"][metric]["maximum_absolute"]


def relative_error(value: float, reference: float) -> float:
    return abs(value - reference) / max(abs(reference), 1.0e-30)


def save(fig: plt.Figure, stem: str) -> None:
    FIGURES.mkdir(parents=True, exist_ok=True)
    fig.tight_layout()
    fig.savefig(FIGURES / f"{stem}.svg", bbox_inches="tight")
    fig.savefig(FIGURES / f"{stem}.png", dpi=180, bbox_inches="tight")
    plt.close(fig)


def write_csv(path: Path, rows: list[dict]) -> None:
    with path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    spatial = [(n, elements, load_artifact(path)) for n, elements, path in SPATIAL]
    temporal = [(dt, load_artifact(path)) for dt, path in TEMPORAL]
    robustness = load_artifact(ROBUSTNESS[1])
    reference = spatial[-1][2]["summary"]["final"]

    spatial_rows = []
    for n, elements, artifact in spatial:
        final = artifact["summary"]["final"]
        row = {
            "lateral_cells": n,
            "tet10_elements": elements,
            "status": artifact["summary"]["status"],
            "history_status": artifact["history"]["status"],
            "maximum_tau_gate_fraction": history_maximum(
                artifact, "tau_evolution_residual_l2"
            )
            / ABSOLUTE_LIMITS["tau_evolution_residual_l2"],
        }
        for label, field in OBSERVABLES.items():
            row[field] = final[field]
            row[f"{field}_relative_to_n10"] = relative_error(final[field], reference[field])
        spatial_rows.append(row)

    temporal_rows = []
    for dt, artifact in temporal:
        final = artifact["summary"]["final"]
        row = {
            "dt_seconds": dt,
            "accepted_timesteps": artifact["history"]["accepted_nonzero_timesteps"],
            "status": artifact["summary"]["status"],
            "history_status": artifact["history"]["status"],
        }
        for _, field in OBSERVABLES.items():
            row[field] = final[field]
        temporal_rows.append(row)

    spatial_orders = {}
    n4 = spatial[2][2]["summary"]["final"]
    n8 = spatial[3][2]["summary"]["final"]
    for label, field in OBSERVABLES.items():
        error4 = abs(n4[field] - reference[field])
        error8 = abs(n8[field] - reference[field])
        spatial_orders[label] = (
            math.log(error4 / error8, 2.0) if error4 > 0.0 and error8 > 0.0 else None
        )

    temporal_orders = {}
    coarse = temporal[0][1]["summary"]["final"]
    medium = temporal[1][1]["summary"]["final"]
    fine = temporal[2][1]["summary"]["final"]
    for label, field in OBSERVABLES.items():
        first_difference = abs(coarse[field] - medium[field])
        second_difference = abs(medium[field] - fine[field])
        temporal_orders[label] = (
            math.log(first_difference / second_difference, 2.0)
            if first_difference > 0.0 and second_difference > 0.0
            else None
        )

    robustness_events = {
        "nominal_dt_seconds": ROBUSTNESS[0],
        "accepted_timesteps": robustness["history"]["accepted_nonzero_timesteps"],
        "rejected_or_nonconverged_step_count": (
            robustness["summary"].get("solver_events", {}).get(
                "rejected_or_nonconverged_step_count", 1
            )
        ),
        "classification": "failed_uniform_step_robustness_cutback_to_10800_seconds",
        "path": robustness["path"],
    }
    document = {
        "benchmark": "SPE1 Case 1",
        "spatial_reference": "10x10x3 physical cells mapped to 1800 TET10 elements",
        "spatial": spatial_rows,
        "spatial_apparent_orders_n4_n8_against_n10": spatial_orders,
        "temporal": temporal_rows,
        "temporal_observed_orders_backward_euler": temporal_orders,
        "timestep_robustness": robustness_events,
    }
    OUTPUT.write_text(json.dumps(document, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    write_csv(RESULTS / "spe1_spatial_convergence_v1.csv", spatial_rows)
    write_csv(RESULTS / "spe1_temporal_convergence_v1.csv", temporal_rows)

    plt.style.use("seaborn-v0_8-whitegrid")
    fig, axes = plt.subplots(2, 2, figsize=(11.5, 8.0))
    ax = axes[0, 0]
    for label, field in OBSERVABLES.items():
        if label not in (
            "average oil pressure",
            "maximum gas saturation",
            "injector BHP",
            "produced gas volume",
        ):
            continue
        ax.loglog(
            [row["tet10_elements"] for row in spatial_rows[:-1]],
            [max(row[f"{field}_relative_to_n10"], 1.0e-12) for row in spatial_rows[:-1]],
            marker="o",
            label=label,
        )
    ax.set(
        xlabel="TET10 elements",
        ylabel="relative endpoint difference from n=10",
        title="Spatial observable refinement",
    )
    ax.legend(fontsize=8)

    ax = axes[0, 1]
    for metric, limit in ABSOLUTE_LIMITS.items():
        ax.loglog(
            [elements for _, elements, _ in spatial],
            [max(history_maximum(artifact, metric) / limit, 1.0e-14) for _, _, artifact in spatial],
            marker="o",
            label=metric.replace("_", " "),
        )
    ax.axhline(1.0, color="black", linestyle="--", label="gate")
    ax.set(
        xlabel="TET10 elements",
        ylabel="largest history residual / gate",
        title="Spatial gate margins",
    )
    ax.legend(fontsize=7)

    ax = axes[1, 0]
    fine_final = temporal[-1][1]["summary"]["final"]
    for label, field in OBSERVABLES.items():
        if label not in (
            "average oil pressure",
            "maximum gas saturation",
            "injector BHP",
            "produced gas volume",
        ):
            continue
        ax.loglog(
            [dt / 3600.0 for dt, _ in temporal[:-1]],
            [
                max(relative_error(artifact["summary"]["final"][field], fine_final[field]), 1.0e-12)
                for _, artifact in temporal[:-1]
            ],
            marker="o",
            label=label,
        )
    ax.invert_xaxis()
    ax.set(
        xlabel="nominal timestep [h]",
        ylabel="relative endpoint difference from 0.75 h",
        title="Backward-Euler timestep refinement",
    )
    ax.legend(fontsize=8)

    ax = axes[1, 1]
    labels = ["6 h", "3 h", "1.5 h", "0.75 h"]
    rejected = [1, 0, 0, 0]
    colors = ["C3" if value else "C2" for value in rejected]
    ax.bar(labels, [1 if value else 0 for value in rejected], color=colors)
    ax.set_ylim(0.0, 1.2)
    ax.set_ylabel("rejected/nonconverged step observed")
    ax.set_title("Timestep robustness")
    ax.text(0, 1.03, "cut back to 3 h", ha="center", va="bottom", fontsize=9)
    save(fig, "spe1_spatial_temporal_convergence")
    print(f"wrote {OUTPUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
