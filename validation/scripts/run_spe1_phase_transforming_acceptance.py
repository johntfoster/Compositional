#!/usr/bin/env python3
"""Run provenance-checked SPE1 CG/EG phase-transformation acceptance."""

from __future__ import annotations

import argparse
import atexit
import csv
import hashlib
import json
import math
import os
import re
import shlex
import subprocess
import sys
import time
from pathlib import Path

from spe1_energy_gates import energy_gate_limits

ROOT = Path(__file__).resolve().parents[2]
EXPECTED_END_TIME = 86400.0
INITIAL_TEMPERATURE = 333.15
TEMPERATURE_TOLERANCE = 1.0e-8
INJECTOR_TARGET_RATE = 32.774128
PRODUCER_TARGET_OIL_RATE = 0.03680261456666667
WELL_RATE_RELATIVE_TOLERANCE = 1.0e-4
INJECTOR_MAXIMUM_BHP = 62149342.24061635
PRODUCER_MINIMUM_BHP = 6894757.293168
OFFICIAL_END_TIME = 315360000.0
BHP_CONTROL_ABSOLUTE_TOLERANCE = 1.0
DOMAIN_LENGTH = 3048.0
SPE1_LAYER_BOUNDARIES = (2543.556, 2552.7)
SPE1_LAYER_OIL_PRESSURES = (
    32972876.15288512,
    33019779.87273818,
    33094835.007206395,
)
SPE1_INITIAL_SOLUTION_GAS_OIL_RATIO = 226.19666048237477
SPE1_INITIAL_WATER_SATURATION = 0.12
SPE1_INITIAL_GAS_SATURATION = 0.0
RESTART_EQUIVALENCE_DT_SECONDS = 2700.0
# Equilibration-stage nonlinear solver capacity.  The first physical full-mesh
# step completed in 49 iterations in the checkpoint pilot.  The 60-iteration
# limit preserves the requested schedule while leaving a small convergence
# margin for this initialized active-set transition.
EQUILIBRATION_MAX_ITS = 60
# Main-phase nonlinear solver capacity for the official-schedule diagnostic.
# It does not relax residual tolerances or permit a rejected step.  The limit
# lets a replay distinguish a slow active-set iteration from an iteration cap
# before declaring the required 675 s increment unacceptable.
PRODUCTION_MAX_ITS = 120
RESTART_INTEGRITY_RELATIVE_TOLERANCE = 5.0e-13
RESTART_INTEGRITY_ABSOLUTE_TOLERANCE = 1.0e-12
# ICs on fields that are restored from the equilibration checkpoint.  During a
# checkpoint restart these would overwrite the restored fields (MOOSE applies
# them at INITIAL), breaking state identity with the uninterrupted run.  They
# are deactivated on restart commands via ICs/inactive.  The scalar well
# variables remain in the equilibration system, with their ICs, scalar kernels,
# and well-source materials inactive.  The checkpoint therefore has the same
# variable layout as the production restart, whose scalar ICs initialize the
# well controls.
RESTART_INACTIVE_ICS = (
    "oil_pressure oil_pressure_enrichment solution_gas_oil_ratio water_saturation "
    "gas_saturation tau gas_phase_transformation_rate fluid_temperature "
    "solid_temperature matrix_reference_component_storage"
)
SCALAR_WELL_INITIAL_CONDITIONS = "injector_bhp_scalar_initial producer_bhp_scalar_initial"
SCALAR_WELL_CHECKPOINT_HOLD_KERNELS = "injector_checkpoint_hold producer_checkpoint_hold"

ABSOLUTE_LIMITS = {
    "phase_volume_constraint_l2": 1.0e-8,
    "matrix_component_balance_l2": 1.0e-6,
    "matrix_component_storage_rate_integral": 1.0e-8,
    "water_global_balance": 1.0e-6,
    "oil_global_balance": 1.0e-6,
    "gas_global_balance": 1.0e-6,
    "phase_transform_kinetic_residual_l2": 1.0e-7,
    "tau_evolution_residual_l2": 1.0e-7,
    "phase_transform_affinity_identity_l2": 1.0e-12,
    "phase_transform_generalized_force_identity_l2": 1.0e-12,
    "phase_transform_power_identity_l2": 1.0e-12,
    "matrix_momentum_x_scaled_weak_residual_linf": 1.0e-7,
    "matrix_momentum_y_scaled_weak_residual_linf": 1.0e-7,
    "matrix_momentum_z_scaled_weak_residual_linf": 1.0e-7,
    "fluid_energy_scaled_weak_residual_linf": 1.0e-7,
    "solid_energy_scaled_weak_residual_linf": 1.0e-7,
}
LOWER_LIMITS = {
    "minimum_oil_saturation": -1.0e-12,
    "minimum_gas_saturation": -1.0e-12,
    "minimum_phase_transform_dissipation": -1.0e-12,
    "minimum_solid_reference_jacobian": 1.0e-8,
}
UPPER_LIMITS = {"maximum_gas_saturation": 1.0 + 1.0e-12}
THERMODYNAMIC_DIAGNOSTICS = (
    "average_reconstructed_tau",
    "average_phase_transform_dissolved_mu",
    "average_phase_transform_free_mu",
    "average_phase_transform_affinity",
    "average_phase_transform_generalized_force",
)
RESTART_INTEGRITY_POSTPROCESSORS = (
    "average_solid_reference_jacobian",
    "minimum_solid_reference_jacobian",
    "average_oil_pressure",
    "average_water_saturation",
    "average_gas_saturation",
    "minimum_oil_saturation",
    "minimum_gas_saturation",
    "maximum_gas_saturation",
    "average_solution_gas_oil_ratio",
    "average_tau",
    "average_reconstructed_tau",
    "average_gas_phase_transformation_rate",
    "average_fluid_temperature",
    "average_solid_temperature",
    "average_phase_transform_dissolved_mu",
    "average_phase_transform_free_mu",
    "average_phase_transform_affinity",
    "average_phase_transform_generalized_force",
    "minimum_phase_transform_dissipation",
    "minimum_undersaturation_gap",
    "water_reference_component_mass",
    "oil_reference_component_mass",
    "gas_reference_component_mass",
    "solid_reference_component_mass",
)
REPORT_OUTPUT_STEMS = (
    "physical_element_fields",
    "phase_rate_element_field",
    "nodal_mechanics",
    "nodal_temperature",
)
SECONDS_PER_DAY = 86400.0
OPM_REFERENCE_PATH = "validation/reference_data/spe1_case1_opm_flow_2021_10.csv"
OPM_COMPARISON_SCRIPT = "validation/scripts/compare_spe1_cg_eg_to_opm.py"
PHYSICAL_SCOPE_AUDIT_SCRIPT = "validation/scripts/check_spe1_physical_scope.py"
SOLUTION_GAS_HISTORY_AUDIT_SCRIPT = "validation/scripts/audit_spe1_solution_gas_history.py"


def lateral_mesh_overrides(cells: int, include_well_parameters: bool = True) -> list[str]:
    cell_length = DOMAIN_LENGTH / cells
    producer_minimum = DOMAIN_LENGTH - cell_length
    completion_area_scale = (10.0 / cells) ** 2
    overrides = [
        f"Mesh/spe1_cartesian_base/ix={cells}",
        f"Mesh/spe1_cartesian_base/iy={cells}",
        f"Mesh/spe1_producer_completion/bottom_left={producer_minimum:.17g} "
        f"{producer_minimum:.17g} 2552.7",
        "Mesh/spe1_producer_completion/top_right=3048 3048 2567.94",
        "Mesh/spe1_injector_completion/bottom_left=0 0 2537.46",
        f"Mesh/spe1_injector_completion/top_right={cell_length:.17g} "
        f"{cell_length:.17g} 2543.556",
        f"Mesh/spe1_injector_completion_nodes/top_right={cell_length:.17g} "
        f"{cell_length:.17g} 2543.556",
        f"Mesh/spe1_producer_completion_nodes/bottom_left={producer_minimum:.17g} "
        f"{producer_minimum:.17g} 2552.7",
    ]
    if include_well_parameters:
        overrides.extend([
            "Materials/injector/completion_reference_volume="
            f"{566336.9318400001 * completion_area_scale:.17g}",
            "Materials/producer/completion_reference_volume="
            f"{1415842.3296 * completion_area_scale:.17g}",
        ])
    return overrides
ACTIVE_WELL_POSTPROCESSORS = (
    "matrix_component_balance_l2 phase_volume_constraint_l2 "
    "phase_transform_kinetic_residual_l2 minimum_phase_transform_dissipation "
    "tau_evolution_residual_l2 phase_transform_affinity_identity_l2 "
    "phase_transform_generalized_force_identity_l2 phase_transform_power_identity_l2 "
    "matrix_momentum_x_scaled_weak_residual_linf "
    "matrix_momentum_y_scaled_weak_residual_linf "
    "matrix_momentum_z_scaled_weak_residual_linf "
    "fluid_energy_scaled_weak_residual_linf solid_energy_scaled_weak_residual_linf "
    "fluid_energy_local_residual_l2 solid_energy_local_residual_l2 "
    "fluid_energy_global_balance solid_energy_global_balance total_energy_global_balance "
    "fluid_energy_storage_rate_integral solid_energy_storage_rate_integral "
    "fluid_energy_source_power_integral solid_energy_source_power_integral "
    "fluid_energy_external_work_power_integral solid_energy_external_work_power_integral "
    "fluid_energy_conversion_power_integral solid_energy_conversion_power_integral "
    "fluid_energy_flux_divergence_integral solid_energy_flux_divergence_integral "
    "fluid_energy_boundary_flux solid_energy_boundary_flux "
    "fluid_heat_flux_left fluid_heat_flux_right fluid_heat_flux_bottom fluid_heat_flux_top "
    "fluid_heat_flux_back fluid_heat_flux_front solid_heat_flux_left solid_heat_flux_right "
    "solid_heat_flux_bottom solid_heat_flux_top solid_heat_flux_back solid_heat_flux_front "
    "average_solid_reference_jacobian minimum_solid_reference_jacobian "
    "matrix_component_storage_rate_integral average_oil_pressure "
    "average_water_saturation average_gas_saturation minimum_oil_saturation minimum_gas_saturation "
    "maximum_gas_saturation average_solution_gas_oil_ratio average_tau "
    "average_reconstructed_tau average_phase_transform_dissolved_mu "
    "average_phase_transform_free_mu average_phase_transform_affinity "
    "average_phase_transform_generalized_force average_gas_phase_transformation_rate "
    "average_fluid_temperature average_solid_temperature water_storage_rate_integral "
    "oil_storage_rate_integral gas_storage_rate_integral water_source_integral "
    "oil_source_integral gas_source_integral water_global_balance oil_global_balance "
    "gas_global_balance injector_gas_surface_rate injector_cell_pressure "
    "producer_cell_pressure gas_saturation_10_10_3 "
    "gas_saturation_10_10_3_backbone gas_saturation_10_10_3_enrichment "
    "injector_water_surface_rate injector_oil_surface_rate "
    "producer_oil_surface_rate producer_water_surface_rate producer_gas_surface_rate "
    "field_gas_oil_ratio injected_gas_surface_rate injected_gas_surface_volume "
    "produced_oil_surface_volume produced_gas_surface_volume produced_water_surface_volume "
    "injector_gas_surface_productivity producer_oil_surface_productivity injector_bhp producer_bhp"
)
EQUILIBRATION_OMITTED_POSTPROCESSORS = {
    "injector_gas_surface_rate", "injector_cell_pressure", "producer_cell_pressure",
    "injector_water_surface_rate", "injector_oil_surface_rate", "producer_oil_surface_rate",
    "producer_water_surface_rate", "producer_gas_surface_rate", "field_gas_oil_ratio",
    "injected_gas_surface_rate", "injected_gas_surface_volume", "produced_oil_surface_volume",
    "produced_gas_surface_volume", "produced_water_surface_volume",
    "injector_gas_surface_productivity", "producer_oil_surface_productivity", "injector_bhp",
    "producer_bhp",
}
EQUILIBRATION_POSTPROCESSORS = " ".join(
    name for name in ACTIVE_WELL_POSTPROCESSORS.split()
    if name not in EQUILIBRATION_OMITTED_POSTPROCESSORS
) + (
    " minimum_undersaturation_gap"
    " equilibrated_oil_pressure_deviation_l2"
    " equilibrated_solution_gas_oil_ratio_deviation_l2"
    " equilibrated_water_saturation_deviation_l2"
    " equilibrated_gas_saturation_deviation_l2"
    " water_reference_component_mass"
    " oil_reference_component_mass"
    " gas_reference_component_mass"
    " solid_reference_component_mass"
)
ACTIVE_WELL_RESTART_POSTPROCESSORS = " ".join(dict.fromkeys(
    ACTIVE_WELL_POSTPROCESSORS.split() + list(RESTART_INTEGRITY_POSTPROCESSORS)
))
EQUILIBRATION_DEVIATION_METRICS = (
    "equilibrated_oil_pressure_deviation_l2",
    "equilibrated_solution_gas_oil_ratio_deviation_l2",
    "equilibrated_water_saturation_deviation_l2",
    "equilibrated_gas_saturation_deviation_l2",
)
EQUILIBRATION_MASS_METRICS = (
    "water_reference_component_mass",
    "oil_reference_component_mass",
    "gas_reference_component_mass",
    "solid_reference_component_mass",
)
EQUILIBRATION_MASS_RELATIVE_TOLERANCE = 1.0e-8
ACCEPTANCE_LOCK = ROOT / ".agent-runtime/locks/spe_acceptance.lock"
INCLUDE_PATTERN = re.compile(r"^\s*!include\s+(?:[\"']([^\"']+)[\"']|(\S+))")


def process_is_alive(pid: int) -> bool:
    """Return whether pid still names a live process owned by this runtime."""
    if pid <= 0:
        return False
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def acquire_acceptance_lock(output_dir: Path) -> int:
    """Publish a process-owned marker for provenance-critical SPE execution."""
    payload = {
        "pid": os.getpid(),
        "output_dir": str(output_dir),
        "started_unix_seconds": time.time(),
    }
    ACCEPTANCE_LOCK.parent.mkdir(parents=True, exist_ok=True)
    while True:
        try:
            descriptor = os.open(ACCEPTANCE_LOCK, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o644)
            break
        except FileExistsError:
            try:
                existing = json.loads(ACCEPTANCE_LOCK.read_text(encoding="utf-8"))
                existing_pid = int(existing.get("pid", -1))
            except (OSError, ValueError, TypeError, json.JSONDecodeError):
                existing_pid = -1
            if process_is_alive(existing_pid):
                raise RuntimeError(
                    f"Another provenance-critical SPE run owns {ACCEPTANCE_LOCK}: "
                    f"pid={existing_pid}. Wait for it to finish before starting another run."
                )
            stale = ACCEPTANCE_LOCK.with_name(
                f"{ACCEPTANCE_LOCK.name}.stale-{int(time.time())}-{existing_pid}"
            )
            try:
                ACCEPTANCE_LOCK.replace(stale)
            except FileNotFoundError:
                continue
    os.write(descriptor, (json.dumps(payload, sort_keys=True) + "\n").encode())
    os.fsync(descriptor)
    return descriptor


def release_acceptance_lock(descriptor: int) -> None:
    """Release this process's marker without removing another process's lock."""
    os.close(descriptor)
    try:
        existing = json.loads(ACCEPTANCE_LOCK.read_text(encoding="utf-8"))
    except (OSError, ValueError, TypeError, json.JSONDecodeError):
        return
    if int(existing.get("pid", -1)) == os.getpid():
        ACCEPTANCE_LOCK.unlink(missing_ok=True)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def sha256_files(root: Path, paths: list[Path]) -> str:
    """Hash explicit files by repository-relative path and content."""
    digest = hashlib.sha256()
    for path in sorted(set(paths), key=lambda p: str(p.relative_to(root))):
        digest.update(str(path.relative_to(root)).encode())
        digest.update(b"\0")
        digest.update(sha256_file(path).encode())
        digest.update(b"\n")
    return digest.hexdigest()


def sha256_tree(root: Path, paths: list[Path]) -> str:
    files: list[Path] = []
    for path in paths:
        if path.is_dir():
            files.extend(p for p in path.rglob("*") if p.is_file())
        elif path.is_file():
            files.append(path)
    return sha256_files(root, files)


def sha256_file_manifest(root: Path, paths: list[Path]) -> dict[str, str]:
    """Return repository-relative hashes so a provenance failure names its files."""
    files: list[Path] = []
    for path in paths:
        if path.is_dir():
            files.extend(candidate for candidate in path.rglob("*") if candidate.is_file())
        elif path.is_file():
            files.append(path)
    return {
        str(path.relative_to(root)): sha256_file(path)
        for path in sorted(set(files), key=lambda candidate: str(candidate.relative_to(root)))
    }


def resolved_input_files(deck: Path) -> list[Path]:
    """Return the recursively resolved MOOSE input-deck include closure."""
    pending = [deck.resolve()]
    resolved: set[Path] = set()
    while pending:
        current = pending.pop()
        if current in resolved:
            continue
        if not current.is_file():
            raise FileNotFoundError(f"Resolved MOOSE input does not exist: {current}")
        resolved.add(current)
        for line in current.read_text(encoding="utf-8").splitlines():
            match = INCLUDE_PATTERN.match(line)
            if match:
                include = match.group(1) or match.group(2)
                pending.append((current.parent / include).resolve())
    return sorted(resolved)


def provenance(root: Path, deck: Path, verifier: Path) -> dict[str, object]:
    exe = root / "moose_app/multicomponent_reactive_flow-opt"
    app_lib = root / "moose_app/lib/libmulticomponent_reactive_flow-opt.so.0.0.0"
    test_lib = root / "moose_app/test/lib/libmulticomponent_reactive_flow_test-opt.so.0.0.0"
    physical_scope_audit = root / PHYSICAL_SCOPE_AUDIT_SCRIPT
    solution_gas_history_audit = root / SOLUTION_GAS_HISTORY_AUDIT_SCRIPT
    tracked_inputs = [
        root / "moose_app/examples",
        root / "moose_app/input",
        root / "moose_app/include",
        root / "moose_app/src",
        root / "moose_app/patches",
    ]
    manuscript_inputs = [root / "main.tex", root / "defs.tex", root / "sections"]
    deck_inputs = resolved_input_files(deck)
    record: dict[str, object] = {
        "deck_path": str(deck.relative_to(root)),
        "deck_sha256": sha256_file(deck),
        "resolved_input_paths": [str(path.relative_to(root)) for path in deck_inputs],
        "resolved_input_tree_sha256": sha256_files(root, deck_inputs),
        "executable_path": str(exe.relative_to(root)),
        "executable_sha256": sha256_file(exe),
        "application_library_path": str(app_lib.relative_to(root)),
        "application_library_sha256": sha256_file(app_lib),
        "verifier_path": str(verifier.relative_to(root)),
        "verifier_sha256": sha256_file(verifier),
        "physical_scope_audit_path": str(physical_scope_audit.relative_to(root)),
        "physical_scope_audit_sha256": sha256_file(physical_scope_audit),
        "solution_gas_history_audit_path": str(solution_gas_history_audit.relative_to(root)),
        "solution_gas_history_audit_sha256": sha256_file(solution_gas_history_audit),
        "input_and_source_tree_sha256": sha256_tree(root, tracked_inputs),
        "input_and_source_files_sha256": sha256_file_manifest(root, tracked_inputs),
        "manuscript_tree_sha256": sha256_tree(root, manuscript_inputs),
    }
    if test_lib.exists():
        record["test_library_path"] = str(test_lib.relative_to(root))
        record["test_library_sha256"] = sha256_file(test_lib)
    return record


RUNTIME_PROVENANCE_KEYS = (
    "deck_path",
    "deck_sha256",
    "resolved_input_paths",
    "resolved_input_tree_sha256",
    "executable_path",
    "executable_sha256",
    "application_library_path",
    "application_library_sha256",
    "test_library_path",
    "test_library_sha256",
    "verifier_path",
    "verifier_sha256",
    "physical_scope_audit_path",
    "physical_scope_audit_sha256",
    "solution_gas_history_audit_path",
    "solution_gas_history_audit_sha256",
    "manuscript_tree_sha256",
)


def runtime_provenance_unchanged(before: dict[str, object], after: dict[str, object]) -> bool:
    """Require runtime artifacts and the governing manuscript to remain fixed."""
    return all(before.get(key) == after.get(key) for key in RUNTIME_PROVENANCE_KEYS)


def write_json(path: Path, value: object) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    temporary.replace(path)


def opm_reference_days(reference_path: Path) -> set[float]:
    """Return the report times supplied by the pinned OPM SPE1 reference."""
    with reference_path.open(newline="", encoding="utf-8") as stream:
        return {float(row["time_days"]) for row in csv.DictReader(stream)}


def run_opm_comparison(
    root: Path,
    output_dir: Path,
    result_csv: Path,
    expected_end_time: float,
) -> dict[str, object]:
    """Generate a descriptive CG/EG-to-OPM comparison outside acceptance gates."""
    reference_path = root / OPM_REFERENCE_PATH
    comparison_script = root / OPM_COMPARISON_SCRIPT
    end_day = expected_end_time / SECONDS_PER_DAY
    comparison_csv = output_dir / "opm_comparison.csv"
    summary_json = output_dir / "opm_comparison_summary.json"
    figure_base = output_dir / "opm_comparison"
    command = [
        sys.executable,
        str(comparison_script),
        "--moose-csv",
        str(result_csv),
        "--opm-csv",
        str(reference_path),
        "--comparison-csv",
        str(comparison_csv),
        "--summary-json",
        str(summary_json),
        "--figure-base",
        str(figure_base),
        "--expected-end-day",
        f"{end_day:.17g}",
    ]
    completed = subprocess.run(command, cwd=root, capture_output=True, text=True, check=False)
    log_path = output_dir / "opm_comparison.log"
    log_path.write_text(
        "command: " + shlex.join(command) + "\n"
        + "stdout:\n" + completed.stdout
        + "\nstderr:\n" + completed.stderr,
        encoding="utf-8",
    )
    return {
        "requested": True,
        "role": "physical-result comparison; not an acceptance gate",
        "status": "generated" if completed.returncode == 0 else "error",
        "returncode": completed.returncode,
        "end_day": end_day,
        "reference_path": OPM_REFERENCE_PATH,
        "reference_sha256": sha256_file(reference_path),
        "comparison_script": OPM_COMPARISON_SCRIPT,
        "comparison_script_sha256": sha256_file(comparison_script),
        "comparison_csv": str(comparison_csv),
        "summary_json": str(summary_json),
        "figure_png": str(figure_base.with_suffix(".png")),
        "figure_svg": str(figure_base.with_suffix(".svg")),
        "log": str(log_path),
    }


def run_physical_scope_audit(
    root: Path, deck: Path, output_dir: Path
) -> dict[str, object]:
    """Record the physical scope of a deck before a provenance-critical run."""
    audit_script = root / PHYSICAL_SCOPE_AUDIT_SCRIPT
    output_path = output_dir / "physical_scope_audit.json"
    command = [
        sys.executable,
        str(audit_script),
        "--repository-root",
        str(root),
        "--deck",
        str(deck),
        "--output",
        str(output_path),
    ]
    completed = subprocess.run(command, cwd=root, capture_output=True, text=True, check=False)
    log_path = output_dir / "physical_scope_audit.log"
    log_path.write_text(
        "command: " + shlex.join(command) + "\n"
        + "stdout:\n" + completed.stdout
        + "\nstderr:\n" + completed.stderr,
        encoding="utf-8",
    )
    if completed.returncode != 0:
        raise RuntimeError(
            "Physical-scope audit failed before SPE execution; see "
            f"{log_path}"
        )
    if not output_path.is_file():
        raise RuntimeError("Physical-scope audit returned success without an artifact")
    audit = json.loads(output_path.read_text(encoding="utf-8"))
    if audit.get("status") != "declared_with_unconstrained_specializations":
        raise RuntimeError("Physical-scope audit returned an unrecognized declaration status")
    return {
        "status": audit["status"],
        "role": audit["audit_role"],
        "artifact": str(output_path),
        "sha256": sha256_file(output_path),
        "script": PHYSICAL_SCOPE_AUDIT_SCRIPT,
        "script_sha256": sha256_file(audit_script),
        "log": str(log_path),
    }


def run_solution_gas_history_audit(
    root: Path, output_dir: Path, result_csv: Path, file_base: str
) -> dict[str, object]:
    """Audit local DRSDT=0 history without hiding field-level violations."""
    audit_script = root / SOLUTION_GAS_HISTORY_AUDIT_SCRIPT
    output_path = output_dir / f"{file_base}_solution_gas_history_audit.json"
    command = [
        sys.executable,
        str(audit_script),
        "--result-csv",
        str(result_csv),
        "--field-glob",
        str(output_dir / f"{file_base}_physical_element_fields_*.csv"),
        "--initial-rs",
        f"{SPE1_INITIAL_SOLUTION_GAS_OIL_RATIO:.17g}",
        "--output",
        str(output_path),
    ]
    completed = subprocess.run(command, cwd=root, capture_output=True, text=True, check=False)
    log_path = output_dir / f"{file_base}_solution_gas_history_audit.log"
    log_path.write_text(
        "command: " + shlex.join(command) + "\n"
        + "stdout:\n" + completed.stdout
        + "\nstderr:\n" + completed.stderr,
        encoding="utf-8",
    )
    if completed.returncode not in (0, 1) or not output_path.is_file():
        raise RuntimeError(
            "Dissolved-gas history audit did not produce a valid result; see "
            f"{log_path}"
        )
    audit = json.loads(output_path.read_text(encoding="utf-8"))
    if audit.get("status") not in ("pass", "fail"):
        raise RuntimeError("Dissolved-gas history audit returned an unrecognized status")
    return {
        "status": audit["status"],
        "artifact": str(output_path),
        "sha256": sha256_file(output_path),
        "script": SOLUTION_GAS_HISTORY_AUDIT_SCRIPT,
        "script_sha256": sha256_file(audit_script),
        "failure_count": audit["failure_count"],
        "maximum_solution_gas_oil_ratio": audit["maximum_solution_gas_oil_ratio"],
        "maximum_initial_cap_excess": audit["maximum_initial_cap_excess"],
        "maximum_stepwise_increase": audit["maximum_stepwise_increase"],
        "log": str(log_path),
    }


def read_rows(csv_path: Path) -> tuple[list[dict[str, str]], dict[str, float]]:
    with csv_path.open(newline="", encoding="utf-8") as stream:
        rows = list(csv.DictReader(stream))
    if not rows:
        raise RuntimeError("MOOSE produced no CSV rows")
    final = {key: float(value) for key, value in rows[-1].items() if value not in ("", None)}
    return rows, final


def numeric_row(row: dict[str, str]) -> dict[str, float]:
    """Convert all populated CSV entries in one row to finite-comparison values."""
    return {key: float(value) for key, value in row.items() if value not in ("", None)}


def row_at_time(rows: list[dict[str, str]], target_time: float) -> dict[str, float]:
    """Return the unique CSV row at target_time and fail closed if it is absent."""
    matches = [
        numeric_row(row)
        for row in rows
        if row.get("time") not in ("", None)
        and math.isclose(float(row["time"]), target_time, rel_tol=0.0, abs_tol=1.0e-8)
    ]
    if len(matches) != 1:
        raise RuntimeError(
            f"Expected exactly one CSV row at time {target_time:.17g}; found {len(matches)}"
        )
    return matches[0]


def initial_execution_overrides(postprocessors: tuple[str, ...]) -> list[str]:
    """Evaluate restart-integrity state diagnostics at INITIAL and accepted step ends."""
    return [
        f"Postprocessors/{name}/execute_on=INITIAL TIMESTEP_END"
        for name in postprocessors
    ]


def checkpoint_base_exists(checkpoint_base: Path) -> bool:
    """Return whether a MOOSE checkpoint base has mesh and restart payloads."""
    parent = checkpoint_base.parent
    stem = checkpoint_base.name
    return (
        any(parent.glob(f"{stem}-mesh.cpa*"))
        and any(parent.glob(f"{stem}-restart-*.rd"))
    )


def compare_restart_rows(
    reference: dict[str, float],
    candidate: dict[str, float],
    metrics: tuple[str, ...] = RESTART_INTEGRITY_POSTPROCESSORS,
) -> dict[str, object]:
    """Compare checkpointed state diagnostics and fail closed on missing or drifting values."""
    comparisons: dict[str, dict[str, float | bool]] = {}
    missing: list[str] = []
    nonfinite: list[str] = []
    drifted: list[str] = []
    for metric in metrics:
        if metric not in reference or metric not in candidate:
            missing.append(metric)
            continue
        reference_value = reference[metric]
        candidate_value = candidate[metric]
        if not math.isfinite(reference_value) or not math.isfinite(candidate_value):
            nonfinite.append(metric)
            continue
        difference = candidate_value - reference_value
        tolerance = (
            RESTART_INTEGRITY_ABSOLUTE_TOLERANCE
            + RESTART_INTEGRITY_RELATIVE_TOLERANCE
            * max(abs(reference_value), abs(candidate_value), 1.0)
        )
        passed = abs(difference) <= tolerance
        comparisons[metric] = {
            "reference": reference_value,
            "candidate": candidate_value,
            "difference": difference,
            "tolerance": tolerance,
            "pass": passed,
        }
        if not passed:
            drifted.append(metric)
    return {
        "status": "pass" if not (missing or nonfinite or drifted) else "fail",
        "relative_tolerance": RESTART_INTEGRITY_RELATIVE_TOLERANCE,
        "absolute_tolerance": RESTART_INTEGRITY_ABSOLUTE_TOLERANCE,
        "required_metrics": list(metrics),
        "missing_metrics": missing,
        "nonfinite_metrics": nonfinite,
        "drifted_metrics": drifted,
        "comparisons": comparisons,
    }


def parse_solver_events(log: str) -> dict[str, object]:
    lowered = log.lower()
    rejected = (
        lowered.count("nonlinear solve did not converge")
        + lowered.count("rejecting time step")
        + lowered.count("solve failed, cutting timestep")
    )
    return {
        "factor_outmemory_count": lowered.count("factor_outmemory"),
        "rejected_or_nonconverged_step_count": rejected,
        "converged_solve_count": lowered.count("solve converged"),
        "contains_nan_or_inf_error": bool(
            re.search(r"(?<![a-z])nan(?![a-z])|\binfinite\b", lowered)
        ),
    }


def nonempty_report_outputs(output_dir: Path) -> dict[str, list[str]]:
    found: dict[str, list[str]] = {}
    for stem in REPORT_OUTPUT_STEMS:
        paths = []
        for path in sorted(output_dir.glob(f"result_{stem}_*.csv")):
            with path.open(encoding="utf-8") as stream:
                if sum(1 for _ in stream) > 1:
                    paths.append(path.name)
        found[stem] = paths
    return found


def equilibration_cell_deviations(
    output_dir: Path, timestep_index: int | None = None
) -> dict[str, dict[str, float]]:
    """Summarize element-sampled departures from the official cell-centered initial map."""
    if timestep_index is None:
        paths = sorted(output_dir.glob("equilibration_physical_element_fields_*.csv"))
    else:
        paths = [
            output_dir / f"equilibration_physical_element_fields_{timestep_index:04d}.csv"
        ]
    if not paths:
        raise RuntimeError("stage 0 produced no physical-element field sample")
    if not paths[-1].is_file():
        raise RuntimeError(
            f"stage 0 produced no physical-element field sample for step {timestep_index}"
        )
    with paths[-1].open(newline="", encoding="utf-8") as stream:
        rows = list(csv.DictReader(stream))
    if not rows:
        raise RuntimeError("the final stage-0 physical-element field sample is empty")

    differences: dict[str, list[float]] = {
        "oil_pressure": [],
        "solution_gas_oil_ratio": [],
        "water_saturation": [],
        "gas_saturation": [],
    }
    for row in rows:
        z = float(row["z"])
        layer = 0 if z < SPE1_LAYER_BOUNDARIES[0] else 1 if z < SPE1_LAYER_BOUNDARIES[1] else 2
        differences["oil_pressure"].append(
            float(row["sample_oil_pressure"]) - SPE1_LAYER_OIL_PRESSURES[layer]
        )
        differences["solution_gas_oil_ratio"].append(
            float(row["sample_solution_gas_oil_ratio"])
            - SPE1_INITIAL_SOLUTION_GAS_OIL_RATIO
        )
        differences["water_saturation"].append(
            float(row["sample_water_saturation"]) - SPE1_INITIAL_WATER_SATURATION
        )
        differences["gas_saturation"].append(
            float(row["sample_gas_saturation"]) - SPE1_INITIAL_GAS_SATURATION
        )
    return {
        name: {
            "rms": math.sqrt(math.fsum(value * value for value in values) / len(values)),
            "maximum_absolute": max(abs(value) for value in values),
        }
        for name, values in differences.items()
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("--mpi-ranks", type=int, default=4)
    parser.add_argument("--dt-seconds", type=float, default=10800.0)
    parser.add_argument(
        "--line-search",
        choices=("basic", "l2", "bt", "cp"),
        help=(
            "Explicit PETSc line-search override recorded with the acceptance "
            "command and verification summary."
        ),
    )
    parser.add_argument(
        "--equilibration-dt-seconds",
        type=float,
        default=RESTART_EQUIVALENCE_DT_SECONDS,
    )
    parser.add_argument("--equilibration-steps", type=int, default=32)
    parser.add_argument("--num-steps", type=int)
    parser.add_argument(
        "--pilot-end-time-seconds",
        type=float,
        help="Stop an official-schedule diagnostic early and record the shorter horizon.",
    )
    parser.add_argument(
        "--official-dtmax-seconds",
        type=float,
        default=10800.0,
        help=(
            "Cap the official-schedule adaptive timestep without changing any official "
            "report boundary or constitutive setting; defaults to 10800 s."
        ),
    )
    parser.add_argument(
        "--production-checkpoint",
        action="store_true",
        help=(
            "Write a production checkpoint at the requested pilot endpoint for a "
            "restart-verified nonlinear diagnostic. This mode remains subject to every "
            "acceptance gate and does not alter the schedule or solution."
        ),
    )
    parser.add_argument("--lateral-cells", type=int, default=10)
    parser.add_argument("--inactive-wells", action="store_true")
    parser.add_argument(
        "--stage-only-diagnostic",
        action="store_true",
        help=(
            "Run and report only the closed-boundary stage-0 solve without acquiring the "
            "provenance-critical acceptance lock. This mode is diagnostic, never acceptance."
        ),
    )
    parser.add_argument(
        "--official-schedule",
        action="store_true",
        help="Preserve the deck timestepper and require the day-3650 horizon.",
    )
    parser.add_argument(
        "--opm-comparison",
        action="store_true",
        help=(
            "Generate a descriptive CG/EG-to-OPM artifact when the requested official "
            "endpoint is a pinned OPM report day; comparison differences are never "
            "acceptance gates."
        ),
    )
    parser.add_argument(
        "--deck",
        help=(
            "Repository-relative SPE1 deck to run. By default, --official-schedule "
            "selects the official-horizon deck and other runs select the one-day deck."
        ),
    )
    args = parser.parse_args()
    if args.lateral_cells < 1:
        parser.error("--lateral-cells must be positive")
    if args.equilibration_dt_seconds <= 0.0 or args.equilibration_steps < 1:
        parser.error("The stage-0 equilibration timestep and step count must be positive")
    if args.official_dtmax_seconds is not None and args.official_dtmax_seconds <= 0.0:
        parser.error("--official-dtmax-seconds must be positive")
    if not math.isclose(
        args.equilibration_dt_seconds,
        RESTART_EQUIVALENCE_DT_SECONDS,
        rel_tol=0.0,
        abs_tol=1.0e-12,
    ):
        parser.error(
            "The restart-integrity gate requires a 2700 s stage-0 timestep so its retained "
            "checkpoint can be compared with one uninterrupted extra 2700 s step"
        )

    root = Path(__file__).resolve().parents[2]
    verifier = Path(__file__).resolve()
    default_deck = (
        "moose_app/examples/spe1_case1_q2_eg_phase_transforming_10_year_superlu.i"
        if args.official_schedule
        else "moose_app/examples/spe1_case1_q2_eg_phase_transforming_report_superlu.i"
    )
    deck = (root / (args.deck or default_deck)).resolve()
    exe = root / "moose_app/multicomponent_reactive_flow-opt"
    output_dir = args.output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    output_base = output_dir / "result"
    num_steps = args.num_steps
    if num_steps is None and not args.official_schedule:
        num_steps = 2 * math.ceil(EXPECTED_END_TIME / args.dt_seconds) + 4
    expected_end_time = (
        args.pilot_end_time_seconds
        if args.pilot_end_time_seconds is not None
        else OFFICIAL_END_TIME if args.official_schedule else EXPECTED_END_TIME
    )
    if args.pilot_end_time_seconds is not None and not args.official_schedule:
        parser.error("--pilot-end-time-seconds requires --official-schedule")
    if args.opm_comparison and not args.official_schedule:
        parser.error("--opm-comparison requires --official-schedule")
    if args.opm_comparison:
        reference_path = root / OPM_REFERENCE_PATH
        endpoint_day = expected_end_time / SECONDS_PER_DAY
        if not any(
            math.isclose(endpoint_day, day, rel_tol=0.0, abs_tol=1.0e-12)
            for day in opm_reference_days(reference_path)
        ):
            parser.error(
                "--opm-comparison requires an endpoint matching a pinned OPM report day; "
                f"requested day {endpoint_day:g}"
            )
    physical_scope_audit = run_physical_scope_audit(root, deck, output_dir)
    if not args.stage_only_diagnostic:
        lock_descriptor = acquire_acceptance_lock(output_dir)
        atexit.register(release_acceptance_lock, lock_descriptor)

    before = provenance(root, deck, verifier)
    initial_provenance = {
        "before": before,
        "after": None,
        "runtime_unchanged_during_run": None,
        "development_tree_unchanged_during_run": None,
    }
    write_json(output_dir / "provenance.json", initial_provenance)
    write_json(output_dir / "verification_summary.json", {
        "benchmark": "SPE1 Case 1",
        "variant": (
            "full_cg_eg_phase_transforming_official_schedule_pilot"
            if args.pilot_end_time_seconds is not None
            else "full_cg_eg_phase_transforming_all_terms"
        ),
        "status": "running",
        "classification": (
            "stage_0_diagnostic_not_acceptance"
            if args.stage_only_diagnostic
            else "provenance_critical_acceptance"
        ),
        "mpi_ranks": args.mpi_ranks,
        "dt_seconds": args.dt_seconds,
        "official_dtmax_seconds": args.official_dtmax_seconds if args.official_schedule else None,
        "requested_num_steps": num_steps,
        "stage_0_equilibration_steps": args.equilibration_steps,
        "stage_0_equilibration_dt_seconds": args.equilibration_dt_seconds,
        "physical_scope_audit": physical_scope_audit,
        "provenance": before,
    })

    equilibration_base = output_dir / "equilibration"
    equilibration_end_time = args.equilibration_dt_seconds * args.equilibration_steps
    uninterrupted_extra_end_time = (
        equilibration_end_time + RESTART_EQUIVALENCE_DT_SECONDS
    )
    launch_prefix = ["mpiexec", "-n", str(args.mpi_ranks)] if args.mpi_ranks > 1 else []
    equilibration_command = [
        *launch_prefix, str(exe),
        "-i", str(deck),
        f"Outputs/file_base={equilibration_base}",
        "Outputs/checkpoint=true",
        f"Executioner/dt={args.equilibration_dt_seconds}",
        f"Executioner/end_time={uninterrupted_extra_end_time}",
        f"Executioner/num_steps={args.equilibration_steps + 1}",
        # The first physical step from the initial condition must complete the
        # quadratic-Bernstein/saturation active-set transition, which
        # reproducibly needs ~49 Newton iterations regardless of dt (2700 or
        # the 1350 retry).  The production deck's nl_max_its=40 is deliberate
        # for the dt=10800 production schedule and leaves no headroom here.
        # Give the equilibration stage 60 so step 1 converges without the
        # schedule-shifting cutback that drops the 86400 s checkpoint.
        f"Executioner/nl_max_its={EQUILIBRATION_MAX_ITS}",
        f"Postprocessors/active={EQUILIBRATION_POSTPROCESSORS}",
        f"ICs/inactive={SCALAR_WELL_INITIAL_CONDITIONS}",
        # Retain the scalar well degrees of freedom in the checkpoint.  Their
        # scalar kernels and well-source materials are inactive in the deck,
        # so this does not add a well source to the closed-domain stage.
        "Variables/inactive=",
        f"ScalarKernels/active={SCALAR_WELL_CHECKPOINT_HOLD_KERNELS}",
    ]
    # The official-horizon deck carries an [Executioner]/[TimeStepper]
    # IterationAdaptiveDT block whose computeInitialDT() returns its own dt
    # (10800 s) and ignores Executioner/dt.  Disable that block so MOOSE
    # auto-creates a default ConstantDT with dt = Executioner/dt (2700 s),
    # exactly reproducing the passing one-day deck's fixed 32-step schedule
    # and the 89100 s closed-equivalence step.
    if args.official_schedule:
        equilibration_command.append("Executioner/inactive=TimeStepper")
    equilibration_command.extend(
        initial_execution_overrides(RESTART_INTEGRITY_POSTPROCESSORS)
    )
    if args.lateral_cells != 10:
        equilibration_command.extend(
            lateral_mesh_overrides(args.lateral_cells, include_well_parameters=False)
        )
    (output_dir / "equilibration_command.txt").write_text(
        shlex.join(equilibration_command) + "\n", encoding="utf-8"
    )

    command = [
        *launch_prefix, str(exe),
        "-i", str(deck),
        f"Outputs/file_base={output_base}",
    ]
    if args.official_schedule:
        if args.pilot_end_time_seconds is not None:
            command.append(f"Executioner/end_time={args.pilot_end_time_seconds}")
        if args.official_dtmax_seconds is not None:
            command.append(f"Executioner/dtmax={args.official_dtmax_seconds:.17g}")
        # Give the main phase the same Newton headroom as the equilibration
        # stage (see PRODUCTION_MAX_ITS) so gas-front phase-appearance steps
        # converge instead of aborting at dtmin.
        command.append(f"Executioner/nl_max_its={PRODUCTION_MAX_ITS}")
    else:
        command.extend([
            f"Executioner/dt={args.dt_seconds}",
            f"Executioner/num_steps={num_steps}",
        ])
    if args.line_search is not None:
        command.append(f"Executioner/line_search={args.line_search}")
    if args.production_checkpoint:
        command.append("Outputs/checkpoint=true")
    if args.lateral_cells != 10:
        command.extend(lateral_mesh_overrides(args.lateral_cells))
    command.extend([
        f"Problem/restart_file_base={equilibration_base}_cp/"
        f"{args.equilibration_steps:04d}",
        "Executioner/start_time=0",
        f"ICs/inactive={RESTART_INACTIVE_ICS}",
    ])
    if not args.inactive_wells:
        command.extend([
            "Variables/inactive=",
            "Materials/inactive=",
            "Materials/inactive_well_sources/block=1 2 3",
            "ScalarKernels/active=injector_control producer_control",
            f"Postprocessors/active={ACTIVE_WELL_RESTART_POSTPROCESSORS}",
        ])
    else:
        command.append(f"Postprocessors/active={EQUILIBRATION_POSTPROCESSORS}")
    command.extend(initial_execution_overrides(RESTART_INTEGRITY_POSTPROCESSORS))
    (output_dir / "command.txt").write_text(shlex.join(command) + "\n", encoding="utf-8")

    started = time.time()
    failures: list[dict[str, object]] = []
    with (output_dir / "equilibration_solver.log").open("w", encoding="utf-8") as log:
        equilibration_completed = subprocess.run(
            equilibration_command, cwd=root, stdout=log, stderr=subprocess.STDOUT, check=False
        )
    equilibration_csv = output_dir / "equilibration.csv"
    equilibration_final: dict[str, float] = {}
    uninterrupted_extra_final: dict[str, float] = {}
    initial_equilibration: dict[str, float] = {}
    equilibration_rows: list[dict[str, str]] = []
    equilibration_mass_changes: dict[str, dict[str, float]] = {}
    equilibration_cell_map_deviations: dict[str, dict[str, float]] = {}
    equilibration_solution_gas_history_audit: dict[str, object] = {"status": "not_run"}
    if equilibration_completed.returncode != 0:
        failures.append({"metric": "stage_0_process_returncode",
                         "observed": equilibration_completed.returncode, "expected": 0})
    elif equilibration_csv.exists():
        equilibration_rows, _ = read_rows(equilibration_csv)
        try:
            initial_equilibration = row_at_time(equilibration_rows, 0.0)
            equilibration_final = row_at_time(equilibration_rows, equilibration_end_time)
            uninterrupted_extra_final = row_at_time(
                equilibration_rows, uninterrupted_extra_end_time
            )
        except RuntimeError as error:
            failures.append({"metric": "stage_0_required_time_rows", "reason": str(error)})
        for metric, limit in ABSOLUTE_LIMITS.items():
            observed = abs(equilibration_final.get(metric, math.inf))
            if observed > limit:
                failures.append({"metric": f"stage_0_{metric}",
                                 "observed": observed, "limit": limit})
        for metric, limit in energy_gate_limits(
            numeric_row(row) for row in equilibration_rows
        ).items():
            observed = abs(equilibration_final.get(metric, math.inf))
            if observed > limit:
                failures.append({"metric": f"stage_0_{metric}",
                                 "observed": observed, "limit": limit})
        for metric, limit in LOWER_LIMITS.items():
            observed = equilibration_final.get(metric, -math.inf)
            if observed < limit:
                failures.append({"metric": f"stage_0_{metric}",
                                 "observed": observed, "lower_limit": limit})
        for metric, limit in UPPER_LIMITS.items():
            observed = equilibration_final.get(metric, math.inf)
            if observed > limit:
                failures.append({"metric": f"stage_0_{metric}",
                                 "observed": observed, "upper_limit": limit})
        for metric in ("water_source_integral", "oil_source_integral", "gas_source_integral"):
            observed = abs(equilibration_final.get(metric, math.inf))
            if observed > 1.0e-12:
                failures.append({"metric": f"stage_0_zero_external_{metric}",
                                 "observed": observed, "limit": 1.0e-12})
        for metric in EQUILIBRATION_DEVIATION_METRICS:
            if not math.isfinite(equilibration_final.get(metric, math.nan)):
                failures.append({"metric": f"stage_0_{metric}",
                                 "reason": "missing_or_not_finite"})
        for metric in EQUILIBRATION_MASS_METRICS:
            initial_mass = initial_equilibration.get(metric, math.nan)
            final_mass = equilibration_final.get(metric, math.nan)
            change = final_mass - initial_mass
            tolerance = EQUILIBRATION_MASS_RELATIVE_TOLERANCE * max(abs(initial_mass), 1.0)
            equilibration_mass_changes[metric] = {
                "initial": initial_mass,
                "final": final_mass,
                "change": change,
                "absolute_tolerance": tolerance,
            }
            if not math.isfinite(change) or abs(change) > tolerance:
                failures.append({
                    "metric": f"stage_0_{metric}_change",
                    "observed": change,
                    "limit": tolerance,
                })
        equilibration_audit = output_dir / "equilibration_time_history_audit.json"
        equilibration_audit_completed = subprocess.run(
            [sys.executable, str(root / "validation/scripts/audit_spe1_time_history.py"),
             str(equilibration_csv), "--output", str(equilibration_audit)],
            cwd=root, check=False,
        )
        if equilibration_audit_completed.returncode != 0:
            failures.append({"metric": "stage_0_all_timestep_history_audit",
                             "observed": "fail", "expected": "pass"})
        try:
            equilibration_solution_gas_history_audit = run_solution_gas_history_audit(
                root, output_dir, equilibration_csv, "equilibration"
            )
            if equilibration_solution_gas_history_audit["status"] != "pass":
                failures.append({
                    "metric": "stage_0_drsdt_zero_solution_gas_history",
                    "observed": "fail",
                    "expected": "pass",
                    "failure_count": equilibration_solution_gas_history_audit[
                        "failure_count"
                    ],
                })
        except (OSError, RuntimeError, ValueError) as error:
            failures.append({
                "metric": "stage_0_drsdt_zero_solution_gas_history",
                "reason": str(error),
            })
        try:
            equilibration_cell_map_deviations = equilibration_cell_deviations(
                output_dir, args.equilibration_steps
            )
        except (KeyError, OSError, RuntimeError, ValueError) as error:
            failures.append({"metric": "stage_0_cell_map_deviations",
                             "reason": str(error)})
    else:
        failures.append({"metric": "stage_0_result_csv_exists",
                         "observed": False, "expected": True})
    checkpoint_target = (
        Path(f"{equilibration_base}_cp") / f"{args.equilibration_steps:04d}"
    )
    if not checkpoint_base_exists(checkpoint_target):
        failures.append({"metric": "stage_0_checkpoint_exists",
                         "observed": False, "expected": True})

    restart_integrity_base = output_dir / "restart_integrity_checkpointed"
    restart_integrity_command = [
        *launch_prefix, str(exe),
        "-i", str(deck),
        f"Outputs/file_base={restart_integrity_base}",
        "Outputs/checkpoint=false",
        "Outputs/csv=true",
        "Outputs/exodus=false",
        f"Executioner/dt={RESTART_EQUIVALENCE_DT_SECONDS}",
        f"Executioner/end_time={uninterrupted_extra_end_time}",
        "Executioner/num_steps=1",
        f"Problem/restart_file_base={checkpoint_target}",
        f"Executioner/start_time={equilibration_end_time}",
        f"ICs/inactive={RESTART_INACTIVE_ICS}",
        # Preserve the stage-0 variable layout.  The well kernels and source
        # materials remain inactive for this closed-domain diagnostic.
        "Variables/inactive=",
        f"ScalarKernels/active={SCALAR_WELL_CHECKPOINT_HOLD_KERNELS}",
        f"Postprocessors/active={' '.join(RESTART_INTEGRITY_POSTPROCESSORS)}",
    ]
    # The restart-integrity step must advance exactly one 2700 s step from the
    # 86400 s checkpoint for equality with the uninterrupted equilibration row
    # at 89100 s.  The official-horizon deck's IterationAdaptiveDT would
    # instead take its own dt after restore, so disable it here too and rely
    # on the ConstantDT fallback (dt = Executioner/dt) for the single step.
    if args.official_schedule:
        restart_integrity_command.append("Executioner/inactive=TimeStepper")
    restart_integrity_command.extend(
        initial_execution_overrides(RESTART_INTEGRITY_POSTPROCESSORS)
    )
    if args.lateral_cells != 10:
        restart_integrity_command.extend(
            lateral_mesh_overrides(args.lateral_cells, include_well_parameters=False)
        )
    (output_dir / "restart_integrity_command.txt").write_text(
        shlex.join(restart_integrity_command) + "\n", encoding="utf-8"
    )

    restart_initial_comparison: dict[str, object] = {"status": "not_run"}
    restart_step_comparison: dict[str, object] = {"status": "not_run"}
    restart_integrity_returncode: int | None = None
    restart_integrity_initial: dict[str, float] = {}
    restart_integrity_final: dict[str, float] = {}
    if (
        equilibration_completed.returncode == 0
        and equilibration_csv.exists()
        and checkpoint_base_exists(checkpoint_target)
        and equilibration_final
        and uninterrupted_extra_final
    ):
        with (output_dir / "restart_integrity_solver.log").open(
            "w", encoding="utf-8"
        ) as log:
            restart_completed = subprocess.run(
                restart_integrity_command,
                cwd=root,
                stdout=log,
                stderr=subprocess.STDOUT,
                check=False,
            )
        restart_integrity_returncode = restart_completed.returncode
        restart_csv = output_dir / "restart_integrity_checkpointed.csv"
        if restart_completed.returncode != 0:
            failures.append({
                "metric": "restart_integrity_process_returncode",
                "observed": restart_completed.returncode,
                "expected": 0,
            })
        elif not restart_csv.is_file():
            failures.append({
                "metric": "restart_integrity_result_csv_exists",
                "observed": False,
                "expected": True,
            })
        else:
            try:
                restart_rows, _ = read_rows(restart_csv)
                restart_integrity_initial = row_at_time(
                    restart_rows, equilibration_end_time
                )
                restart_integrity_final = row_at_time(
                    restart_rows, uninterrupted_extra_end_time
                )
                restart_initial_comparison = compare_restart_rows(
                    equilibration_final, restart_integrity_initial
                )
                restart_step_comparison = compare_restart_rows(
                    uninterrupted_extra_final, restart_integrity_final
                )
            except RuntimeError as error:
                failures.append({
                    "metric": "restart_integrity_required_time_rows",
                    "reason": str(error),
                })
            if restart_initial_comparison.get("status") != "pass":
                failures.append({
                    "metric": "restart_initial_state_identity",
                    "observed": restart_initial_comparison.get("status"),
                    "expected": "pass",
                    "missing_metrics": restart_initial_comparison.get("missing_metrics", []),
                    "drifted_metrics": restart_initial_comparison.get("drifted_metrics", []),
                })
            if restart_step_comparison.get("status") != "pass":
                failures.append({
                    "metric": "restart_2700s_step_equivalence",
                    "observed": restart_step_comparison.get("status"),
                    "expected": "pass",
                    "missing_metrics": restart_step_comparison.get("missing_metrics", []),
                    "drifted_metrics": restart_step_comparison.get("drifted_metrics", []),
                })
    restart_integrity_report: dict[str, object] = {
        "status": (
            "pass"
            if restart_initial_comparison.get("status") == "pass"
            and restart_step_comparison.get("status") == "pass"
            else "fail"
        ),
        "checkpoint_base": str(checkpoint_target),
        "stage_0_final_time": equilibration_end_time,
        "extra_closed_step_seconds": RESTART_EQUIVALENCE_DT_SECONDS,
        "uninterrupted_extra_time": uninterrupted_extra_end_time,
        "history_state_coverage": (
            "The one-step comparison advances from the retained stage-0 checkpoint and "
            "therefore exercises the old solution used by the nonincreasing solution-gas "
            "PVT history cap."
        ),
        "returncode": restart_integrity_returncode,
        "initial_state_comparison": restart_initial_comparison,
        "extra_step_comparison": restart_step_comparison,
    }
    write_json(output_dir / "restart_integrity_summary.json", restart_integrity_report)
    write_json(output_dir / "equilibration_summary.json", {
        "status": "pass" if not failures else "fail",
        "accepted_nonzero_steps": sum(
            0.0 < float(row["time"]) <= equilibration_end_time
            for row in equilibration_rows
        ),
        "final": equilibration_final,
        "uninterrupted_restart_integrity_extra_step": uninterrupted_extra_final,
        "official_equil_rsvd_swof_deviation_metrics": {
            metric: equilibration_final.get(metric) for metric in EQUILIBRATION_DEVIATION_METRICS
        },
        "closed_domain_reference_mass_changes": equilibration_mass_changes,
        "official_cell_center_map_deviations": equilibration_cell_map_deviations,
        "restart_integrity": {
            "summary": str(output_dir / "restart_integrity_summary.json"),
            "initial_state_status": restart_initial_comparison.get("status"),
            "extra_step_status": restart_step_comparison.get("status"),
        },
        "failures": failures,
    })

    if args.stage_only_diagnostic:
        elapsed = time.time() - started
        after = provenance(root, deck, verifier)
        runtime_unchanged = runtime_provenance_unchanged(before, after)
        development_unchanged = (
            before["input_and_source_tree_sha256"] == after["input_and_source_tree_sha256"]
        )
        before_files = before["input_and_source_files_sha256"]
        after_files = after["input_and_source_files_sha256"]
        changed_development_paths = sorted(
            path
            for path in set(before_files) | set(after_files)
            if before_files.get(path) != after_files.get(path)
        )
        if not runtime_unchanged:
            failures.append({"metric": "stage_0_runtime_provenance_unchanged",
                             "observed": False, "expected": True})
        write_json(output_dir / "provenance.json", {
            "before": before,
            "after": after,
            "runtime_unchanged_during_run": runtime_unchanged,
            "development_tree_unchanged_during_run": development_unchanged,
            "changed_development_paths": changed_development_paths,
            "restart_integrity_artifact": {
                "path": str(output_dir / "restart_integrity_summary.json"),
                "sha256": sha256_file(output_dir / "restart_integrity_summary.json"),
            },
        })
        equilibration_log = (output_dir / "equilibration_solver.log").read_text(
            errors="replace"
        )
        events = parse_solver_events(equilibration_log)
        if events["contains_nan_or_inf_error"]:
            failures.append({"metric": "stage_0_solver_nan_or_inf_error", "observed": True,
                             "expected": False})
        write_json(output_dir / "equilibration_solver_events.json", events)
        write_json(output_dir / "equilibration_summary.json", {
            "status": "pass" if not failures else "fail",
            "accepted_nonzero_steps": sum(
                0.0 < float(row["time"]) <= equilibration_end_time
                for row in equilibration_rows
            ),
            "final": equilibration_final,
            "uninterrupted_restart_integrity_extra_step": uninterrupted_extra_final,
            "official_equil_rsvd_swof_deviation_metrics": {
                metric: equilibration_final.get(metric)
                for metric in EQUILIBRATION_DEVIATION_METRICS
            },
            "closed_domain_reference_mass_changes": equilibration_mass_changes,
            "official_cell_center_map_deviations": equilibration_cell_map_deviations,
            "solution_gas_history_audit": equilibration_solution_gas_history_audit,
            "restart_integrity": {
                "summary": str(output_dir / "restart_integrity_summary.json"),
                "initial_state_status": restart_initial_comparison.get("status"),
                "extra_step_status": restart_step_comparison.get("status"),
            },
            "failures": failures,
        })
        summary = {
            "benchmark": "SPE1 Case 1",
            "classification": "stage_0_diagnostic_not_acceptance",
            "status": "pass" if not failures else "fail",
            "returncode": equilibration_completed.returncode,
            "elapsed_seconds": elapsed,
            "mpi_ranks": args.mpi_ranks,
            "lateral_cells": args.lateral_cells,
            "equilibration_dt_seconds": args.equilibration_dt_seconds,
            "requested_steps": args.equilibration_steps,
            "accepted_nonzero_timesteps": sum(
                0.0 < float(row["time"]) <= equilibration_end_time
                for row in equilibration_rows
            ),
            "final": equilibration_final,
            "uninterrupted_restart_integrity_extra_step": uninterrupted_extra_final,
            "closed_domain_reference_mass_changes": equilibration_mass_changes,
            "official_cell_center_map_deviations": equilibration_cell_map_deviations,
            "solution_gas_history_audit": equilibration_solution_gas_history_audit,
            "restart_integrity": {
                "summary": str(output_dir / "restart_integrity_summary.json"),
                "initial_state_comparison": restart_initial_comparison,
                "extra_step_comparison": restart_step_comparison,
            },
            "physical_scope_audit": physical_scope_audit,
            "failures": failures,
            "solver_events": events,
            "runtime_unchanged_during_run": runtime_unchanged,
            "development_tree_unchanged_during_run": development_unchanged,
        }
        write_json(output_dir / "verification_summary.json", summary)
        print(
            f"{summary['status']} diagnostic: "
            f"{summary['accepted_nonzero_timesteps']} accepted nonzero stage-0 steps, "
            f"{len(failures)} failures, {elapsed:.1f} s"
        )
        return 0 if not failures else 1

    if not failures:
        with (output_dir / "solver.log").open("w", encoding="utf-8") as log:
            completed = subprocess.run(
                command, cwd=root, stdout=log, stderr=subprocess.STDOUT, check=False
            )
    else:
        completed = subprocess.CompletedProcess(command, 99)
        (output_dir / "solver.log").write_text(
            "Official schedule not started because stage-0 equilibration failed.\n",
            encoding="utf-8",
        )
    elapsed = time.time() - started
    after = provenance(root, deck, verifier)
    runtime_unchanged = runtime_provenance_unchanged(before, after)
    development_unchanged = (
        before["input_and_source_tree_sha256"] == after["input_and_source_tree_sha256"]
    )
    before_files = before["input_and_source_files_sha256"]
    after_files = after["input_and_source_files_sha256"]
    changed_development_paths = sorted(
        path
        for path in set(before_files) | set(after_files)
        if before_files.get(path) != after_files.get(path)
    )
    write_json(output_dir / "provenance.json", {
        "before": before,
        "after": after,
        "runtime_unchanged_during_run": runtime_unchanged,
        "development_tree_unchanged_during_run": development_unchanged,
        "changed_development_paths": changed_development_paths,
    })

    final: dict[str, float] = {}
    accepted_nonzero_steps = 0
    production_checkpoint: Path | None = None
    stage_1_initial_comparison: dict[str, object] = {"status": "not_run"}
    opm_comparison: dict[str, object] = {
        "requested": args.opm_comparison,
        "role": "physical-result comparison; not an acceptance gate",
        "status": "not_requested" if not args.opm_comparison else "not_run",
    }
    production_solution_gas_history_audit: dict[str, object] = {"status": "not_run"}
    csv_path = output_dir / "result.csv"
    if completed.returncode != 0:
        failures.append({"metric": "process_returncode", "observed": completed.returncode,
                         "expected": 0})
    if not runtime_unchanged:
        failures.append({"metric": "runtime_provenance_unchanged", "observed": False,
                         "expected": True})
    rows: list[dict[str, str]] = []
    if completed.returncode == 0 and csv_path.exists():
        rows, final = read_rows(csv_path)
        try:
            stage_1_initial = row_at_time(rows, 0.0)
            stage_1_initial_comparison = compare_restart_rows(
                equilibration_final, stage_1_initial
            )
        except RuntimeError as error:
            failures.append({
                "metric": "stage_1_initial_required_time_row",
                "reason": str(error),
            })
        if stage_1_initial_comparison.get("status") != "pass":
            failures.append({
                "metric": "stage_0_to_stage_1_initial_state_identity",
                "observed": stage_1_initial_comparison.get("status"),
                "expected": "pass",
                "missing_metrics": stage_1_initial_comparison.get("missing_metrics", []),
                "drifted_metrics": stage_1_initial_comparison.get("drifted_metrics", []),
            })
        accepted_nonzero_steps = sum(float(row["time"]) > 0 for row in rows)
        if args.production_checkpoint:
            production_checkpoint = (
                Path(f"{output_base}_cp") / f"{accepted_nonzero_steps:04d}"
            )
            if not checkpoint_base_exists(production_checkpoint):
                failures.append({
                    "metric": "production_checkpoint_exists",
                    "observed": False,
                    "expected": True,
                    "checkpoint": str(production_checkpoint),
                })
        if abs(final.get("time", -1.0) - expected_end_time) > 1.0e-8:
            failures.append({"metric": "final_time", "observed": final.get("time", -1.0),
                             "expected": expected_end_time})
        for metric, limit in ABSOLUTE_LIMITS.items():
            observed = abs(final.get(metric, math.inf))
            if observed > limit:
                failures.append({"metric": metric, "observed": observed, "limit": limit})
        for metric, limit in energy_gate_limits(
            numeric_row(row) for row in rows
        ).items():
            observed = abs(final.get(metric, math.inf))
            if observed > limit:
                failures.append({"metric": metric, "observed": observed, "limit": limit})
        for metric, limit in LOWER_LIMITS.items():
            observed = final.get(metric, -math.inf)
            if observed < limit:
                failures.append({"metric": metric, "observed": observed, "lower_limit": limit})
        for metric, limit in UPPER_LIMITS.items():
            observed = final.get(metric, math.inf)
            if observed > limit:
                failures.append({"metric": metric, "observed": observed, "upper_limit": limit})
        for metric in ("average_fluid_temperature", "average_solid_temperature"):
            error = abs(final.get(metric, math.inf) - INITIAL_TEMPERATURE)
            if error > TEMPERATURE_TOLERANCE:
                failures.append({"metric": metric, "observed_error": error,
                                 "limit": TEMPERATURE_TOLERANCE})
        for metric in THERMODYNAMIC_DIAGNOSTICS:
            if not math.isfinite(final.get(metric, math.nan)):
                failures.append({"metric": metric, "reason": "missing_or_not_finite"})
        if not args.inactive_wells:
            if final.get("maximum_gas_saturation", 0.0) <= 1.0e-3:
                failures.append({"metric": "maximum_gas_saturation",
                                 "observed": final.get("maximum_gas_saturation"),
                                 "lower_limit": 1.0e-3})
            control_data = (
                ("injected_gas_surface_rate", INJECTOR_TARGET_RATE),
                ("producer_oil_surface_rate", PRODUCER_TARGET_OIL_RATE),
            )
            injector_on_bhp = (
                final.get("injector_bhp", math.inf)
                >= INJECTOR_MAXIMUM_BHP - BHP_CONTROL_ABSOLUTE_TOLERANCE
            )
            producer_on_bhp = (
                final.get("producer_bhp", -math.inf)
                <= PRODUCER_MINIMUM_BHP + BHP_CONTROL_ABSOLUTE_TOLERANCE
            )
            for (metric, target), on_bhp in zip(
                control_data, (injector_on_bhp, producer_on_bhp)
            ):
                error = abs(final.get(metric, math.inf) - target) / target
                if error > WELL_RATE_RELATIVE_TOLERANCE and not (
                    args.official_schedule and on_bhp
                ):
                    failures.append({"metric": metric, "relative_error": error,
                                     "limit": WELL_RATE_RELATIVE_TOLERANCE})
            if (
                final.get("injector_bhp", math.inf)
                > INJECTOR_MAXIMUM_BHP + BHP_CONTROL_ABSOLUTE_TOLERANCE
            ):
                failures.append({"metric": "injector_bhp", "observed": final.get("injector_bhp"),
                                 "upper_limit": INJECTOR_MAXIMUM_BHP})
            if (
                final.get("producer_bhp", -math.inf)
                < PRODUCER_MINIMUM_BHP - BHP_CONTROL_ABSOLUTE_TOLERANCE
            ):
                failures.append({"metric": "producer_bhp", "observed": final.get("producer_bhp"),
                                 "lower_limit": PRODUCER_MINIMUM_BHP})
        history_audit_path = output_dir / "time_history_audit.json"
        history_command = [sys.executable,
                           str(root / "validation/scripts/audit_spe1_time_history.py"),
                           str(csv_path), "--output", str(history_audit_path)]
        if not args.inactive_wells:
            history_command.append("--active-wells")
        history_completed = subprocess.run(history_command, cwd=root, check=False)
        if history_completed.returncode != 0:
            failures.append({"metric": "all_timestep_history_audit", "observed": "fail",
                             "expected": "pass"})
        elif not history_audit_path.is_file():
            failures.append({"metric": "all_timestep_history_audit_output", "observed": False,
                             "expected": True})
        try:
            production_solution_gas_history_audit = run_solution_gas_history_audit(
                root, output_dir, csv_path, "result"
            )
            if production_solution_gas_history_audit["status"] != "pass":
                failures.append({
                    "metric": "drsdt_zero_solution_gas_history",
                    "observed": "fail",
                    "expected": "pass",
                    "failure_count": production_solution_gas_history_audit[
                        "failure_count"
                    ],
                })
        except (OSError, RuntimeError, ValueError) as error:
            failures.append({
                "metric": "drsdt_zero_solution_gas_history",
                "reason": str(error),
            })
        if args.opm_comparison:
            opm_comparison = run_opm_comparison(
                root, output_dir, csv_path, expected_end_time
            )
    elif completed.returncode == 0:
        failures.append({"metric": "result_csv_exists", "observed": False, "expected": True})

    restart_integrity_report["stage_1_initial_state_comparison"] = stage_1_initial_comparison
    restart_integrity_report["status"] = (
        "pass"
        if restart_initial_comparison.get("status") == "pass"
        and restart_step_comparison.get("status") == "pass"
        and stage_1_initial_comparison.get("status") == "pass"
        else "fail"
    )
    write_json(output_dir / "restart_integrity_summary.json", restart_integrity_report)
    write_json(output_dir / "provenance.json", {
        "before": before,
        "after": after,
        "runtime_unchanged_during_run": runtime_unchanged,
        "development_tree_unchanged_during_run": development_unchanged,
        "changed_development_paths": changed_development_paths,
        "restart_integrity_artifact": {
            "path": str(output_dir / "restart_integrity_summary.json"),
            "sha256": sha256_file(output_dir / "restart_integrity_summary.json"),
        },
    })

    report_outputs = nonempty_report_outputs(output_dir)
    for stem, paths in report_outputs.items():
        if not paths:
            failures.append({"metric": f"nonempty_{stem}_output", "observed": False,
                             "expected": True})
    exodus_path = output_dir / "result.e"
    if (
        not args.official_schedule
        and (not exodus_path.exists() or exodus_path.stat().st_size == 0)
    ):
        failures.append({"metric": "nonempty_exodus_output", "observed": False,
                         "expected": True})

    log_text = (output_dir / "solver.log").read_text(errors="replace")
    events = parse_solver_events(log_text)
    if events["contains_nan_or_inf_error"]:
        failures.append({"metric": "solver_nan_or_inf_error", "observed": True,
                         "expected": False})
    if events["factor_outmemory_count"]:
        failures.append({"metric": "factor_outmemory_count",
                         "observed": events["factor_outmemory_count"], "expected": 0})
    if args.official_schedule and events["rejected_or_nonconverged_step_count"]:
        failures.append({"metric": "rejected_or_nonconverged_step_count",
                         "observed": events["rejected_or_nonconverged_step_count"],
                         "expected": 0})
    write_json(output_dir / "solver_events.json", events)
    summary = {
        "benchmark": "SPE1 Case 1",
        "variant": (
            "full_cg_eg_phase_transforming_official_schedule_pilot"
            if args.pilot_end_time_seconds is not None
            else "full_cg_eg_phase_transforming_all_terms"
        ),
        "status": "pass" if not failures else "fail",
        "returncode": completed.returncode,
        "elapsed_seconds": elapsed,
        "mpi_ranks": args.mpi_ranks,
        "lateral_cells": args.lateral_cells,
        "dt_seconds": args.dt_seconds,
        "line_search": args.line_search,
        "official_dtmax_seconds": args.official_dtmax_seconds if args.official_schedule else None,
        "timestep_mode": "deck_adaptive_official_schedule" if args.official_schedule
                         else "command_line_uniform",
        "expected_end_time": expected_end_time,
        "requested_num_steps": num_steps,
        "stage_0_equilibration": {
            "dt_seconds": args.equilibration_dt_seconds,
            "requested_steps": args.equilibration_steps,
            "final": equilibration_final,
            "uninterrupted_restart_integrity_extra_step": uninterrupted_extra_final,
            "deviation_metrics": {
                metric: equilibration_final.get(metric)
                for metric in EQUILIBRATION_DEVIATION_METRICS
            },
            "closed_domain_reference_mass_changes": equilibration_mass_changes,
            "official_cell_center_map_deviations": equilibration_cell_map_deviations,
            "checkpoint": str(checkpoint_target),
        },
        "restart_integrity": {
            "summary": str(output_dir / "restart_integrity_summary.json"),
            "status": restart_integrity_report["status"],
            "stage_0_checkpoint_identity": restart_initial_comparison,
            "uninterrupted_vs_checkpointed_2700s_step": restart_step_comparison,
            "stage_0_to_stage_1_initial_identity": stage_1_initial_comparison,
        },
        "accepted_nonzero_timesteps": accepted_nonzero_steps,
        "production_checkpoint": {
            "requested": args.production_checkpoint,
            "base": str(production_checkpoint) if production_checkpoint else None,
            "exists": checkpoint_base_exists(production_checkpoint)
            if production_checkpoint
            else False,
        },
        "opm_comparison": opm_comparison,
        "solution_gas_history_audit": {
            "stage_0": equilibration_solution_gas_history_audit,
            "production": production_solution_gas_history_audit,
        },
        "physical_scope_audit": physical_scope_audit,
        "final": final,
        "absolute_limits": ABSOLUTE_LIMITS,
        "energy_scale_aware_limits": energy_gate_limits(numeric_row(row) for row in rows),
        "lower_limits": LOWER_LIMITS,
        "upper_limits": UPPER_LIMITS,
        "failures": failures,
        "solver_events": events,
        "report_outputs": report_outputs,
        "exodus_bytes": exodus_path.stat().st_size if exodus_path.exists() else 0,
        "provenance": before,
        "runtime_unchanged_during_run": runtime_unchanged,
        "development_tree_unchanged_during_run": development_unchanged,
    }
    write_json(output_dir / "verification_summary.json", summary)
    print(f"{summary['status']}: {accepted_nonzero_steps} accepted nonzero steps, "
          f"{len(failures)} failures, {elapsed:.1f} s")
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main())
