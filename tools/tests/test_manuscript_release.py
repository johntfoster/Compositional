#!/usr/bin/env python3
"""Tests for the dry-run-first manuscript release workflow."""

from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


SOURCE_ROOT = Path(__file__).resolve().parents[2]


class ManuscriptReleaseTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        (self.root / "tools").mkdir()
        (self.root / "provenance").mkdir()
        shutil.copy2(SOURCE_ROOT / "tools/manuscript_release.py", self.root / "tools")
        (self.root / "provenance/manuscript-export.json").write_text(
            json.dumps({"schema_version": 1, "paths": ["main.tex"]}), encoding="utf-8"
        )
        (self.root / "main.tex").write_text("manuscript\n", encoding="utf-8")
        self.git("init", "-q")
        self.git("config", "user.name", "Test Author")
        self.git("config", "user.email", "test@example.invalid")
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "initial")

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def git(self, *args: str) -> None:
        subprocess.run(["git", *args], cwd=self.root, check=True)

    def command(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["python3", "tools/manuscript_release.py", *args],
            cwd=self.root,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_audit_accepts_tracked_relative_manifest(self) -> None:
        result = self.command("audit")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("1 repository-relative paths", result.stdout)

    def test_extract_dry_run_is_non_mutating(self) -> None:
        result = self.command("extract", "--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("git clone --no-local", result.stdout)
        self.assertFalse((self.root / ".agent-runtime").exists())

    def test_extract_rejects_destination_outside_runtime(self) -> None:
        result = self.command("extract", "--destination", "../outside", "--dry-run")
        self.assertEqual(result.returncode, 2)
        self.assertIn("repository-relative", result.stderr)

    def test_freeze_preview_requires_clean_tree_and_creates_no_tag(self) -> None:
        result = self.command("freeze", "--tag", "manuscript-submission-v1")
        self.assertEqual(result.returncode, 0, result.stderr)
        tags = subprocess.run(
            ["git", "tag", "--list"], cwd=self.root, text=True, capture_output=True, check=True
        ).stdout
        self.assertEqual(tags, "")
        (self.root / "main.tex").write_text("dirty\n", encoding="utf-8")
        dirty = self.command("freeze", "--tag", "manuscript-submission-v1")
        self.assertEqual(dirty.returncode, 2)
        self.assertIn("clean worktree", dirty.stderr)


if __name__ == "__main__":
    unittest.main()
