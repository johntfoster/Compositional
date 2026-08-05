#!/usr/bin/env python3
"""Regression tests for the verified input-block workflow."""

from __future__ import annotations

import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest import mock

import yaml


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "agent_workflows/scripts/verified_blocks.py"
SPEC = importlib.util.spec_from_file_location("verified_blocks", MODULE_PATH)
assert SPEC and SPEC.loader
verified_blocks = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(verified_blocks)


class VerifiedBlockTests(unittest.TestCase):
    def test_parse_named_objects_and_types(self) -> None:
        source = """[Kernels]
  [storage]
    type = ADReferenceComponentStorageTerm
  []
[]

[Materials]
  [flux]
    type = ADStandardDarcyReferenceFluxMaterial
  []
[]
"""
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "objects.i"
            path.write_text(source, encoding="utf-8")
            objects = verified_blocks.parse_input_objects(path)
        self.assertEqual(
            [(item["section"], item["name"], item["type"]) for item in objects],
            [
                ("Kernels", "storage", "ADReferenceComponentStorageTerm"),
                ("Materials", "flux", "ADStandardDarcyReferenceFluxMaterial"),
            ],
        )

    def test_catalog_and_registry_cover_all_canonical_fragments(self) -> None:
        _, include_root, catalog = verified_blocks.catalog_index(
            verified_blocks.DEFAULT_CATALOG
        )
        _, registry = verified_blocks.registry_index(verified_blocks.DEFAULT_REGISTRY)
        disk_paths = {
            path.relative_to(include_root).as_posix() for path in include_root.rglob("*.i")
        }
        self.assertEqual(disk_paths, {item["path"] for item in catalog.values()})
        self.assertEqual(set(catalog), set(registry))

    def test_registry_integrity(self) -> None:
        self.assertEqual(
            verified_blocks.validate_registry(
                verified_blocks.DEFAULT_CATALOG, verified_blocks.DEFAULT_REGISTRY
            ),
            [],
        )

    def test_verified_blocks_have_durable_evidence(self) -> None:
        _, registry = verified_blocks.registry_index(verified_blocks.DEFAULT_REGISTRY)
        verified = [item for item in registry.values() if item["status"] == "verified"]
        for block in verified:
            self.assertRegex(block["version"], verified_blocks.SEMVER_RE)
            self.assertTrue(block["verification"])
            self.assertTrue(all(item["result"] == "passed" for item in block["verification"]))
            self.assertTrue(block["promotion"]["authorized_by"])

    def test_registry_yaml_has_expected_policy(self) -> None:
        registry = yaml.safe_load(verified_blocks.DEFAULT_REGISTRY.read_text(encoding="utf-8"))
        self.assertEqual(registry["hash_algorithm"], "sha256")
        self.assertEqual(registry["canonicalization"], "exact_bytes")
        self.assertEqual(
            set(registry["protected_sections"]), verified_blocks.PROTECTED_SECTIONS
        )

    def test_generated_assembly_uses_protected_snapshots(self) -> None:
        deck = ROOT / "moose_app/input/assemblies/verified_q2_eg_mms_2d.i"
        text = deck.read_text(encoding="utf-8")
        self.assertIn(".codex/verified-input-blocks/", text)
        self.assertNotIn("!include ../includes/", text)
        manifest = deck.with_suffix(deck.suffix + ".manifest.yml")
        self.assertEqual(
            verified_blocks.validate_assembly_manifest(
                manifest,
                verified_blocks.DEFAULT_CATALOG,
                verified_blocks.DEFAULT_REGISTRY,
            ),
            [],
        )

    def test_scenario_protected_object_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "scenario.i"
            path.write_text(
                "[Kernels]\n  [forbidden]\n    type = ADMaterialPropertyResidual\n  []\n[]\n",
                encoding="utf-8",
            )
            objects = verified_blocks.direct_protected_objects(path)
        self.assertEqual([(item["section"], item["name"]) for item in objects], [("Kernels", "forbidden")])

    def test_changed_protected_payload_is_a_lock_violation(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            include_root = root / "includes"
            locked_root = root / ".codex/verified-input-blocks"
            source = include_root / "operators/example.i"
            locked = locked_root / "operators.example/1.0.0.i"
            evidence = root / "tests"
            source.parent.mkdir(parents=True)
            locked.parent.mkdir(parents=True)
            source_text = "[Kernels]\n  [example]\n    type = ADMaterialPropertyResidual\n  []\n[]\n"
            source.write_text(source_text, encoding="utf-8")
            locked.write_text(source_text.replace("example", "changed", 1), encoding="utf-8")
            evidence.write_text("[example_passes]\n", encoding="utf-8")
            catalog = root / "catalog.yml"
            registry = root / "registry.yml"
            catalog.write_text(
                yaml.safe_dump(
                    {
                        "schema_version": 1,
                        "include_root": "includes",
                        "fragments": [
                            {"id": "operators.example", "path": "operators/example.i"}
                        ],
                    },
                    sort_keys=False,
                ),
                encoding="utf-8",
            )
            with mock.patch.object(verified_blocks, "ROOT", root):
                objects = verified_blocks.object_records("operators.example", source)
                registry.write_text(
                    yaml.safe_dump(
                        {
                            "schema_version": 1,
                            "hash_algorithm": "sha256",
                            "canonicalization": "exact_bytes",
                            "locked_root": ".codex/verified-input-blocks",
                            "blocks": [
                                {
                                    "id": "operators.example",
                                    "version": "1.0.0",
                                    "status": "verified",
                                    "path": "operators/example.i",
                                    "locked_path": "operators.example/1.0.0.i",
                                    "sha256": verified_blocks.sha256_file(source),
                                    "objects": objects,
                                    "verification": [
                                        {
                                            "reference": "tests::example_passes",
                                            "result": "passed",
                                        }
                                    ],
                                    "promotion": {"authorized_by": "John"},
                                }
                            ],
                        },
                        sort_keys=False,
                    ),
                    encoding="utf-8",
                )
                errors = verified_blocks.validate_registry(catalog, registry)
        self.assertTrue(any("LOCK VIOLATION in protected payload" in item for item in errors))


if __name__ == "__main__":
    unittest.main()
