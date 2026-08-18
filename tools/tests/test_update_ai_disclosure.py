#!/usr/bin/env python3
"""Tests for the dependency-free AI disclosure generator."""

from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


SOURCE_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = SOURCE_ROOT / "tools/update_ai_disclosure.py"
REGISTRY = SOURCE_ROOT / "provenance/ai-use.yml"
HOOK = SOURCE_ROOT / ".githooks/pre-commit"


class DisclosureTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        (self.root / "tools").mkdir()
        (self.root / "provenance").mkdir()
        (self.root / ".githooks").mkdir()
        shutil.copy2(SCRIPT, self.root / "tools/update_ai_disclosure.py")
        shutil.copy2(REGISTRY, self.root / "provenance/ai-use.yml")
        shutil.copy2(HOOK, self.root / ".githooks/pre-commit")
        self.git("init", "-q")
        self.git("config", "user.name", "Test Author")
        self.git("config", "user.email", "test@example.invalid")
        (self.root / "README.md").write_text("before manuscript\n", encoding="utf-8")
        self.commit("2026-05-01T10:00:00+00:00", "non-manuscript")
        (self.root / "main.tex").write_text("manuscript\n", encoding="utf-8")
        self.commit("2026-05-08T16:42:39+00:00", "first manuscript")
        (self.root / "README.md").write_text("later\n", encoding="utf-8")
        self.commit("2026-08-17T16:19:49+00:00", "latest")

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def git(self, *args: str, env: dict[str, str] | None = None) -> str:
        completed = subprocess.run(
            ["git", *args], cwd=self.root, text=True, capture_output=True, check=True, env=env
        )
        return completed.stdout.strip()

    def commit(self, timestamp: str, message: str) -> None:
        self.git("add", "-A")
        environment = {"GIT_AUTHOR_DATE": timestamp, "GIT_COMMITTER_DATE": timestamp}
        import os

        self.git("commit", "-q", "-m", message, env={**os.environ, **environment})

    def run_script(self, *args: str, expected: int = 0) -> subprocess.CompletedProcess[str]:
        completed = subprocess.run(
            ["python3", "tools/update_ai_disclosure.py", *args],
            cwd=self.root,
            text=True,
            capture_output=True,
        )
        self.assertEqual(expected, completed.returncode, completed.stderr)
        return completed

    def test_active_output_derives_first_and_latest_commits(self) -> None:
        first_hash = self.git("log", "--reverse", "--format=%H", "--", "main.tex").splitlines()[0]
        self.run_script()
        markdown = (self.root / "provenance/AI_USE.md").read_text(encoding="utf-8")
        latex = (self.root / "provenance/ai_use_statement.tex").read_text(encoding="utf-8")
        self.assertIn(f"`{first_hash}` (8 May 2026)", markdown)
        self.assertIn("the latest covered commit on 17 August 2026", markdown)
        self.assertIn("From 8 May 2026 through the latest covered commit", latex)
        self.assertIn("model versions were not consistently recorded", markdown)

    def test_pending_date_and_check_mode_are_deterministic(self) -> None:
        self.run_script("--pending-date", "2026-08-18")
        markdown = (self.root / "provenance/AI_USE.md").read_text(encoding="utf-8")
        self.assertIn("the latest covered commit on 18 August 2026", markdown)
        self.run_script("--check", "--pending-date", "2026-08-18")
        self.run_script("--check", "--pending-date", "2026-08-19", expected=1)

    def test_frozen_output_uses_tag_without_embedding_commit_hash(self) -> None:
        self.git("tag", "manuscript-submission-v1")
        registry_path = self.root / "provenance/ai-use.yml"
        registry = json.loads(registry_path.read_text(encoding="utf-8"))
        registry["disclosure"]["status"] = "submission-frozen"
        registry["disclosure"]["submission_tag"] = "manuscript-submission-v1"
        registry_path.write_text(json.dumps(registry), encoding="utf-8")
        final_hash = self.git("rev-parse", "manuscript-submission-v1")
        self.run_script("--pending-date", "2026-08-30")
        markdown = (self.root / "provenance/AI_USE.md").read_text(encoding="utf-8")
        latex = (self.root / "provenance/ai_use_statement.tex").read_text(encoding="utf-8")
        self.assertIn("Submission-frozen", markdown)
        self.assertIn("identified by tag `manuscript-submission-v1`", markdown)
        self.assertNotIn(final_hash, markdown)
        self.assertIn("final manuscript commit", latex)

    def test_absolute_manuscript_path_is_rejected(self) -> None:
        registry_path = self.root / "provenance/ai-use.yml"
        registry = json.loads(registry_path.read_text(encoding="utf-8"))
        registry["manuscript_paths"] = ["/absolute/main.tex"]
        registry_path.write_text(json.dumps(registry), encoding="utf-8")
        completed = self.run_script(expected=2)
        self.assertIn("repository-relative", completed.stderr)

    def test_hook_stages_only_generated_provenance_files(self) -> None:
        (self.root / "README.md").write_text("unstaged user change\n", encoding="utf-8")
        completed = subprocess.run(
            ["sh", ".githooks/pre-commit"],
            cwd=self.root,
            text=True,
            capture_output=True,
        )
        self.assertEqual(0, completed.returncode, completed.stderr)
        staged = self.git("diff", "--cached", "--name-only").splitlines()
        self.assertEqual(
            ["provenance/AI_USE.md", "provenance/ai_use_statement.tex"], staged
        )
        self.assertIn("README.md", self.git("diff", "--name-only").splitlines())

    def test_hook_commit_is_immediately_current(self) -> None:
        self.git("config", "core.hooksPath", ".githooks")
        (self.root / "README.md").write_text("hooked commit\n", encoding="utf-8")
        self.commit("2026-08-18T12:00:00+00:00", "hooked")
        self.run_script("--check")


if __name__ == "__main__":
    unittest.main()
