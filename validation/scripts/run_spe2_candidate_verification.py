#!/usr/bin/env python3
"""Audit and, when explicitly requested, run the SPE2 candidate evidence set.

This runner cannot issue a production acceptance verdict while the governing
gate file forbids that claim. It separates static fragment evidence from the
coupled 900-day result so partial evidence remains explicit.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

import yaml


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_GATES = ROOT / "validation/reference_data/spe2_candidate_gates.yml"
DEFAULT_REGISTRY = ROOT / "moose_app/input/verified_block_registry.yml"
DEFAULT_SCHEMA = ROOT / "agent_workflows/schemas/problem_spec.schema.json"
ACCEPTANCE_LOCK = ROOT / ".agent-runtime/locks/spe_acceptance.lock"


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_yaml(path: Path) -> dict[str, Any]:
    document = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(document, dict):
        raise ValueError(f"expected a mapping in {path}")
    return document


def validate_problem_spec(spec: Path, schema: Path) -> None:
    try:
        import jsonschema
    except ImportError as error:
        raise RuntimeError("jsonschema is required to validate the SPE2 problem spec") from error
    jsonschema.validate(
        json.loads(spec.read_text(encoding="utf-8")),
        json.loads(schema.read_text(encoding="utf-8")),
    )


def candidate_block_audit(gates: dict[str, Any], registry_path: Path) -> list[dict[str, Any]]:
    registry = load_yaml(registry_path)
    records = {entry["id"]: entry for entry in registry.get("blocks", [])}
    audited: list[dict[str, Any]] = []
    for block_id in gates["required_candidate_blocks"]:
        record = records.get(block_id)
        item: dict[str, Any] = {"id": block_id, "pass": False}
        if record is None:
            item["reason"] = "missing registry record"
        else:
            relative = Path("moose_app/input/includes") / record["path"]
            source = ROOT / relative
            item.update({
                "version": record.get("version"),
                "status": record.get("status"),
                "path": str(relative),
                "recorded_sha256": record.get("sha256"),
                "actual_sha256": sha256_file(source) if source.is_file() else None,
            })
            item["pass"] = (
                record.get("status") == "candidate"
                and record.get("version") == "0.1.0-candidate"
                and source.is_file()
                and item["actual_sha256"] == item["recorded_sha256"]
            )
            if not item["pass"]:
                item["reason"] = "candidate status, version, path, or digest mismatch"
        audited.append(item)
    return audited


def static_test_regex(gates: dict[str, Any]) -> str:
    names = [entry.rsplit(".", 1)[-1] for entry in gates["static_evidence"]["required_tests"]]
    return "(" + "|".join(re.escape(name) for name in names) + ")"


def process_is_alive(pid: int) -> bool:
    if pid <= 0:
        return False
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def acquire_lock(output_dir: Path) -> int:
    payload = {"pid": os.getpid(), "output_dir": str(output_dir), "started": time.time()}
    ACCEPTANCE_LOCK.parent.mkdir(parents=True, exist_ok=True)
    try:
        descriptor = os.open(ACCEPTANCE_LOCK, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o644)
    except FileExistsError as error:
        try:
            owner = json.loads(ACCEPTANCE_LOCK.read_text(encoding="utf-8"))
            pid = int(owner.get("pid", -1))
        except (OSError, TypeError, ValueError, json.JSONDecodeError):
            pid = -1
        state = "live" if process_is_alive(pid) else "stale or unreadable"
        raise RuntimeError(f"MOOSE queue lock is {state}: {ACCEPTANCE_LOCK}, pid={pid}") from error
    os.write(descriptor, (json.dumps(payload, sort_keys=True) + "\n").encode())
    os.fsync(descriptor)
    return descriptor


def release_lock(descriptor: int) -> None:
    os.close(descriptor)
    try:
        owner = json.loads(ACCEPTANCE_LOCK.read_text(encoding="utf-8"))
    except (OSError, TypeError, ValueError, json.JSONDecodeError):
        return
    if int(owner.get("pid", -1)) == os.getpid():
        ACCEPTANCE_LOCK.unlink(missing_ok=True)


def run_static_tests(gates: dict[str, Any], output_dir: Path) -> dict[str, Any]:
    command = [
        str(ROOT / "agent_environment/skills/setup-moose-conda/scripts/moose_conda_env.sh"),
        "run",
        "--",
        "python",
        str(ROOT / ".agent-runtime/moose/python/run_tests"),
        "-j",
        "1",
        "--re",
        static_test_regex(gates),
    ]
    descriptor = acquire_lock(output_dir)
    try:
        completed = subprocess.run(
            command,
            cwd=ROOT / "moose_app",
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
    finally:
        release_lock(descriptor)
    (output_dir / "static_tests.log").write_text(completed.stdout, encoding="utf-8")
    return {"command": command, "returncode": completed.returncode, "pass": completed.returncode == 0}


def run_initial_state_audit(gates: dict[str, Any], output_dir: Path) -> dict[str, Any]:
    script = ROOT / gates["static_evidence"]["initial_state_generator"]
    command = [sys.executable, str(script), "--output-dir", str(output_dir)]
    completed = subprocess.run(
        command,
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    (output_dir / "initial_state.log").write_text(completed.stdout, encoding="utf-8")
    summary_path = output_dir / "initial_state_summary.json"
    summary = json.loads(summary_path.read_text(encoding="utf-8")) if summary_path.is_file() else None
    return {
        "command": command,
        "returncode": completed.returncode,
        "pass": completed.returncode == 0 and summary is not None and summary.get("status") == "pass",
        "summary": summary,
    }


def read_csv(path: Path) -> list[dict[str, float]]:
    with path.open(newline="", encoding="utf-8") as stream:
        rows = []
        for row in csv.DictReader(stream):
            rows.append({key: float(value) for key, value in row.items() if value not in (None, "")})
    if not rows:
        raise ValueError(f"no data rows in {path}")
    return rows


def maximum_absolute(rows: list[dict[str, float]], names: tuple[str, ...]) -> float | None:
    values = [abs(row[name]) for row in rows for name in names if name in row]
    return max(values) if values else None


def minimum(rows: list[dict[str, float]], name: str) -> float | None:
    values = [row[name] for row in rows if name in row]
    return min(values) if values else None


def coupled_gate_audit(rows: list[dict[str, float]], gates: dict[str, Any]) -> dict[str, Any]:
    limits = gates["coupled_evidence"]["gates"]
    final_time = rows[-1].get("time")
    metrics: dict[str, float | None] = {
        "component_relative_balance_max": maximum_absolute(
            rows, ("water_relative_balance", "oil_relative_balance", "gas_relative_balance")
        ),
        "solid_relative_balance_max": maximum_absolute(rows, ("solid_relative_balance",)),
        "phase_volume_constraint_l2_max": maximum_absolute(rows, ("phase_volume_constraint_l2",)),
        "phase_pressure_force_identity_l2_max": maximum_absolute(
            rows, ("water_pressure_force_identity_l2", "gas_pressure_force_identity_l2")
        ),
        "dynamic_pressure_lag_source_l2_max": maximum_absolute(
            rows, ("dynamic_pressure_lag_source_l2",)
        ),
        "mechanics_scaled_weak_residual_linf_max": maximum_absolute(
            rows,
            ("matrix_momentum_r_scaled_weak_residual_linf", "matrix_momentum_z_scaled_weak_residual_linf"),
        ),
        "energy_scaled_weak_residual_linf_max": maximum_absolute(
            rows, ("fluid_energy_scaled_weak_residual_linf", "solid_energy_scaled_weak_residual_linf")
        ),
        "minimum_solid_reference_jacobian": minimum(rows, "minimum_solid_reference_jacobian"),
        "minimum_water_saturation": minimum(rows, "minimum_water_saturation"),
        "minimum_gas_saturation": minimum(rows, "minimum_gas_saturation"),
        "minimum_oil_saturation": minimum(rows, "minimum_oil_saturation"),
        "minimum_conversion_dissipation": minimum(rows, "minimum_phase_transform_dissipation"),
        "minimum_saturation_onsager_dissipation": minimum(
            rows, "minimum_saturation_onsager_dissipation"
        ),
        "well_complementarity_linf_max": maximum_absolute(rows, ("spe2_well_complementarity_linf",)),
    }
    first = rows[0]
    temperature_deviations = []
    for row in rows:
        for name in ("average_fluid_temperature", "average_solid_temperature"):
            if name in row and name in first:
                temperature_deviations.append(abs(row[name] - first[name]))
    metrics["maximum_temperature_deviation_K"] = (
        max(temperature_deviations) if temperature_deviations else None
    )

    checks: list[dict[str, Any]] = []
    for name, value in metrics.items():
        limit = float(limits[name])
        lower_bound = name.startswith("minimum_")
        passed = value is not None and (value >= limit if lower_bound else value <= limit)
        checks.append({
            "name": name,
            "value": value,
            "comparison": ">=" if lower_bound else "<=",
            "limit": limit,
            "pass": passed,
        })
    end_time_limit = float(gates["coupled_evidence"]["required_end_time_s"])
    checks.append({
        "name": "end_time_s",
        "value": final_time,
        "comparison": ">=",
        "limit": end_time_limit,
        "pass": final_time is not None and final_time >= end_time_limit,
    })
    return {"checks": checks, "pass": all(item["pass"] for item in checks)}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--gates", type=Path, default=DEFAULT_GATES)
    parser.add_argument("--registry", type=Path, default=DEFAULT_REGISTRY)
    parser.add_argument("--schema", type=Path, default=DEFAULT_SCHEMA)
    parser.add_argument("--results-csv", type=Path)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--run-static-tests", action="store_true")
    parser.add_argument("--claim", choices=("candidate", "production"), default="candidate")
    args = parser.parse_args()

    args.output_dir.mkdir(parents=True, exist_ok=True)
    gates = load_yaml(args.gates)
    if args.claim == "production" and not gates.get("production_claim_allowed", False):
        raise SystemExit("production claim rejected: SPE2 registry blocks are candidate-only")

    spec = ROOT / gates["problem_spec"]
    validate_problem_spec(spec, args.schema)
    blocks = candidate_block_audit(gates, args.registry)
    static = {
        "spec_valid": True,
        "candidate_blocks": blocks,
        "candidate_blocks_pass": all(item["pass"] for item in blocks),
        "initial_state": run_initial_state_audit(gates, args.output_dir),
        "tests": {"status": "not_run"},
    }
    if args.run_static_tests:
        static["tests"] = run_static_tests(gates, args.output_dir)

    coupled: dict[str, Any] = {"status": "pending", "pass": False}
    if args.results_csv:
        coupled = coupled_gate_audit(read_csv(args.results_csv), gates)
        coupled["status"] = "pass" if coupled["pass"] else "fail"
        (args.output_dir / "result.csv").write_bytes(args.results_csv.read_bytes())

    static_pass = static["candidate_blocks_pass"] and static["initial_state"]["pass"] and (
        not args.run_static_tests or static["tests"]["pass"]
    )
    status = "candidate_pass" if static_pass and coupled["pass"] else (
        "coupled_fail" if args.results_csv and not coupled["pass"] else "coupled_pending"
    )
    summary = {
        "benchmark": gates["benchmark"],
        "claim_level": "candidate_only",
        "production_claim_allowed": False,
        "status": status,
        "static": static,
        "coupled": coupled,
        "provenance": {
            "gates": {"path": str(args.gates), "sha256": sha256_file(args.gates)},
            "registry": {"path": str(args.registry), "sha256": sha256_file(args.registry)},
            "problem_spec": {"path": str(spec), "sha256": sha256_file(spec)},
            "results_csv": (
                {"path": str(args.results_csv), "sha256": sha256_file(args.results_csv)}
                if args.results_csv else None
            ),
        },
    }
    (args.output_dir / "verification_summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(json.dumps({"status": status, "output": str(args.output_dir)}, sort_keys=True))
    return 0 if static_pass and (not args.results_csv or coupled["pass"]) else 1


if __name__ == "__main__":
    raise SystemExit(main())
