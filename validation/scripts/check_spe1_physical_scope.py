#!/usr/bin/env python3
"""Record the physical data scope of an SPE1 finite-deformation deck.

This audit records the deck values that SPE1 supplies directly and the
constitutive, thermal, and mechanics specializations that SPE1 leaves open.
It is provenance disclosure rather than a calibration test or an acceptance
gate.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path


INCLUDE_PATTERN = re.compile(r"^\s*!include\s+(?:[\"']([^\"']+)[\"']|(\S+))")
BLOCK_PATTERN = re.compile(r"^\s*\[([^\]]+)\]\s*$")
END_BLOCK_PATTERN = re.compile(r"^\s*\[\]\s*$")
ASSIGNMENT_PATTERN = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*(?::=|=)\s*(.*?)\s*$")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def resolved_input_files(deck: Path) -> list[Path]:
    """Return the recursive include closure for a MOOSE input deck."""
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


def parse_blocks(paths: list[Path]) -> dict[str, list[dict[str, object]]]:
    """Return simple named MOOSE blocks and their direct assignments."""
    blocks: dict[str, list[dict[str, object]]] = {}
    for path in paths:
        current: dict[str, object] | None = None
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if END_BLOCK_PATTERN.match(line):
                current = None
                continue
            block_match = BLOCK_PATTERN.match(line)
            if block_match:
                current = {
                    "path": path,
                    "line": line_number,
                    "values": {},
                    "value_lines": {},
                }
                blocks.setdefault(block_match.group(1), []).append(current)
                continue
            if current is None:
                continue
            assignment = ASSIGNMENT_PATTERN.match(line.split("#", maxsplit=1)[0])
            if assignment:
                name, value = assignment.groups()
                current["values"][name] = value.strip()
                current["value_lines"][name] = line_number
    return blocks


def parameter(
    blocks: dict[str, list[dict[str, object]]], root: Path, block: str, name: str
) -> dict[str, object]:
    candidates = blocks.get(block, [])
    for candidate in candidates:
        values = candidate["values"]
        if name in values:
            path = candidate["path"]
            return {
                "value": values[name],
                "source": str(path.relative_to(root)),
                "line": candidate["value_lines"][name],
            }
    raise ValueError(f"Missing required parameter {block}/{name} in the resolved deck")


def block_values(
    blocks: dict[str, list[dict[str, object]]], root: Path, block: str, names: tuple[str, ...]
) -> dict[str, object]:
    return {name: parameter(blocks, root, block, name) for name in names}


def write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    temporary.replace(path)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--deck", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--repository-root", type=Path)
    args = parser.parse_args()

    root = (args.repository_root or Path(__file__).resolve().parents[2]).resolve()
    deck = args.deck.resolve()
    if not deck.is_relative_to(root):
        parser.error("--deck must be inside --repository-root")
    input_files = resolved_input_files(deck)
    blocks = parse_blocks(input_files)
    opm_reference = root / "validation/reference_data/spe1_case1_opm_flow_2021_10.csv"
    if not opm_reference.is_file():
        raise FileNotFoundError(f"Pinned OPM reference is missing: {opm_reference}")
    opm_columns = opm_reference.read_text(encoding="utf-8").splitlines()[0].split(",")

    pvt_file = root / "moose_app/input/includes/materials/spe1_case1_black_oil_pvt.i"
    solid_mass_file = root / "moose_app/input/includes/materials/solid_phase_mass_volume.i"
    for required_input in (pvt_file, solid_mass_file):
        if required_input.resolve() not in input_files:
            raise ValueError(
                "The SPE1 physical-scope audit requires the resolved input closure to contain "
                f"{required_input.relative_to(root)}"
            )
    data = {
        "audit": "SPE1 physical-model scope",
        "audit_role": "provenance disclosure; not a calibration test or acceptance gate",
        "status": "declared_with_unconstrained_specializations",
        "deck": str(deck.relative_to(root)),
        "resolved_input_paths": [str(path.relative_to(root)) for path in input_files],
        "source_data": {
            "black_oil_pvt_and_saturation_tables": {
                "status": "SPE1 datum",
                "source": str(pvt_file.relative_to(root)),
                "sha256": sha256_file(pvt_file),
            },
            "pinned_opm_observables": {
                "status": "comparison datum",
                "source": str(opm_reference.relative_to(root)),
                "sha256": sha256_file(opm_reference),
                "columns": opm_columns,
            },
        },
        "unconstrained_specializations": {
            "phase_transfer_thermodynamic_embedding": {
                "status": "explicit, uncalibrated benchmark specialization",
                "parameters": {
                    "chemical_stiffness": parameter(
                        blocks, root, "spe1_phase_transform_mu", "chemical_stiffness"
                    ),
                    "reference_thermodynamics": parameter(
                        blocks, root, "phase_transform_reference_thermodynamics", "prop_values"
                    ),
                },
                "physical_implication": (
                    "The PVT tables constrain attainable dissolved gas, while this embedding "
                    "supplies the chemical-potential scale and reference datum."
                ),
            },
            "phase_transfer_kinetics": {
                "status": "explicit, uncalibrated benchmark specialization",
                "parameters": block_values(
                    blocks,
                    root,
                    "spe1_phase_transfer",
                    ("kinetic_mobilities", "forward_phase_active_names", "reverse_phase_active_names"),
                ),
                "physical_implication": (
                    "SPE1 has no phase-transfer resistance datum, so the finite-rate "
                    "relaxation rate is not calibrated by its input tables."
                ),
            },
            "thermal_model": {
                "status": "explicit, uncalibrated benchmark specialization",
                "parameters": {
                    "storage": parameter(
                        blocks, root, "phase_transform_reference_thermodynamics", "prop_values"
                    ),
                    "fluid_heat_flux": block_values(
                        blocks, root, "fluid_heat_flux", ("diffusivity", "mobility_name")
                    ),
                    "solid_heat_flux": block_values(
                        blocks, root, "solid_heat_flux", ("diffusivity", "mobility_name")
                    ),
                    "fluid_solid_exchange": parameter(
                        blocks, root, "fluid_solid_energy_exchange", "expression"
                    ),
                },
                "physical_implication": (
                    "The production residual includes two energy equations, but SPE1 supplies "
                    "neither thermal calibration nor a thermal comparison observable."
                ),
            },
            "solid_constitutive_response": {
                "status": "explicit, uncalibrated benchmark specialization",
                "parameters": {
                    "effective_stress": block_values(
                        blocks, root, "matrix_effective_stress", ("shear_modulus", "lame_lambda")
                    ),
                    "grain_density": parameter(
                        blocks, root, "matrix_mass_and_volume", "solid_intrinsic_density"
                    ),
                    "rock_compressibility": parameter(blocks, root, "spe1_pvt", "rock_compressibility"),
                    "pressure_dependent_rock_porosity": parameter(
                        blocks, root, "spe1_pvt", "use_pressure_dependent_rock_porosity"
                    ),
                    "solid_mass_source": str(solid_mass_file.relative_to(root)),
                },
                "physical_implication": (
                    "SPE1 ROCK data set the bulk response, while shear response, grain density, "
                    "and this finite-deformation specialization require independent justification."
                ),
            },
            "mechanical_boundary_and_reference_state": {
                "status": "explicit, uncalibrated benchmark specialization",
                "parameters": {
                    "reference_prestress": block_values(
                        blocks, root, "matrix_reference_prestress", ("tensor_functions",)
                    ),
                    "geostatic_prestress": block_values(
                        blocks, root, "geostatic_prestress_zz", ("x", "y")
                    ),
                    "rigid_body_constraints": {
                        name: block_values(blocks, root, name, ("variable", "boundary", "value"))
                        for name in ("matrix_pin_x", "matrix_pin_y", "matrix_bottom_normal_support")
                    },
                },
                "physical_implication": (
                    "The reference stress and supports make the deformable initial state admissible; "
                    "SPE1 provides no stress, displacement, or compaction observation to choose them."
                ),
            },
        },
        "interpretation_limits": [
            "Passing the coupled residual, conservation, and thermodynamic-identity gates verifies the selected model path.",
            "Matching OPM rate, pressure, saturation, and cumulative observables does not calibrate unobserved thermal or mechanics quantities.",
            "Phase-transfer curvature and mobility require a sensitivity study or independent constitutive evidence before their values are interpreted as SPE1 predictions.",
        ],
    }
    write_json(args.output.resolve(), data)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
