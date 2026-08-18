#!/usr/bin/env python3
"""Inventory, lock, assemble, and validate reusable MOOSE input fragments."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import sys
from typing import Any, Iterable

import yaml


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CATALOG = ROOT / "moose_app/input/fragment_catalog.yml"
DEFAULT_REGISTRY = ROOT / "moose_app/input/verified_block_registry.yml"
DEFAULT_SCHEMA = ROOT / "agent_workflows/schemas/problem_spec.schema.json"
LOCKED_ROOT_RELATIVE = Path("agent_environment/verified-input-blocks")
DEFAULT_LOCKED_ROOT = ROOT / LOCKED_ROOT_RELATIVE

OBJECT_SECTIONS = {
    "AuxKernels",
    "AuxVariables",
    "BCs",
    "Controls",
    "DGKernels",
    "FVKernels",
    "Functions",
    "ICs",
    "Kernels",
    "Materials",
    "MultiApps",
    "Postprocessors",
    "ScalarKernels",
    "Transfers",
    "UserObjects",
    "Variables",
    "VectorPostprocessors",
}
PROTECTED_SECTIONS = {
    "AuxKernels",
    "DGKernels",
    "FVKernels",
    "Kernels",
    "Materials",
    "ScalarKernels",
    "UserObjects",
}
INCLUDE_RE = re.compile(r"^\s*!include\s+(?P<path>\S+)\s*(?:#.*)?$")
BLOCK_RE = re.compile(r"^\s*\[(?P<token>[^]]*)\]\s*(?:#.*)?$")
TYPE_RE = re.compile(r"^\s*type\s*=\s*['\"]?(?P<type>[^\s'\"#]+)")
PARAMETER_KEY_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
SEMVER_RE = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")
BLOCK_ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]*$")


class WorkflowError(RuntimeError):
    """A user-correctable verified-block workflow error."""


def relative_to_root(path: Path) -> str:
    try:
        return path.resolve().relative_to(ROOT.resolve()).as_posix()
    except ValueError as error:
        raise WorkflowError(f"path is outside the repository: {path}") from error


def resolve_repo_path(value: str | Path) -> Path:
    path = Path(value)
    if not path.is_absolute():
        path = ROOT / path
    path = path.resolve()
    relative_to_root(path)
    return path


def load_yaml(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise WorkflowError(f"missing YAML file: {relative_to_root(path)}")
    with path.open("r", encoding="utf-8") as stream:
        document = yaml.safe_load(stream)
    if not isinstance(document, dict):
        raise WorkflowError(f"expected a YAML mapping: {relative_to_root(path)}")
    return document


def write_yaml(path: Path, document: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    rendered = yaml.safe_dump(document, sort_keys=False, width=100)
    path.write_text(rendered, encoding="utf-8")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def parse_input_objects(path: Path) -> list[dict[str, Any]]:
    """Extract named MOOSE objects from the first nesting level of known sections."""
    lines = path.read_text(encoding="utf-8").splitlines()
    stack: list[tuple[str, int]] = []
    active: dict[str, Any] | None = None
    objects: list[dict[str, Any]] = []

    def finish(end_line: int) -> None:
        nonlocal active
        if active is None:
            return
        active["end_line"] = end_line
        content = "\n".join(lines[active["start_line"] - 1 : end_line]) + "\n"
        active["sha256"] = sha256_text(content)
        objects.append(active)
        active = None

    for line_number, line in enumerate(lines, start=1):
        match = BLOCK_RE.match(line)
        if match:
            token = match.group("token").strip()
            if token == "":
                if len(stack) == 2 and stack[0][0] in OBJECT_SECTIONS:
                    finish(line_number)
                if stack:
                    stack.pop()
                continue
            if token == "../":
                if len(stack) == 2 and stack[0][0] in OBJECT_SECTIONS:
                    finish(line_number)
                if stack:
                    stack.pop()
                continue
            if token.startswith("./"):
                token = token[2:]
            if not stack:
                stack.append((token, line_number))
            else:
                stack.append((token, line_number))
                if len(stack) == 2 and stack[0][0] in OBJECT_SECTIONS:
                    active = {
                        "section": stack[0][0],
                        "name": token,
                        "start_line": line_number,
                    }
            continue
        if active is not None and "type" not in active:
            type_match = TYPE_RE.match(line)
            if type_match:
                active["type"] = type_match.group("type")

    if active is not None:
        finish(len(lines))
    return objects


def catalog_context(catalog_path: Path) -> tuple[dict[str, Any], Path, list[dict[str, Any]]]:
    catalog = load_yaml(catalog_path)
    include_root = resolve_repo_path(catalog.get("include_root", ""))
    fragments = catalog.get("fragments")
    if not isinstance(fragments, list):
        raise WorkflowError("fragment catalog must contain a fragments list")
    return catalog, include_root, fragments


def catalog_index(catalog_path: Path) -> tuple[dict[str, Any], Path, dict[str, dict[str, Any]]]:
    catalog, include_root, fragments = catalog_context(catalog_path)
    index: dict[str, dict[str, Any]] = {}
    paths: set[str] = set()
    for fragment in fragments:
        if not isinstance(fragment, dict):
            raise WorkflowError("each catalog fragment must be a mapping")
        block_id = fragment.get("id")
        path = fragment.get("path")
        if not isinstance(block_id, str) or not block_id:
            raise WorkflowError("catalog fragment is missing a nonempty id")
        if block_id in index:
            raise WorkflowError(f"duplicate catalog fragment id: {block_id}")
        if not isinstance(path, str) or not path:
            raise WorkflowError(f"catalog fragment {block_id} is missing a path")
        if path in paths:
            raise WorkflowError(f"duplicate catalog fragment path: {path}")
        index[block_id] = fragment
        paths.add(path)
    return catalog, include_root, index


def registry_index(registry_path: Path) -> tuple[dict[str, Any], dict[str, dict[str, Any]]]:
    registry = load_yaml(registry_path)
    blocks = registry.get("blocks")
    if not isinstance(blocks, list):
        raise WorkflowError("verified block registry must contain a blocks list")
    index: dict[str, dict[str, Any]] = {}
    for block in blocks:
        if not isinstance(block, dict) or not isinstance(block.get("id"), str):
            raise WorkflowError("registry block is missing an id")
        if block["id"] in index:
            raise WorkflowError(f"duplicate registry block id: {block['id']}")
        index[block["id"]] = block
    return registry, index


def object_records(block_id: str, path: Path) -> list[dict[str, Any]]:
    records = []
    for item in parse_input_objects(path):
        record = {
            "id": f"{block_id}::{item['section']}/{item['name']}",
            "section": item["section"],
            "name": item["name"],
            "start_line": item["start_line"],
            "end_line": item["end_line"],
            "sha256": item["sha256"],
        }
        if "type" in item:
            record["type"] = item["type"]
        records.append(record)
    return records


def make_candidate(fragment: dict[str, Any], include_root: Path) -> dict[str, Any]:
    block_id = fragment["id"]
    path = include_root / fragment["path"]
    if not path.is_file():
        raise WorkflowError(f"catalog fragment does not exist: {relative_to_root(path)}")
    record: dict[str, Any] = {
        "id": block_id,
        "version": "0.1.0-candidate",
        "status": "candidate",
        "path": fragment["path"],
        "sha256": sha256_file(path),
        "objects": object_records(block_id, path),
    }
    for key in ("dimension", "requires", "provides"):
        if key in fragment:
            record[key] = fragment[key]
    record["verification"] = []
    return record


def sync_candidates(catalog_path: Path, registry_path: Path) -> dict[str, int]:
    catalog, include_root, catalog_by_id = catalog_index(catalog_path)
    disk_paths = {
        path.relative_to(include_root).as_posix()
        for path in include_root.rglob("*.i")
        if path.is_file()
    }
    catalog_paths = {fragment["path"] for fragment in catalog_by_id.values()}
    uncataloged = sorted(disk_paths - catalog_paths)
    missing = sorted(catalog_paths - disk_paths)
    if uncataloged or missing:
        details = []
        if uncataloged:
            details.append("uncataloged fragments: " + ", ".join(uncataloged))
        if missing:
            details.append("missing catalog paths: " + ", ".join(missing))
        raise WorkflowError("; ".join(details))

    existing: dict[str, dict[str, Any]] = {}
    registry: dict[str, Any]
    if registry_path.exists():
        registry, existing = registry_index(registry_path)
    else:
        registry = {
            "schema_version": 1,
            "hash_algorithm": "sha256",
            "canonicalization": "exact_bytes",
            "catalog": relative_to_root(catalog_path),
            "include_root": relative_to_root(include_root),
            "locked_root": LOCKED_ROOT_RELATIVE.as_posix(),
            "protected_sections": sorted(PROTECTED_SECTIONS),
            "blocks": [],
        }
    registry["locked_root"] = LOCKED_ROOT_RELATIVE.as_posix()

    unknown = sorted(set(existing) - set(catalog_by_id))
    if unknown:
        raise WorkflowError("registry contains blocks absent from catalog: " + ", ".join(unknown))

    blocks = []
    updated = 0
    preserved = 0
    for block_id, fragment in catalog_by_id.items():
        prior = existing.get(block_id)
        if prior and prior.get("status") == "verified":
            blocks.append(prior)
            preserved += 1
        else:
            blocks.append(make_candidate(fragment, include_root))
            updated += 1
    registry = {
        "schema_version": registry.get("schema_version", 1),
        "hash_algorithm": registry.get("hash_algorithm", "sha256"),
        "canonicalization": registry.get("canonicalization", "exact_bytes"),
        "catalog": relative_to_root(catalog_path),
        "include_root": relative_to_root(include_root),
        "locked_root": LOCKED_ROOT_RELATIVE.as_posix(),
        "protected_sections": sorted(PROTECTED_SECTIONS),
        "blocks": blocks,
    }
    write_yaml(registry_path, registry)
    return {"candidate_records_updated": updated, "verified_records_preserved": preserved}


def evidence_exists(evidence: dict[str, Any]) -> bool:
    reference = evidence.get("reference")
    if not isinstance(reference, str) or not reference:
        return False
    path_text, separator, selector = reference.partition("::")
    path = resolve_repo_path(path_text)
    if not path.is_file():
        return False
    if separator and selector:
        return selector in path.read_text(encoding="utf-8")
    return True


def validate_registry(catalog_path: Path, registry_path: Path) -> list[str]:
    errors: list[str] = []
    try:
        _, include_root, catalog_by_id = catalog_index(catalog_path)
        registry, registry_by_id = registry_index(registry_path)
        locked_root = resolve_repo_path(registry.get("locked_root", ""))
    except WorkflowError as error:
        return [str(error)]

    if registry.get("hash_algorithm") != "sha256":
        errors.append("registry hash_algorithm must be sha256")
    if registry.get("canonicalization") != "exact_bytes":
        errors.append("registry canonicalization must be exact_bytes")
    if registry.get("locked_root") != LOCKED_ROOT_RELATIVE.as_posix():
        errors.append(
            f"registry locked_root must be {LOCKED_ROOT_RELATIVE.as_posix()}"
        )
    if set(registry_by_id) != set(catalog_by_id):
        missing = sorted(set(catalog_by_id) - set(registry_by_id))
        extra = sorted(set(registry_by_id) - set(catalog_by_id))
        if missing:
            errors.append("registry is missing catalog blocks: " + ", ".join(missing))
        if extra:
            errors.append("registry has unknown blocks: " + ", ".join(extra))

    for block_id, fragment in catalog_by_id.items():
        block = registry_by_id.get(block_id)
        if block is None:
            continue
        expected_path = fragment["path"]
        if block.get("path") != expected_path:
            errors.append(f"{block_id}: registry path differs from catalog")
            continue
        source = include_root / expected_path
        if not source.is_file():
            errors.append(f"{block_id}: source file is missing")
            continue
        source_sha = sha256_file(source)
        status = block.get("status")
        object_source = source
        if status == "verified":
            expected_locked_path = f"{block_id}/{block.get('version')}.i"
            if block.get("locked_path") != expected_locked_path:
                errors.append(f"{block_id}: verified locked_path must be {expected_locked_path}")
                locked_source = None
            else:
                locked_source = (locked_root / expected_locked_path).resolve()
                try:
                    locked_source.relative_to(locked_root.resolve())
                except ValueError:
                    errors.append(f"{block_id}: locked path escapes locked_root")
                    locked_source = None
            if locked_source is None or not locked_source.is_file():
                errors.append(f"{block_id}: protected versioned payload is missing")
            else:
                locked_sha = sha256_file(locked_source)
                if block.get("sha256") != locked_sha:
                    errors.append(
                        f"{block_id}: LOCK VIOLATION in protected payload; "
                        f"expected {block.get('sha256')}, got {locked_sha}"
                    )
                if source_sha != locked_sha:
                    errors.append(
                        f"{block_id}: LOCK VIOLATION in editable include; "
                        f"protected {locked_sha}, got {source_sha}"
                    )
                object_source = locked_source
        elif block.get("sha256") != source_sha:
            errors.append(
                f"{block_id}: stale candidate; expected {block.get('sha256')}, got {source_sha}"
            )
        actual_objects = object_records(block_id, object_source)
        if block.get("objects") != actual_objects:
            errors.append(f"{block_id}: object inventory differs from source")
        if status not in {"candidate", "verified", "deprecated"}:
            errors.append(f"{block_id}: invalid status {status!r}")
        if status == "verified":
            version = block.get("version", "")
            if not isinstance(version, str) or not SEMVER_RE.fullmatch(version):
                errors.append(f"{block_id}: verified version must use MAJOR.MINOR.PATCH")
            verification = block.get("verification")
            if not isinstance(verification, list) or not verification:
                errors.append(f"{block_id}: verified block requires evidence")
            else:
                for evidence in verification:
                    if not isinstance(evidence, dict) or evidence.get("result") != "passed":
                        errors.append(f"{block_id}: each verification record must have result: passed")
                    elif not evidence_exists(evidence):
                        errors.append(f"{block_id}: verification reference is missing or selector was not found")
            promotion = block.get("promotion")
            if not isinstance(promotion, dict) or not promotion.get("authorized_by"):
                errors.append(f"{block_id}: verified block requires promotion authorization")
    return errors


def discover_inventory(
    catalog_path: Path, registry_path: Path, scan_roots: Iterable[Path]
) -> dict[str, Any]:
    _, include_root, catalog_by_id = catalog_index(catalog_path)
    _, registry_by_id = registry_index(registry_path)
    path_to_id = {fragment["path"]: block_id for block_id, fragment in catalog_by_id.items()}
    files: list[dict[str, Any]] = []
    section_counts: dict[str, int] = {}
    for scan_root in scan_roots:
        if not scan_root.exists():
            continue
        input_paths = {
            path
            for pattern in ("*.i", "*.i.template")
            for path in scan_root.rglob(pattern)
            if path.is_file()
        }
        for path in sorted(input_paths):
            objects = parse_input_objects(path)
            for item in objects:
                section_counts[item["section"]] = section_counts.get(item["section"], 0) + 1
            record: dict[str, Any] = {
                "path": relative_to_root(path),
                "sha256": sha256_file(path),
                "object_count": len(objects),
                "objects": objects,
            }
            try:
                include_path = path.resolve().relative_to(include_root.resolve()).as_posix()
            except ValueError:
                include_path = ""
            if include_path in path_to_id:
                block_id = path_to_id[include_path]
                record["registry_id"] = block_id
                record["status"] = registry_by_id.get(block_id, {}).get("status", "unregistered")
            files.append(record)
    return {
        "schema_version": 1,
        "generated_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "scan_roots": [relative_to_root(path) for path in scan_roots if path.exists()],
        "summary": {
            "files": len(files),
            "objects": sum(item["object_count"] for item in files),
            "sections": dict(sorted(section_counts.items())),
            "catalog_blocks": len(catalog_by_id),
            "registry_blocks": len(registry_by_id),
            "verified_blocks": sum(
                block.get("status") == "verified" for block in registry_by_id.values()
            ),
        },
        "files": files,
    }


def dependency_groups(requirements: Any, all_ids: set[str]) -> list[set[str]]:
    """Return exact requirements and wildcard alternative groups known to the registry."""
    groups: list[set[str]] = []
    if not isinstance(requirements, list):
        return groups
    for requirement in requirements:
        if not isinstance(requirement, str):
            continue
        if requirement in all_ids:
            groups.append({requirement})
            continue
        if requirement.endswith("_*"):
            prefix = requirement[:-1]
            alternatives = {item for item in all_ids if item.startswith(prefix)}
            if alternatives:
                groups.append(alternatives)
    return groups


def order_blocks(
    requested: list[str], registry_by_id: dict[str, dict[str, Any]], include_order: list[str]
) -> list[str]:
    selected = set(requested)
    for block_id in requested:
        groups = dependency_groups(
            registry_by_id[block_id].get("requires"), set(registry_by_id)
        )
        missing = [" or ".join(sorted(group)) for group in groups if not (group & selected)]
        if missing:
            raise WorkflowError(f"{block_id} requires selected blocks: {', '.join(missing)}")

    order_index = {name: index for index, name in enumerate(include_order)}
    dependencies = {
        block_id: set().union(
            *(group & selected for group in dependency_groups(
                registry_by_id[block_id].get("requires"), set(registry_by_id)
            ))
        )
        for block_id in requested
    }
    remaining = set(requested)
    ordered: list[str] = []
    while remaining:
        ready = [item for item in remaining if not (dependencies[item] & remaining)]
        if not ready:
            raise WorkflowError("selected blocks contain a dependency cycle")
        ready.sort(
            key=lambda item: (
                order_index.get(registry_by_id[item]["path"].split("/", 1)[0], len(order_index)),
                requested.index(item),
            )
        )
        item = ready[0]
        ordered.append(item)
        remaining.remove(item)
    return ordered


def format_parameter(value: Any) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return str(value)
    if isinstance(value, str) and "\n" not in value and "\r" not in value:
        if value.startswith("'") and value.endswith("'"):
            return value
        return f"'{value}'"
    raise WorkflowError(f"unsupported assembly parameter value: {value!r}")


def validate_problem_spec(spec_path: Path) -> dict[str, Any]:
    document = json.loads(spec_path.read_text(encoding="utf-8"))
    try:
        import jsonschema
    except ImportError as error:
        raise WorkflowError("jsonschema is required to validate problem specifications") from error
    schema = json.loads(DEFAULT_SCHEMA.read_text(encoding="utf-8"))
    try:
        jsonschema.validate(document, schema)
    except jsonschema.ValidationError as error:
        location = "/".join(str(item) for item in error.absolute_path)
        raise WorkflowError(f"invalid problem specification at {location or '<root>'}: {error.message}") from error
    return document


def direct_protected_objects(path: Path) -> list[dict[str, Any]]:
    return [item for item in parse_input_objects(path) if item["section"] in PROTECTED_SECTIONS]


def assemble(
    spec_path: Path,
    output_path: Path,
    catalog_path: Path,
    registry_path: Path,
    force: bool,
) -> Path:
    spec = validate_problem_spec(spec_path)
    assembly = spec.get("deck_assembly")
    if not isinstance(assembly, dict):
        raise WorkflowError("problem specification requires deck_assembly")
    requested = assembly.get("blocks")
    if not isinstance(requested, list) or not requested or not all(isinstance(x, str) for x in requested):
        raise WorkflowError("deck_assembly.blocks must be a nonempty list of block IDs")
    if len(requested) != len(set(requested)):
        raise WorkflowError("deck_assembly.blocks contains duplicate IDs")

    catalog, include_root, catalog_by_id = catalog_index(catalog_path)
    registry, registry_by_id = registry_index(registry_path)
    locked_root = resolve_repo_path(registry["locked_root"])
    errors = validate_registry(catalog_path, registry_path)
    if errors:
        raise WorkflowError("registry validation failed:\n  " + "\n  ".join(errors))
    for block_id in requested:
        if block_id not in registry_by_id:
            raise WorkflowError(f"unknown block ID: {block_id}")
        if registry_by_id[block_id].get("status") != "verified":
            raise WorkflowError(f"assembly may only use verified blocks: {block_id}")
        dimension = registry_by_id[block_id].get("dimension")
        spec_dimension = spec.get("mesh", {}).get("dimension")
        if dimension is not None and dimension != spec_dimension:
            raise WorkflowError(
                f"{block_id} is dimension {dimension}, but the problem specification is {spec_dimension}"
            )

    ordered = order_blocks(requested, registry_by_id, catalog.get("include_order", []))
    scenario_includes = assembly.get("scenario_includes", [])
    if not isinstance(scenario_includes, list) or not all(isinstance(x, str) for x in scenario_includes):
        raise WorkflowError("deck_assembly.scenario_includes must be a list of repository paths")
    scenario_paths = [resolve_repo_path(item) for item in scenario_includes]
    for path in scenario_paths:
        if not path.is_file():
            raise WorkflowError(f"scenario include does not exist: {relative_to_root(path)}")
        protected = direct_protected_objects(path)
        if protected:
            labels = ", ".join(f"{item['section']}/{item['name']}" for item in protected)
            raise WorkflowError(f"scenario include defines protected objects ({labels}): {relative_to_root(path)}")

    output_path = resolve_repo_path(output_path)
    if output_path.exists() and not force:
        raise WorkflowError(f"output exists; pass --force to regenerate: {relative_to_root(output_path)}")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    parameters = assembly.get("parameters", {})
    if not isinstance(parameters, dict):
        raise WorkflowError("deck_assembly.parameters must be a mapping")

    lines = [
        "# GENERATED FILE: assemble from verified blocks; do not add protected objects here.",
        f"# problem_spec: {relative_to_root(spec_path)}",
        f"# registry_sha256: {sha256_file(registry_path)}",
        "",
    ]
    for key, value in parameters.items():
        if not isinstance(key, str) or not PARAMETER_KEY_RE.fullmatch(key):
            raise WorkflowError(f"invalid MOOSE substitution name: {key!r}")
        lines.append(f"{key} := {format_parameter(value)}")
    if parameters:
        lines.append("")
    for block_id in ordered:
        source = locked_root / registry_by_id[block_id]["locked_path"]
        include = os.path.relpath(source, output_path.parent)
        lines.append(f"# verified-block: {block_id}@{registry_by_id[block_id]['version']}")
        lines.append(f"!include {Path(include).as_posix()}")
    if scenario_paths:
        lines.extend(["", "# Scenario-local, non-protected objects."])
        for path in scenario_paths:
            include = os.path.relpath(path, output_path.parent)
            lines.append(f"!include {Path(include).as_posix()}")
    rendered = "\n".join(lines) + "\n"
    output_path.write_text(rendered, encoding="utf-8")

    manifest_path = output_path.with_suffix(output_path.suffix + ".manifest.yml")
    manifest = {
        "schema_version": 1,
        "assembly": spec["name"],
        "problem_spec": relative_to_root(spec_path),
        "output": relative_to_root(output_path),
        "output_sha256": sha256_file(output_path),
        "registry": relative_to_root(registry_path),
        "registry_sha256": sha256_file(registry_path),
        "blocks": [
            {
                "id": block_id,
                "version": registry_by_id[block_id]["version"],
                "sha256": registry_by_id[block_id]["sha256"],
                "path": registry_by_id[block_id]["path"],
                "locked_path": registry_by_id[block_id]["locked_path"],
            }
            for block_id in ordered
        ],
        "scenario_includes": [relative_to_root(path) for path in scenario_paths],
        "validation_target": spec.get("validation", {}).get("matrix_id"),
    }
    write_yaml(manifest_path, manifest)
    return manifest_path


def resolved_includes(path: Path, visited: set[Path] | None = None) -> list[Path]:
    visited = set() if visited is None else visited
    path = path.resolve()
    if path in visited:
        return []
    visited.add(path)
    includes: list[Path] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        match = INCLUDE_RE.match(line)
        if not match:
            continue
        include = (path.parent / match.group("path")).resolve()
        relative_to_root(include)
        if not include.is_file():
            raise WorkflowError(f"missing include {match.group('path')} from {relative_to_root(path)}")
        includes.append(include)
        includes.extend(resolved_includes(include, visited))
    return includes


def validate_assembly_manifest(
    manifest_path: Path, catalog_path: Path, registry_path: Path
) -> list[str]:
    errors: list[str] = []
    try:
        manifest = load_yaml(manifest_path)
        _, include_root, catalog_by_id = catalog_index(catalog_path)
        registry, registry_by_id = registry_index(registry_path)
        locked_root = resolve_repo_path(registry["locked_root"])
        output = resolve_repo_path(manifest.get("output", ""))
        if not output.is_file():
            return [f"manifest output is missing: {manifest.get('output')}"]
        if manifest.get("output_sha256") != sha256_file(output):
            errors.append(f"{relative_to_root(output)}: output hash differs from manifest")
        if manifest.get("registry_sha256") != sha256_file(registry_path):
            errors.append(f"{relative_to_root(manifest_path)}: registry hash differs; regenerate assembly")

        direct = direct_protected_objects(output)
        if direct:
            errors.append(f"{relative_to_root(output)}: generated deck contains direct protected objects")
        includes = resolved_includes(output)
        path_to_id = {
            (locked_root / block["locked_path"]).resolve(): block_id
            for block_id, block in registry_by_id.items()
            if block.get("status") == "verified" and block.get("locked_path")
        }
        actual_ids = []
        for include in includes:
            block_id = path_to_id.get(include)
            if block_id:
                actual_ids.append(block_id)
                block = registry_by_id.get(block_id, {})
                if block.get("status") != "verified":
                    errors.append(f"{block_id}: assembled deck includes a non-verified block")
                if block.get("sha256") != sha256_file(include):
                    errors.append(f"{block_id}: included source violates its registry hash")
            else:
                protected = direct_protected_objects(include)
                if protected:
                    errors.append(
                        f"{relative_to_root(include)}: scenario include contains protected objects"
                    )
        manifest_ids = [item.get("id") for item in manifest.get("blocks", []) if isinstance(item, dict)]
        if actual_ids != manifest_ids:
            errors.append("manifest block order/content differs from resolved canonical includes")
        for item in manifest.get("blocks", []):
            if not isinstance(item, dict) or item.get("id") not in registry_by_id:
                errors.append("manifest contains an unknown block")
                continue
            registry_block = registry_by_id[item["id"]]
            for key in ("version", "sha256", "path", "locked_path"):
                if item.get(key) != registry_block.get(key):
                    errors.append(f"{item['id']}: manifest {key} differs from registry")
    except (WorkflowError, OSError, TypeError) as error:
        errors.append(str(error))
    return errors


def parse_semver(value: str) -> tuple[int, int, int]:
    match = SEMVER_RE.fullmatch(value)
    if not match:
        raise WorkflowError("version must use MAJOR.MINOR.PATCH")
    return tuple(int(item) for item in match.groups())


def promote(
    block_id: str,
    version: str,
    evidence: list[str],
    authorized_by: str,
    approval_ref: str,
    previous_sha: str | None,
    catalog_path: Path,
    registry_path: Path,
) -> None:
    parse_semver(version)
    _, include_root, catalog_by_id = catalog_index(catalog_path)
    registry, registry_by_id = registry_index(registry_path)
    locked_root = resolve_repo_path(
        registry.get("locked_root", LOCKED_ROOT_RELATIVE.as_posix())
    )
    if block_id not in catalog_by_id or block_id not in registry_by_id:
        raise WorkflowError(f"unknown block ID: {block_id}")
    if not BLOCK_ID_RE.fullmatch(block_id):
        raise WorkflowError(f"block ID cannot form a protected path: {block_id}")
    block = registry_by_id[block_id]
    source = include_root / catalog_by_id[block_id]["path"]
    actual_sha = sha256_file(source)
    if block.get("status") == "verified":
        if previous_sha != block.get("sha256"):
            raise WorkflowError("updating a verified block requires its exact --previous-sha")
        if parse_semver(version) <= parse_semver(block["version"]):
            raise WorkflowError("a verified block update requires a higher semantic version")
    elif previous_sha is not None:
        raise WorkflowError("--previous-sha applies only when replacing a verified version")
    if not evidence:
        raise WorkflowError("promotion requires at least one --evidence reference")
    records = []
    for reference in evidence:
        record = {"reference": reference, "result": "passed"}
        if not evidence_exists(record):
            raise WorkflowError(f"evidence path or selector does not exist: {reference}")
        records.append(record)
    locked_path = f"{block_id}/{version}.i"
    locked_source = (locked_root / locked_path).resolve()
    locked_source.relative_to(locked_root.resolve())
    if locked_source.exists() and sha256_file(locked_source) != actual_sha:
        raise WorkflowError(f"protected version already exists with different content: {locked_path}")
    if not locked_source.exists():
        locked_source.parent.mkdir(parents=True, exist_ok=True)
        locked_source.write_bytes(source.read_bytes())
        locked_source.chmod(0o444)
    block.update(
        {
            "version": version,
            "status": "verified",
            "sha256": actual_sha,
            "locked_path": locked_path,
            "objects": object_records(block_id, source),
            "verification": records,
            "promotion": {
                "authorized_by": authorized_by,
                "approval_ref": approval_ref,
                "date": dt.date.today().isoformat(),
            },
        }
    )
    write_yaml(registry_path, registry)


def materialize_existing_locks(catalog_path: Path, registry_path: Path) -> int:
    """Bootstrap protected snapshots for verified records created before locked storage."""
    _, include_root, catalog_by_id = catalog_index(catalog_path)
    registry, registry_by_id = registry_index(registry_path)
    locked_root = resolve_repo_path(
        registry.get("locked_root", LOCKED_ROOT_RELATIVE.as_posix())
    )
    count = 0
    for block_id, block in registry_by_id.items():
        if block.get("status") != "verified" or block.get("locked_path"):
            continue
        if not BLOCK_ID_RE.fullmatch(block_id) or not SEMVER_RE.fullmatch(str(block.get("version", ""))):
            raise WorkflowError(f"cannot materialize invalid verified identity: {block_id}")
        source = include_root / catalog_by_id[block_id]["path"]
        if sha256_file(source) != block.get("sha256"):
            raise WorkflowError(f"cannot materialize changed verified source: {block_id}")
        locked_path = f"{block_id}/{block['version']}.i"
        target = (locked_root / locked_path).resolve()
        target.relative_to(locked_root.resolve())
        if target.exists() and sha256_file(target) != block["sha256"]:
            raise WorkflowError(f"protected version already differs: {locked_path}")
        target.parent.mkdir(parents=True, exist_ok=True)
        if not target.exists():
            target.write_bytes(source.read_bytes())
        target.chmod(0o444)
        block["locked_path"] = locked_path
        count += 1
    write_yaml(registry_path, registry)
    return count


def default_scan_roots() -> list[Path]:
    return [
        ROOT / "moose_app/input/includes",
        ROOT / "moose_app/input/templates",
        ROOT / "moose_app/test/tests",
        ROOT / "moose_app/examples",
    ]


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalog", type=Path, default=DEFAULT_CATALOG)
    parser.add_argument("--registry", type=Path, default=DEFAULT_REGISTRY)
    subparsers = parser.add_subparsers(dest="command", required=True)

    sync = subparsers.add_parser("sync-candidates", help="refresh candidate inventory records")
    sync.set_defaults(handler=command_sync)

    materialize = subparsers.add_parser(
        "materialize-locks", help=argparse.SUPPRESS
    )
    materialize.set_defaults(handler=command_materialize)

    inventory = subparsers.add_parser("inventory", help="inventory individual MOOSE input objects")
    inventory.add_argument("--scan-root", action="append", type=Path)
    inventory.add_argument("--output", type=Path)
    inventory.set_defaults(handler=command_inventory)

    validate = subparsers.add_parser("validate", help="validate registry locks and assemblies")
    validate.add_argument("--manifest", action="append", type=Path, default=[])
    validate.add_argument("--all-assemblies", action="store_true")
    validate.set_defaults(handler=command_validate)

    assembler = subparsers.add_parser("assemble", help="assemble a deck from verified blocks")
    assembler.add_argument("--spec", type=Path, required=True)
    assembler.add_argument("--output", type=Path, required=True)
    assembler.add_argument("--force", action="store_true")
    assembler.set_defaults(handler=command_assemble)

    promotion = subparsers.add_parser("promote", help="promote or version a verified block")
    promotion.add_argument("--id", required=True)
    promotion.add_argument("--version", required=True)
    promotion.add_argument("--evidence", action="append", default=[])
    promotion.add_argument("--authorized-by", required=True)
    promotion.add_argument("--approval-ref", required=True)
    promotion.add_argument("--previous-sha")
    promotion.set_defaults(handler=command_promote)
    return parser


def normalized_paths(args: argparse.Namespace) -> tuple[Path, Path]:
    return resolve_repo_path(args.catalog), resolve_repo_path(args.registry)


def command_sync(args: argparse.Namespace) -> int:
    catalog, registry = normalized_paths(args)
    result = sync_candidates(catalog, registry)
    print(yaml.safe_dump(result, sort_keys=False).strip())
    return 0


def command_inventory(args: argparse.Namespace) -> int:
    catalog, registry = normalized_paths(args)
    scan_roots = [resolve_repo_path(path) for path in args.scan_root] if args.scan_root else default_scan_roots()
    report = discover_inventory(catalog, registry, scan_roots)
    if args.output:
        output = resolve_repo_path(args.output)
        write_yaml(output, report)
        print(f"wrote {relative_to_root(output)}")
    else:
        print(yaml.safe_dump(report, sort_keys=False, width=100).strip())
    return 0


def command_materialize(args: argparse.Namespace) -> int:
    catalog, registry = normalized_paths(args)
    count = materialize_existing_locks(catalog, registry)
    print(f"materialized {count} protected versioned payloads")
    return 0


def command_validate(args: argparse.Namespace) -> int:
    catalog, registry = normalized_paths(args)
    errors = validate_registry(catalog, registry)
    manifests = [resolve_repo_path(path) for path in args.manifest]
    if args.all_assemblies:
        manifests.extend(sorted((ROOT / "moose_app/input/assemblies").glob("*.manifest.yml")))
    for manifest in dict.fromkeys(manifests):
        errors.extend(validate_assembly_manifest(manifest, catalog, registry))
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print(f"OK registry: {relative_to_root(registry)}")
    for manifest in manifests:
        print(f"OK assembly: {relative_to_root(manifest)}")
    return 0


def command_assemble(args: argparse.Namespace) -> int:
    catalog, registry = normalized_paths(args)
    manifest = assemble(
        resolve_repo_path(args.spec), resolve_repo_path(args.output), catalog, registry, args.force
    )
    print(f"wrote {relative_to_root(args.output)}")
    print(f"wrote {relative_to_root(manifest)}")
    return 0


def command_promote(args: argparse.Namespace) -> int:
    catalog, registry = normalized_paths(args)
    promote(
        args.id,
        args.version,
        args.evidence,
        args.authorized_by,
        args.approval_ref,
        args.previous_sha,
        catalog,
        registry,
    )
    errors = validate_registry(catalog, registry)
    if errors:
        raise WorkflowError("post-promotion validation failed:\n  " + "\n  ".join(errors))
    print(f"promoted {args.id}@{args.version}")
    return 0


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        return args.handler(args)
    except (WorkflowError, OSError, json.JSONDecodeError, yaml.YAMLError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
