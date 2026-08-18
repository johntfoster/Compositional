#!/usr/bin/env python3
"""Verify that an active-well SPE1 production checkpoint restores exactly."""

from __future__ import annotations

import argparse
import json
import math
import shlex
import subprocess
import sys
from pathlib import Path

from run_spe1_phase_transforming_acceptance import (
    ACTIVE_WELL_RESTART_POSTPROCESSORS,
    PRODUCTION_MAX_ITS,
    RESTART_INACTIVE_ICS,
    RESTART_INTEGRITY_POSTPROCESSORS,
    SCALAR_WELL_INITIAL_CONDITIONS,
    compare_restart_rows,
    initial_execution_overrides,
    parse_solver_events,
    read_rows,
    row_at_time,
)


PRODUCTION_CONTROL_POSTPROCESSORS = (
    "injector_bhp",
    "producer_bhp",
    "injected_gas_surface_rate",
    "producer_oil_surface_rate",
)
PRODUCTION_RESTART_METRICS = tuple(
    dict.fromkeys(RESTART_INTEGRITY_POSTPROCESSORS + PRODUCTION_CONTROL_POSTPROCESSORS)
)


def write_json(path: Path, value: object) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    temporary.replace(path)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("checkpoint_base", type=Path)
    parser.add_argument("reference_csv", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("--start-time-seconds", type=float, required=True)
    parser.add_argument("--end-time-seconds", type=float)
    parser.add_argument("--official-dtmax-seconds", type=float)
    parser.add_argument("--fixed-dt-seconds", type=float)
    parser.add_argument(
        "--snes-type",
        choices=("vinewtonrsls", "vinewtonssls"),
        default="vinewtonrsls",
        help="Bound-aware PETSc Newton method used for the checkpoint continuation.",
    )
    parser.add_argument(
        "--line-search",
        choices=("bt", "basic", "l2", "cp"),
        help="Optional PETSc line-search override for a controlled nonlinear-method comparison.",
    )
    parser.add_argument(
        "--vi-monitor",
        action="store_true",
        help="Write PETSc variational-inequality active/inactive-set diagnostics to solver.log.",
    )
    parser.add_argument(
        "--saturation-simplex-damper",
        action="store_true",
        help=(
            "Run a nonacceptance candidate that uses the combined Bernstein-plus-P0 "
            "saturation simplex damper instead of the current transformed, VI-bounded "
            "reconstruction."
        ),
    )
    parser.add_argument("--write-checkpoint", action="store_true")
    parser.add_argument("--mpi-ranks", type=int, default=8)
    args = parser.parse_args()

    if args.mpi_ranks < 1:
        parser.error("--mpi-ranks must be positive")
    if args.end_time_seconds is not None and args.end_time_seconds < args.start_time_seconds:
        parser.error("--end-time-seconds must be at least --start-time-seconds")
    if args.official_dtmax_seconds is not None and args.official_dtmax_seconds <= 0.0:
        parser.error("--official-dtmax-seconds must be positive")
    if args.fixed_dt_seconds is not None and args.fixed_dt_seconds <= 0.0:
        parser.error("--fixed-dt-seconds must be positive")
    if args.fixed_dt_seconds is not None and args.official_dtmax_seconds is not None:
        parser.error("--fixed-dt-seconds and --official-dtmax-seconds are exclusive")
    root = Path(__file__).resolve().parents[2]
    checkpoint_base = args.checkpoint_base.resolve()
    reference_csv = args.reference_csv.resolve()
    output_dir = args.output_dir.resolve()
    deck = root / "moose_app/examples/spe1_case1_q2_eg_phase_transforming_10_year_superlu.i"
    exe = root / "moose_app/multicomponent_reactive_flow-opt"
    if not checkpoint_base.parent.is_dir():
        parser.error(f"checkpoint parent does not exist: {checkpoint_base.parent}")
    if not reference_csv.is_file():
        parser.error(f"reference CSV does not exist: {reference_csv}")
    if not exe.is_file():
        parser.error(f"application executable does not exist: {exe}")

    reference_rows, _ = read_rows(reference_csv)
    reference = row_at_time(reference_rows, args.start_time_seconds)
    output_dir.mkdir(parents=True, exist_ok=True)
    output_base = output_dir / "restart_identity"
    end_time = args.start_time_seconds if args.end_time_seconds is None else args.end_time_seconds
    command = [
        "mpiexec",
        "-n",
        str(args.mpi_ranks),
        str(exe),
        "-i",
        str(deck),
        f"Outputs/file_base={output_base}",
        f"Outputs/checkpoint={'true' if args.write_checkpoint else 'false'}",
        "Outputs/csv=true",
        "Outputs/exodus=false",
        f"Executioner/start_time={args.start_time_seconds:.17g}",
        f"Executioner/end_time={end_time:.17g}",
        f"Executioner/nl_max_its={PRODUCTION_MAX_ITS}",
        f"Executioner/petsc_options_value={args.snes_type}",
        f"Problem/restart_file_base={checkpoint_base}",
        f"ICs/inactive={RESTART_INACTIVE_ICS} {SCALAR_WELL_INITIAL_CONDITIONS}",
        "Variables/inactive=",
        "Materials/inactive=",
        "Materials/inactive_well_sources/block=1 2 3",
        "ScalarKernels/active=injector_control producer_control",
        f"Postprocessors/active={ACTIVE_WELL_RESTART_POSTPROCESSORS}",
    ]
    actual_snes_type = args.snes_type
    if args.saturation_simplex_damper:
        # This controlled candidate keeps the physical reconstructed water and
        # gas saturations admissible coefficientwise, while permitting signed
        # P0 corrections.  It is intentionally a diagnostic configuration;
        # successful continuation does not validate it for acceptance.
        command.extend([
            "Materials/water_saturation_reconstruction/value_transform=identity",
            "Materials/gas_saturation_reconstruction/value_transform=identity",
            "Bounds/active=",
            "Dampers/inactive=",
            "Executioner/petsc_options_value=newtonls",
        ])
        actual_snes_type = "newtonls"
    if args.line_search is not None:
        command.append(f"Executioner/line_search={args.line_search}")
    if args.vi_monitor:
        command.append("Executioner/petsc_options=-snes_vi_monitor")
    if math.isclose(end_time, args.start_time_seconds, rel_tol=0.0, abs_tol=1.0e-12):
        command.append("Executioner/num_steps=0")
    if args.official_dtmax_seconds is not None:
        command.append(f"Executioner/dtmax={args.official_dtmax_seconds:.17g}")
    if args.fixed_dt_seconds is not None:
        fixed_steps = (end_time - args.start_time_seconds) / args.fixed_dt_seconds
        rounded_fixed_steps = round(fixed_steps)
        if rounded_fixed_steps < 1 or not math.isclose(
            fixed_steps, rounded_fixed_steps, rel_tol=0.0, abs_tol=1.0e-10
        ):
            parser.error(
                "--fixed-dt-seconds must divide the requested continuation interval exactly"
            )
        command.extend([
            "Executioner/inactive=TimeStepper",
            f"Executioner/dt={args.fixed_dt_seconds:.17g}",
            f"Executioner/num_steps={rounded_fixed_steps}",
        ])
    # Keep the well rate and productivity postprocessors on LINEAR so the
    # scalar BHP controls receive their current nonlinear values.  The
    # checkpoint-state diagnostics alone need the INITIAL override.
    command.extend(initial_execution_overrides(RESTART_INTEGRITY_POSTPROCESSORS))
    (output_dir / "command.txt").write_text(
        shlex.join(command) + "\n", encoding="utf-8"
    )
    with (output_dir / "solver.log").open("w", encoding="utf-8") as log:
        completed = subprocess.run(command, cwd=root, stdout=log, stderr=subprocess.STDOUT, check=False)

    comparison: dict[str, object] = {"status": "not_run"}
    candidate_csv = output_dir / "restart_identity.csv"
    failures: list[dict[str, object]] = []
    if completed.returncode != 0:
        failures.append({"metric": "process_returncode", "observed": completed.returncode})
    elif not candidate_csv.is_file():
        failures.append({"metric": "result_csv_exists", "observed": False})
    else:
        try:
            candidate_rows, _ = read_rows(candidate_csv)
            candidate = row_at_time(candidate_rows, args.start_time_seconds)
            comparison = compare_restart_rows(reference, candidate, PRODUCTION_RESTART_METRICS)
        except RuntimeError as error:
            failures.append({"metric": "initial_row", "reason": str(error)})
        if comparison.get("status") != "pass":
            failures.append({
                "metric": "production_restart_state_identity",
                "missing_metrics": comparison.get("missing_metrics", []),
                "drifted_metrics": comparison.get("drifted_metrics", []),
            })
        if abs(end_time - args.start_time_seconds) > 1.0e-12:
            _, final = read_rows(candidate_csv)
            if abs(final.get("time", -math.inf) - end_time) > 1.0e-8:
                failures.append({"metric": "final_time", "observed": final.get("time"),
                                 "expected": end_time})
            audit = output_dir / "time_history_audit.json"
            audit_completed = subprocess.run(
                [sys.executable, str(root / "validation/scripts/audit_spe1_time_history.py"),
                 str(candidate_csv), "--output", str(audit), "--active-wells"],
                cwd=root,
                check=False,
            )
            if audit_completed.returncode != 0:
                failures.append({"metric": "segment_time_history_audit", "observed": "fail"})
    events = parse_solver_events((output_dir / "solver.log").read_text(errors="replace"))
    if events["contains_nan_or_inf_error"]:
        failures.append({"metric": "solver_nan_or_inf_error", "observed": True})
    if events["rejected_or_nonconverged_step_count"]:
        failures.append({"metric": "rejected_or_nonconverged_step_count",
                         "observed": events["rejected_or_nonconverged_step_count"]})

    summary = {
        "status": "pass" if not failures else "fail",
        "checkpoint_base": str(checkpoint_base),
        "reference_csv": str(reference_csv),
        "start_time_seconds": args.start_time_seconds,
        "end_time_seconds": end_time,
        "official_dtmax_seconds": args.official_dtmax_seconds,
        "fixed_dt_seconds": args.fixed_dt_seconds,
        "snes_type": actual_snes_type,
        "line_search": args.line_search,
        "vi_monitor": args.vi_monitor,
        "saturation_simplex_damper": args.saturation_simplex_damper,
        "write_checkpoint": args.write_checkpoint,
        "returncode": completed.returncode,
        "metrics": list(PRODUCTION_RESTART_METRICS),
        "comparison": comparison,
        "solver_events": events,
        "failures": failures,
    }
    write_json(output_dir / "summary.json", summary)
    print(f"{summary['status']}: {len(failures)} failures")
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
