#!/usr/bin/env python3
"""Plot numerical and analytical pressure profiles for the Mandel problem."""

from __future__ import annotations

import argparse
import csv
import importlib.util
import json
import math
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.lines import Line2D


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_ACCEPTED_ARTIFACT = (
    ROOT / "validation/results/mandel_implicit_biot/accepted_20260821"
)
DEFAULT_PROFILES = (
    ROOT
    / "validation/results/mandel_implicit_biot/profile_20260821/pressure_profiles.csv"
)
DEFAULT_OUTPUT = (
    ROOT
    / "validation/reports/figures/mandel_implicit_biot/accepted_20260821/mandel_pressure_profiles.svg"
)
DEFAULT_PGF_OUTPUT = DEFAULT_OUTPUT.with_suffix(".pgf")
DEFAULT_DOCS_OUTPUT = (
    ROOT / "docs/assets/mandel_implicit_biot/mandel_pressure_profiles.svg"
)


def load_verifier():
    path = ROOT / "validation/scripts/check_mandel_implicit_biot.py"
    spec = importlib.util.spec_from_file_location("mandel_verifier", path)
    if spec is None or spec.loader is None:
        raise SystemExit(f"cannot import Mandel verifier: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def decode_exodus_names(values) -> list[str]:
    names = []
    for row in values:
        if row.dtype.kind in "ui":
            names.append("".join(chr(value) for value in row if value).strip())
        else:
            names.append(b"".join(row).decode().strip("\x00 "))
    return names


def extract_profiles(
    exodus: Path, output: Path, ordinate: float, selected_times: tuple[float, ...]
) -> None:
    try:
        from netCDF4 import Dataset
    except ImportError as error:
        raise SystemExit("Exodus extraction requires the MOOSE Python environment") from error

    rows: list[dict[str, float]] = []
    with Dataset(exodus) as dataset:
        times = dataset.variables["time_whole"][:]
        x_coordinates = dataset.variables["coordx"][:]
        y_coordinates = dataset.variables["coordy"][:]
        variable_names = decode_exodus_names(dataset.variables["name_nod_var"][:])
        try:
            pressure_index = variable_names.index("p") + 1
        except ValueError as error:
            raise SystemExit(f"pressure variable p is absent from {exodus}") from error
        pressure_values = dataset.variables[f"vals_nod_var{pressure_index}"][:]

        line_nodes = sorted(
            (
                (float(x_coordinates[index]), index)
                for index in range(len(x_coordinates))
                if math.isclose(
                    float(y_coordinates[index]), ordinate, rel_tol=0.0, abs_tol=1.0e-12
                )
            ),
            key=lambda pair: pair[0],
        )
        if not line_nodes:
            raise SystemExit(f"no Exodus nodes found on y={ordinate:g}")

        selected_indices = [
            (time_index, float(time))
            for time_index, time in enumerate(times)
            if any(
                math.isclose(float(time), selected, rel_tol=0.0, abs_tol=1.0e-10)
                for selected in selected_times
            )
        ]
        if len(selected_indices) != len(selected_times):
            available = ", ".join(f"{float(time):g}" for time in times)
            raise SystemExit(
                f"requested times {selected_times} are not all present; available times: {available}"
            )

        for time_index, time in selected_indices:
            for x_coordinate, node_index in line_nodes:
                rows.append(
                    {
                        "time": float(time),
                        "x": x_coordinate,
                        "y": ordinate,
                        "pressure": float(pressure_values[time_index, node_index]),
                    }
                )

    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=("time", "x", "y", "pressure"))
        writer.writeheader()
        writer.writerows(rows)


def read_profiles(path: Path) -> dict[float, list[dict[str, float]]]:
    profiles: dict[float, list[dict[str, float]]] = {}
    with path.open(newline="", encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            values = {name: float(value) for name, value in row.items()}
            profiles.setdefault(values["time"], []).append(values)
    for rows in profiles.values():
        rows.sort(key=lambda row: row["x"])
    if not profiles:
        raise SystemExit(f"no pressure profiles found in {path}")
    return profiles


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--accepted-artifact", type=Path, default=DEFAULT_ACCEPTED_ARTIFACT)
    parser.add_argument("--profiles", type=Path, default=DEFAULT_PROFILES)
    parser.add_argument("--exodus", type=Path)
    parser.add_argument("--ordinate", type=float, default=0.05)
    parser.add_argument("--times", default="0.014,0.05,0.1,0.2,0.4")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--pgf-output", type=Path, default=DEFAULT_PGF_OUTPUT)
    parser.add_argument("--docs-output", type=Path, default=DEFAULT_DOCS_OUTPUT)
    args = parser.parse_args()

    summary_path = args.accepted_artifact / "verification_summary.json"
    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    if not summary.get("accepted") or not all(summary.get("gates", {}).values()):
        raise SystemExit(f"refusing to plot against an unaccepted artifact: {summary_path}")

    if args.exodus:
        selected_times = tuple(float(value) for value in args.times.split(","))
        extract_profiles(args.exodus, args.profiles, args.ordinate, selected_times)
    profiles = read_profiles(args.profiles)
    verifier = load_verifier()

    figure, axis = plt.subplots(figsize=(7.4, 4.8), constrained_layout=True)
    colors = plt.get_cmap("viridis")(
        [index / max(len(profiles) - 1, 1) for index in range(len(profiles))]
    )
    analytical_x = [index / 400.0 for index in range(401)]

    for color, (time, numerical_rows) in zip(colors, sorted(profiles.items())):
        axis.plot(
            analytical_x,
            [verifier.analytical_solution(time, x)[0] / 1000.0 for x in analytical_x],
            color=color,
            linewidth=1.8,
            label=fr"$t={time:g}$ s",
        )
        marker_stride = max(len(numerical_rows) // 20, 1)
        sampled_rows = numerical_rows[::marker_stride]
        if sampled_rows[-1] is not numerical_rows[-1]:
            sampled_rows.append(numerical_rows[-1])
        axis.plot(
            [row["x"] for row in sampled_rows],
            [row["pressure"] / 1000.0 for row in sampled_rows],
            linestyle="none",
            marker="o",
            markersize=3.8,
            markerfacecolor="white",
            markeredgecolor=color,
            markeredgewidth=0.9,
        )

    time_legend = axis.legend(
        title="Profile time", loc="lower left", fontsize=8, title_fontsize=9, ncol=2
    )
    axis.add_artist(time_legend)
    axis.legend(
        handles=(
            Line2D([0], [0], color="0.2", linewidth=1.8, label="analytical series"),
            Line2D(
                [0],
                [0],
                color="0.2",
                linestyle="none",
                marker="o",
                markerfacecolor="white",
                markersize=4,
                label="Q2/Q1 finite element",
            ),
        ),
        loc="upper right",
        fontsize=8,
    )
    axis.set_xlabel(r"distance from the undrained center, $x$ [m]")
    axis.set_ylabel(r"water pressure, $p$ [kPa]")
    axis.set_xlim(0.0, 1.0)
    axis.set_ylim(bottom=0.0)
    axis.grid(alpha=0.22)

    for output in (args.output, args.pgf_output, args.docs_output):
        output.parent.mkdir(parents=True, exist_ok=True)
        save_options = (
            {} if output.suffix == ".pgf"
            else {"metadata": {"Creator": "plot_mandel_implicit_biot.py"}}
        )
        figure.savefig(output, **save_options)
        print(output)
    plt.close(figure)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
