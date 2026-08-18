#!/usr/bin/env python3
"""Generate SPE1 figures only after endpoint, runtime, and history acceptance pass."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


def load_json(path: Path) -> dict[str, object]:
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("artifact", type=Path)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument(
        "--opm",
        type=Path,
        default=Path("validation/reference_data/spe1_case1_opm_flow_2021_10.csv"),
    )
    args = parser.parse_args()

    summary = load_json(args.artifact / "verification_summary.json")
    provenance = load_json(args.artifact / "provenance.json")
    audit = load_json(args.artifact / "time_history_audit.json")
    failures = []
    if summary.get("status") != "pass":
        failures.append("endpoint verification")
    if provenance.get("runtime_unchanged_during_run") is not True:
        failures.append("runtime provenance")
    if provenance.get("development_tree_unchanged_during_run") is not True:
        failures.append("development-tree provenance")
    if audit.get("status") != "pass":
        failures.append("all-timestep audit")
    if failures:
        raise SystemExit("cannot plot unaccepted artifact; failed: " + ", ".join(failures))

    plotter = Path(__file__).with_name("plot_spe1_all_gates_report.py")
    command = [
        sys.executable,
        str(plotter),
        str(args.artifact),
        "--output-dir",
        str(args.output_dir),
        "--opm",
        str(args.opm),
        "--allow-incomplete",
    ]
    completed = subprocess.run(command, check=False)
    if completed.returncode != 0:
        return completed.returncode
    print("pass: figures generated from endpoint-, provenance-, and history-accepted artifact")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
