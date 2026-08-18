#!/usr/bin/env python3
"""Check conservative phase appearance in the coupled SPE1 Q2/CG-EG deck."""

from __future__ import annotations

import csv
import argparse
import hashlib
import json
import math
import os
import re
import shlex
import signal
import subprocess
import tempfile
from contextlib import nullcontext
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
VERIFIER = Path(__file__).resolve()
APP_DIR = ROOT / "moose_app"
APP = APP_DIR / "multicomponent_reactive_flow-opt"
DECK = APP_DIR / "examples" / "spe1_case1_q2_eg_phase_transforming.i"
MOOSE_PATCH_SERIES = APP_DIR / "patches" / "moose" / "series.yml"

ABSOLUTE_LIMITS = {
    "phase_volume_constraint_l2": 1.0e-8,
    # These are extensive kg/s balance diagnostics over the complete SPE1
    # domain.  1e-6 kg/s is both physically negligible and above the observed
    # double-precision assembly floor for the 2.8e8 m^3 reference volume.
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
MINIMUM_GAS_SATURATION = -1.0e-12
MAXIMUM_GAS_SATURATION = 1.0 + 1.0e-12
MINIMUM_PHASE_TRANSFORM_DISSIPATION = -1.0e-12
MINIMUM_SOLID_REFERENCE_JACOBIAN = 1.0e-8
INITIAL_TEMPERATURE = 333.15
TEMPERATURE_TOLERANCE = 1.0e-8
EXPECTED_END_TIME = 86400.0

# Reduced (1 x 1 lateral) harness timeouts.  The DRSDT gate runs a lagged
# active-set Picard outer loop whose transition steps perform up to
# fixed_point_max_its inner Newton solves, so the reduced budget is higher
# than the bare kinetic row's historical 300 s.
REDUCED_TIMEOUT_SECONDS = 600
FULL_TIMEOUT_SECONDS = 7200

DOMAIN_LENGTH = 3048.0


def lateral_mesh_overrides(cells: int) -> tuple[str, ...]:
    """Map an n by n lateral convergence mesh onto the fixed SPE1 domain."""
    cell_length = DOMAIN_LENGTH / cells
    producer_minimum = DOMAIN_LENGTH - cell_length
    return (
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
    )


def reduced_material_overrides() -> tuple[str, ...]:
    """Remap layer materials for the 1 by 1 lateral reduced mesh.

    With a single lateral cell the injector and producer completion boxes span
    the full domain, so the SubdomainBoundingBox generators reassign the entire
    bottom layer to block 11 and the entire top layer to block 13.  The
    production deck's layer-1 materials reference '1 11' and the layer-3
    materials reference '3 13', which is valid only when plain blocks 1 and 3
    survive.  Remap them to the completion block IDs for the reduced mesh.
    """
    return (
        "Materials/layer_1_water_darcy/block=11",
        "Materials/layer_1_oil_darcy/block=11",
        "Materials/layer_1_gas_darcy/block=11",
        "Materials/layer_3_water_darcy/block=13",
        "Materials/layer_3_oil_darcy/block=13",
        "Materials/layer_3_gas_darcy/block=13",
        "Materials/inactive_well_sources/block=11 2 13",
    )

def active_well_postprocessors(drsdt_closure: bool) -> str:
    """Active-wells postprocessor list for the selected phase-transfer closure."""
    phase_closure = (
        "phase_transform_solution_gas_constraint_l2"
        if drsdt_closure
        else "phase_transform_kinetic_residual_l2"
    )
    # The DRSDT=0 gate monitors the direct equilibrium phase-appearance residual
    # (gas_appearance_equilibrium_residual_l2) directly; the bare solution-gas
    # constraint residual is a non-gated monitor.  Both must be in the active
    # list so the verifier's DRSDT gate column is written to the CSV.
    gate_closure = " gas_appearance_equilibrium_residual_l2" if drsdt_closure else ""
    return (
        "matrix_component_balance_l2 phase_volume_constraint_l2 "
        f"{phase_closure}{gate_closure} minimum_phase_transform_dissipation "
        "tau_evolution_residual_l2 phase_transform_affinity_identity_l2 "
        "phase_transform_generalized_force_identity_l2 phase_transform_power_identity_l2 "
        "matrix_momentum_x_scaled_weak_residual_linf "
        "matrix_momentum_y_scaled_weak_residual_linf "
        "matrix_momentum_z_scaled_weak_residual_linf "
        "fluid_energy_scaled_weak_residual_linf solid_energy_scaled_weak_residual_linf "
        "average_solid_reference_jacobian minimum_solid_reference_jacobian "
        "matrix_component_storage_rate_integral average_oil_pressure "
        "average_water_saturation average_gas_saturation minimum_gas_saturation "
        "maximum_gas_saturation average_solution_gas_oil_ratio average_tau "
        "average_reconstructed_tau average_phase_transform_dissolved_mu "
        "average_phase_transform_free_mu average_phase_transform_affinity "
        "average_phase_transform_generalized_force "
        "average_gas_phase_transformation_rate average_fluid_temperature "
        "average_solid_temperature water_storage_rate_integral "
        "oil_storage_rate_integral gas_storage_rate_integral water_source_integral "
        "oil_source_integral gas_source_integral water_global_balance "
        "oil_global_balance gas_global_balance injector_gas_surface_rate "
        "injector_cell_pressure producer_cell_pressure injector_water_surface_rate "
        "injector_oil_surface_rate producer_oil_surface_rate "
        "producer_water_surface_rate producer_gas_surface_rate field_gas_oil_ratio "
        "injected_gas_surface_rate injected_gas_surface_volume "
        "produced_oil_surface_volume produced_gas_surface_volume "
        "produced_water_surface_volume injector_gas_surface_productivity "
        "producer_oil_surface_productivity injector_bhp producer_bhp "
        "gas_active_set_mismatch_integral"
    )
def active_well_overrides(drsdt_closure: bool) -> tuple[str, ...]:
    """Active-wells override tuple for the selected phase-transfer closure."""
    return (
        "Variables/inactive=",
        "ICs/inactive=",
        "Materials/inactive=",
        "Materials/inactive_well_sources/block=1 2 3",
        "ScalarKernels/active=injector_control producer_control",
        f"Postprocessors/active={active_well_postprocessors(drsdt_closure)}",
    )
INJECTOR_TARGET_RATE = 32.774128
PRODUCER_TARGET_OIL_RATE = 0.03680261456666667
WELL_RATE_RELATIVE_TOLERANCE = 1.0e-4
INJECTOR_MAXIMUM_BHP = 62149342.24061635
PRODUCER_MINIMUM_BHP = 6894757.293168


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def resolved_input_paths() -> list[Path]:
    """Return the parent deck and its complete, recursively resolved include closure."""
    pending = [DECK.resolve()]
    paths: set[Path] = set()
    while pending:
        path = pending.pop()
        if path in paths:
            continue
        if not path.is_file():
            raise SystemExit(f"SPE1 input dependency is missing: {path}")
        try:
            path.relative_to(ROOT)
        except ValueError as error:
            raise SystemExit(f"SPE1 input dependency is outside the repository: {path}") from error
        paths.add(path)
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            stripped = line.strip()
            if not stripped.startswith("!include"):
                continue
            arguments = shlex.split(stripped[len("!include") :].strip())
            if len(arguments) != 1:
                raise SystemExit(
                    f"unsupported !include syntax at {path.relative_to(ROOT)}:{line_number}"
                )
            pending.append((path.parent / arguments[0]).resolve())
    return sorted(paths)


def input_tree_sha256() -> str:
    """Hash every file in the resolved SPE1 input closure by path and bytes."""
    paths = resolved_input_paths()
    digest = hashlib.sha256()
    for path in paths:
        relative = path.relative_to(ROOT).as_posix().encode("utf-8")
        digest.update(len(relative).to_bytes(8, byteorder="big"))
        digest.update(relative)
        with path.open("rb") as stream:
            for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                digest.update(chunk)
    return digest.hexdigest()


def capture_provenance() -> dict[str, object]:
    paths = resolved_input_paths()
    return {
        "deck_path": str(DECK.relative_to(ROOT)),
        "deck_sha256": sha256_file(DECK),
        "input_tree_sha256": input_tree_sha256(),
        "resolved_input_paths": [str(path.relative_to(ROOT)) for path in paths],
        "executable_path": str(APP.relative_to(ROOT)),
        "executable_sha256": sha256_file(APP),
        "verifier_path": str(VERIFIER.relative_to(ROOT)),
        "verifier_sha256": sha256_file(VERIFIER),
        "moose_patch_series_path": str(MOOSE_PATCH_SERIES.relative_to(ROOT)),
        "moose_patch_series_sha256": sha256_file(MOOSE_PATCH_SERIES),
    }


def write_json_atomic(path: Path, document: dict) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(document, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    temporary.replace(path)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mesh_group = parser.add_mutually_exclusive_group()
    mesh_group.add_argument(
        "--reduced",
        action="store_true",
        help="Use one lateral cell and all three layers for the coupled harness gate.",
    )
    mesh_group.add_argument(
        "--lateral-cells",
        type=int,
        help="Use an n by n lateral mesh over the fixed domain for convergence studies.",
    )
    parser.add_argument(
        "--mpi-ranks",
        type=int,
        default=1,
        help="Number of MPI ranks used for the MOOSE solve (default: 1).",
    )
    parser.add_argument(
        "--active-wells",
        action="store_true",
        help="Activate the one-day injector and producer rate/BHP controls.",
    )
    parser.add_argument(
        "--dt-seconds",
        type=float,
        help="Override the nominal timestep without changing the production deck.",
    )
    parser.add_argument(
        "--phase-transfer-mobility",
        type=float,
        help=(
            "Override the oil--gas transfer mobility for a separately labeled "
            "sensitivity diagnostic."
        ),
    )
    parser.add_argument(
        "--phase-transform-chemical-stiffness",
        type=float,
        help=(
            "Override the synthetic phase-transform free-energy curvature for a "
            "separately labeled sensitivity diagnostic."
        ),
    )
    parser.add_argument(
        "--drsdt-closure",
        action="store_true",
        help=(
            "Select the rate-independent DRSDT=0 history closure for the "
            "phase-transfer rate by deactivating the finite-rate kinetic row. "
            "The gate then monitors the direct equilibrium phase-appearance "
            "residual (gas_appearance_equilibrium_residual_l2) in place of the "
            "kinetic residual."
        ),
    )
    parser.add_argument(
        "--artifacts-dir",
        type=Path,
        help=(
            "Preserve result.csv, solver.log, command.txt, provenance.json, and "
            "the verified summary JSON instead of using temporary output."
        ),
    )
    args = parser.parse_args()
    if args.mpi_ranks < 1:
        parser.error("--mpi-ranks must be positive")
    if args.lateral_cells is not None and args.lateral_cells < 1:
        parser.error("--lateral-cells must be positive")
    if args.dt_seconds is not None and args.dt_seconds <= 0.0:
        parser.error("--dt-seconds must be positive")
    if args.phase_transfer_mobility is not None and args.phase_transfer_mobility <= 0.0:
        parser.error("--phase-transfer-mobility must be positive")
    if (
        args.phase_transform_chemical_stiffness is not None
        and args.phase_transform_chemical_stiffness <= 0.0
    ):
        parser.error("--phase-transform-chemical-stiffness must be positive")
    lateral_cells = 1 if args.reduced else (args.lateral_cells or 10)
    mesh_variant = f"{lateral_cells}x{lateral_cells}x3_cells_{6 * lateral_cells**2 * 3}_tet10"
    # The DRSDT=0 closure replaces the finite-rate kinetic row; the governing
    # residual for the phase-transfer rate becomes the rate-independent direct
    # equilibrium constraint A_(m) = 0 on the active phase set with the
    # phase-transfer rate r_(m) as the multiplier returned by the component
    # balance.  Active cells drive the DRSDT-capped stability gap to zero;
    # inactive cells drive r itself to zero.  Swap the monitored postprocessor
    # and its limit accordingly so the gate asserts the selected formulation.
    # The bare solution-gas-constraint residual is intentionally NOT gated in
    # DRSDT mode: it is nonzero on undersaturated branches (gap > 0), where the
    # equilibrium constraint correctly holds r = 0.
    phase_closure_postprocessor = (
        "gas_appearance_equilibrium_residual_l2"
        if args.drsdt_closure
        else "phase_transform_kinetic_residual_l2"
    )
    phase_closure_limit = 1.0e-7
    absolute_limits = dict(ABSOLUTE_LIMITS)
    absolute_limits[phase_closure_postprocessor] = phase_closure_limit
    absolute_limits.pop(
        "phase_transform_solution_gas_constraint_l2"
        if not args.drsdt_closure
        else "phase_transform_kinetic_residual_l2",
        None,
    )
    parameter_overrides = {
        name: value
        for name, value in {
            "phase_transfer_mobility": args.phase_transfer_mobility,
            "phase_transform_chemical_stiffness": args.phase_transform_chemical_stiffness,
            "drsdt_closure": args.drsdt_closure,
        }.items()
        if value is not None and value is not False
    }
    if not APP.exists():
        raise SystemExit(f"missing optimized executable: {APP}")
    if args.artifacts_dir:
        args.artifacts_dir = args.artifacts_dir.resolve()
        if args.artifacts_dir.exists() and any(args.artifacts_dir.iterdir()):
            raise SystemExit(
                "--artifacts-dir must be new or empty; refusing to reuse evidence: "
                f"{args.artifacts_dir}"
            )

    if args.artifacts_dir:
        args.artifacts_dir.mkdir(parents=True, exist_ok=True)
        run_context = nullcontext(str(args.artifacts_dir))
    else:
        run_context = tempfile.TemporaryDirectory(prefix="spe1_q2_eg_phase_appearance_")

    with run_context as tmp:
        output_base = Path(tmp) / "result"
        log_path = Path(tmp) / "solver.log"
        provenance_path = Path(tmp) / "provenance.json"
        provenance = {"before": capture_provenance()}
        write_json_atomic(provenance_path, provenance)
        summary_path = Path(tmp) / "verification_summary.json"
        write_json_atomic(
            summary_path,
            {
                "benchmark": "SPE1 Case 1",
                "status": "running",
                "provenance": provenance["before"],
                "parameter_overrides": parameter_overrides,
            },
        )
        command = [
            str(APP),
            "-i",
            str(DECK),
            f"Outputs/file_base={output_base}",
        ]
        if args.drsdt_closure:
            # The production deck defaults to the finite-rate kinetic row.
            # Selecting the DRSDT=0 closure deactivates that row; the
            # rate-independent direct equilibrium constraint A_(m) = 0 then
            # governs the same element-local phase-transfer rate unknown.
            command.append("Kernels/inactive=gas_phase_transformation_closure")
            # Lagged active-set (Picard) closure, standard in reservoir
            # simulation.  The [spe1_pvt] material freezes the phase-appearance
            # branch at the previous fixed-point state (see
            # active_set_flag_variable / active_set_flag_enrichment_variable in
            # the deck), so the active set cannot flip inside the inner Newton
            # solve and stall the Jacobian at the gas-front transition.  The
            # FixedPointSolve outer loop below refreshes the flag between
            # Picard iterations and converges when the active-set mismatch
            # integral (gas_active_set_mismatch_integral) falls below
            # custom_abs_tol.  disable_fixed_point_residual_norm_check skips
            # the main-app residual-norm checks, which are meaningless without
            # MultiApps.  Backtracking (bt) line search breaks the default
            # RSLS/L2 period-2/4 residual cycle at the step-2 gas-front
            # active-set transition.
            command.append("Executioner/line_search=bt")
            command.append("Executioner/fixed_point_algorithm=picard")
            # Two outer solves refresh a stale flag once; three leaves one
            # headroom iteration before a timestep cutback.
            command.append("Executioner/fixed_point_max_its=3")
            command.append("Executioner/disable_fixed_point_residual_norm_check=true")
            command.append("Executioner/custom_pp=gas_active_set_mismatch_integral")
            # With direct_pp_value=true the convergence object tests
            # |mismatch - 0| < custom_abs_tol (the mismatch is a strict 0/1
            # volume integral, so any remaining mismatched cell is O(cell
            # volume) and cleanly exceeds 1e-6).  The difference-based default
            # would instead compare against the previous timestep's mismatch,
            # which never relaxes when a flag transition occurs.
            command.append("Executioner/direct_pp_value=true")
            command.append("Executioner/custom_abs_tol=1e-6")
            # Keep the production deck's strict nl_abs_tol=1e-8 for the inner
            # solve.  Relaxing it (e.g. to 1e-6) stops the coupled Newton
            # before the gas component balance closes: a reduced run then
            # violates gas_global_balance by ~1.3e3 kg/s while the lagged
            # active-set gate still reads converged.  The DRSDT gate quantity
            # (gas_appearance_equilibrium_residual_l2) is enforced separately
            # by custom_abs_tol above.
            # The injected gas splits between the dissolved (R_s) and free-gas
            # rows according to the undersaturation gap in
            # ADBlackOilPeacemanWellMaterial (see
            # saturated_solution_gas_oil_ratio_name).  This partition keeps the
            # injector's hard mass source from stalling the frozen-inactive
            # free-gas rows of the first DRSDT solve and is scoped to this gate
            # so the finite-rate kinetic acceptance path keeps its baseline
            # behavior.
            command.append(
                "Materials/injector/saturated_solution_gas_oil_ratio_name="
                "benchmark_black_oil_saturated_solution_gas_oil_ratio"
            )
        # The first physical step from the initial condition must complete the
        # quadratic-Bernstein/saturation active-set transition, which
        # reproducibly needs ~41 Newton iterations regardless of dt.  The
        # production deck's nl_max_its=40 is deliberate for the dt=10800
        # production schedule and leaves no headroom for run-to-run
        # nondeterminism in the threaded LU factorization.  Mirror the
        # acceptance runner's equilibration-stage headroom (EQUILIBRATION_MAX_ITS
        # in run_spe1_phase_transforming_acceptance.py) so step 1 converges
        # without the schedule-shifting cutback that drops the 86400 s gate.
        command.append("Executioner/nl_max_its=60")
        if args.mpi_ranks > 1:
            command = ["mpiexec", "-n", str(args.mpi_ranks), *command]
        if lateral_cells != 10:
            command.extend(lateral_mesh_overrides(lateral_cells))
        if lateral_cells == 1:
            command.extend(reduced_material_overrides())
        if args.active_wells:
            command.extend(active_well_overrides(args.drsdt_closure))
        if args.dt_seconds is not None:
            command.append(f"Executioner/dt={args.dt_seconds:.17g}")
            command.append(
                "Executioner/num_steps="
                f"{2 * math.ceil(EXPECTED_END_TIME / args.dt_seconds) + 4}"
            )
        if args.phase_transfer_mobility is not None:
            command.append(
                "Materials/spe1_phase_transfer/kinetic_mobilities="
                f"{args.phase_transfer_mobility:.17g}"
            )
        if args.phase_transform_chemical_stiffness is not None:
            command.append(
                "Materials/spe1_phase_transform_mu/chemical_stiffness="
                f"{args.phase_transform_chemical_stiffness:.17g}"
            )
        if lateral_cells == 1 and args.active_wells:
            command.append("Materials/inactive_well_sources/block=2")
        if args.artifacts_dir:
            (args.artifacts_dir / "command.txt").write_text(
                shlex.join(command) + "\n", encoding="utf-8"
            )
        try:
            # Stream directly to the durable log. A pipe can remain open when
            # an MPI descendant exits abnormally and leave the Python wrapper
            # blocked after the visible solver processes disappear.
            with log_path.open("w", encoding="utf-8") as log_stream:
                process = subprocess.Popen(
                    command,
                    cwd=APP_DIR,
                    stdout=log_stream,
                    stderr=subprocess.STDOUT,
                    text=True,
                    start_new_session=True,
                )
                try:
                    returncode = process.wait(
                        timeout=REDUCED_TIMEOUT_SECONDS if lateral_cells == 1 else FULL_TIMEOUT_SECONDS
                    )
                except (subprocess.TimeoutExpired, KeyboardInterrupt):
                    os.killpg(process.pid, signal.SIGTERM)
                    try:
                        process.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        os.killpg(process.pid, signal.SIGKILL)
                        process.wait()
                    raise
        except subprocess.TimeoutExpired as error:
            provenance["after"] = capture_provenance()
            provenance["unchanged_during_run"] = provenance["before"] == provenance["after"]
            write_json_atomic(provenance_path, provenance)
            write_json_atomic(
                summary_path,
                {
                    "benchmark": "SPE1 Case 1",
                    "status": "fail",
                    "failure_kind": "solver_timeout",
                    "timeout_seconds": (
                        REDUCED_TIMEOUT_SECONDS if lateral_cells == 1 else FULL_TIMEOUT_SECONDS
                    ),
                    "provenance": provenance,
                    "parameter_overrides": parameter_overrides,
                },
            )
            output = log_path.read_text(encoding="utf-8", errors="replace")
            raise SystemExit(
                "SPE1 Q2/CG-EG phase-appearance solve timed out:\n" + output[-4000:]
            ) from error
        provenance["after"] = capture_provenance()
        provenance["unchanged_during_run"] = provenance["before"] == provenance["after"]
        write_json_atomic(provenance_path, provenance)
        if not provenance["unchanged_during_run"]:
            write_json_atomic(
                summary_path,
                {
                    "benchmark": "SPE1 Case 1",
                    "status": "fail",
                    "failure_kind": "provenance_changed_during_run",
                    "provenance": provenance,
                    "parameter_overrides": parameter_overrides,
                },
            )
            raise SystemExit(
                "SPE1 deck, reusable input tree, or executable changed during the run; "
                f"artifact provenance is invalid: {provenance_path}"
            )
        if returncode:
            write_json_atomic(
                summary_path,
                {
                    "benchmark": "SPE1 Case 1",
                    "status": "fail",
                    "failure_kind": "solver_nonzero_exit",
                    "returncode": returncode,
                    "provenance": provenance,
                    "parameter_overrides": parameter_overrides,
                },
            )
            output = log_path.read_text(encoding="utf-8", errors="replace")
            raise SystemExit(
                "SPE1 Q2/CG-EG phase-appearance solve failed:\n"
                + output[-4000:]
            )
        csv_path = Path(str(output_base) + ".csv")
        if not csv_path.exists():
            raise SystemExit("SPE1 Q2/CG-EG phase-appearance solve produced no CSV")
        with csv_path.open(newline="") as handle:
            rows = list(csv.DictReader(handle))
        log_text = log_path.read_text(encoding="utf-8", errors="replace")

    if not rows:
        raise SystemExit("SPE1 Q2/CG-EG phase-appearance CSV is empty")
    final = {name: float(value) for name, value in rows[-1].items()}
    lowered_log = log_text.lower()
    solver_events = {
        "rejected_or_nonconverged_step_count": (
            lowered_log.count("nonlinear solve did not converge")
            + lowered_log.count("rejecting time step")
            + lowered_log.count("solve failed, cutting timestep")
        ),
        "factor_outmemory_count": lowered_log.count("factor_outmemory"),
        "contains_nan_or_infinity": bool(
            re.search(r"(?<![a-z])nan(?![a-z])|\binfinite\b", lowered_log)
        ),
    }
    required = tuple(absolute_limits) + (
        "time",
        "minimum_gas_saturation",
        "maximum_gas_saturation",
        "minimum_phase_transform_dissipation",
        "minimum_solid_reference_jacobian",
        "average_fluid_temperature",
        "average_solid_temperature",
    )
    if args.active_wells:
        required += (
            "injected_gas_surface_rate",
            "producer_oil_surface_rate",
            "injector_bhp",
            "producer_bhp",
        )
    missing = [name for name in required if name not in final]
    if missing:
        raise SystemExit("SPE1 Q2/CG-EG phase-appearance CSV omitted: " + ", ".join(missing))

    failures = []
    if solver_events["rejected_or_nonconverged_step_count"]:
        failures.append(
            "rejected_or_nonconverged_step_count="
            f"{solver_events['rejected_or_nonconverged_step_count']} > 0"
        )
    if solver_events["factor_outmemory_count"]:
        failures.append(
            f"factor_outmemory_count={solver_events['factor_outmemory_count']} > 0"
        )
    if solver_events["contains_nan_or_infinity"]:
        failures.append("solver log contains NaN or infinity")
    for name in required:
        if not math.isfinite(final[name]):
            failures.append(f"{name} is not finite")
    for name, limit in absolute_limits.items():
        if math.isfinite(final[name]) and abs(final[name]) > limit:
            failures.append(f"abs({name})={abs(final[name]):.6e} > {limit:.1e}")
    if abs(final["time"] - EXPECTED_END_TIME) > 1.0e-8:
        failures.append(
            f"time={final['time']:.12e} does not reach {EXPECTED_END_TIME:.12e}"
        )
    if final["minimum_gas_saturation"] < MINIMUM_GAS_SATURATION:
        failures.append(
            "minimum_gas_saturation="
            f"{final['minimum_gas_saturation']:.6e} < {MINIMUM_GAS_SATURATION:.1e}"
        )
    if final["maximum_gas_saturation"] > MAXIMUM_GAS_SATURATION:
        failures.append(
            "maximum_gas_saturation="
            f"{final['maximum_gas_saturation']:.6e} > {MAXIMUM_GAS_SATURATION:.1e}"
        )
    if final["minimum_phase_transform_dissipation"] < MINIMUM_PHASE_TRANSFORM_DISSIPATION:
        failures.append(
            "minimum_phase_transform_dissipation="
            f"{final['minimum_phase_transform_dissipation']:.6e} "
            f"< {MINIMUM_PHASE_TRANSFORM_DISSIPATION:.1e}"
        )
    if final["minimum_solid_reference_jacobian"] <= MINIMUM_SOLID_REFERENCE_JACOBIAN:
        failures.append(
            "minimum_solid_reference_jacobian="
            f"{final['minimum_solid_reference_jacobian']:.6e} "
            f"<= {MINIMUM_SOLID_REFERENCE_JACOBIAN:.1e}"
        )
    for name in ("average_fluid_temperature", "average_solid_temperature"):
        if abs(final[name] - INITIAL_TEMPERATURE) > TEMPERATURE_TOLERANCE:
            failures.append(
                f"{name}={final[name]:.12e} differs from the adiabatic initial "
                f"temperature by more than {TEMPERATURE_TOLERANCE:.1e} K"
            )
    if args.active_wells:
        for name, target in (
            ("injected_gas_surface_rate", INJECTOR_TARGET_RATE),
            ("producer_oil_surface_rate", PRODUCER_TARGET_OIL_RATE),
        ):
            relative_error = abs(final[name] - target) / target
            if relative_error > WELL_RATE_RELATIVE_TOLERANCE:
                failures.append(
                    f"{name} relative target error={relative_error:.6e} > "
                    f"{WELL_RATE_RELATIVE_TOLERANCE:.1e}"
                )
        if final["injector_bhp"] > INJECTOR_MAXIMUM_BHP:
            failures.append(
                f"injector_bhp={final['injector_bhp']:.6e} > {INJECTOR_MAXIMUM_BHP:.6e}"
            )
        if final["producer_bhp"] < PRODUCER_MINIMUM_BHP:
            failures.append(
                f"producer_bhp={final['producer_bhp']:.6e} < {PRODUCER_MINIMUM_BHP:.6e}"
            )
    if failures:
        if args.artifacts_dir:
            write_json_atomic(
                args.artifacts_dir / "verification_summary.json",
                {
                    "benchmark": "SPE1 Case 1",
                    "variant": (
                        mesh_variant
                        + ("_active_wells" if args.active_wells else "_inactive_wells")
                    ),
                    "mpi_ranks": args.mpi_ranks,
                    "status": "fail",
                    "failures": failures,
                    "solver_events": solver_events,
                    "provenance": provenance["before"],
                    "parameter_overrides": parameter_overrides,
                    "limits": absolute_limits,
                    "final": final,
                },
            )
        raise SystemExit("SPE1 Q2/CG-EG phase-appearance gate failed: " + "; ".join(failures))

    if args.artifacts_dir:
        summary = {
            "benchmark": "SPE1 Case 1",
            "variant": (
                mesh_variant
                + ("_active_wells" if args.active_wells else "_inactive_wells")
            ),
            "mpi_ranks": args.mpi_ranks,
            "status": "pass",
            "provenance": provenance["before"],
            "parameter_overrides": parameter_overrides,
            "limits": absolute_limits,
            "solver_events": solver_events,
            "final": final,
        }
        write_json_atomic(args.artifacts_dir / "verification_summary.json", summary)

    print(
        "spe1_q2_eg_phase_appearance"
        + f"_{lateral_cells}x{lateral_cells}x3"
        + ("_active_wells" if args.active_wells else "")
        + ("_drsdt" if args.drsdt_closure else "")
        + ": "
        f"minimum_Sg={final['minimum_gas_saturation']:.6e}, "
        f"{phase_closure_postprocessor}={final[phase_closure_postprocessor]:.6e}, "
        f"minimum_dissipation={final['minimum_phase_transform_dissipation']:.6e}, "
        f"gas_balance={final['gas_global_balance']:.6e}, "
        f"Tf={final['average_fluid_temperature']:.6e}, "
        f"Ts={final['average_solid_temperature']:.6e}, "
        f"minimum_J={final['minimum_solid_reference_jacobian']:.6e}"
        + (
            f", qinj={final['injected_gas_surface_rate']:.6e}, "
            f"qop={final['producer_oil_surface_rate']:.6e}"
            if args.active_wells
            else ""
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
