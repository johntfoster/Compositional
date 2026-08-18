from __future__ import annotations

import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SOURCE_TOOL = Path(__file__).resolve().parents[2] / "tools" / "agentctl"


class AgentctlTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name) / "portable-repo"
        self.root.mkdir()
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        (self.root / "AGENTS.md").write_text("# Instructions\n", encoding="utf-8")
        (self.root / "tools").mkdir()
        shutil.copy2(SOURCE_TOOL, self.root / "tools" / "agentctl")
        (self.root / "agent_environment").mkdir()
        (self.root / "agent_environment" / "skills" / "latex-equation-resolver").mkdir(parents=True)
        (self.root / "agent_environment" / "skills" / "latex-equation-resolver" / "SKILL.md").write_text(
            "---\nname: latex-equation-resolver\n"
            "description: Resolve rendered manuscript equation numbers.\n---\n",
            encoding="utf-8",
        )
        self.write_manifest()

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def write_manifest(self, extra: dict | None = None) -> None:
        profile = {
            "description": "test manuscript tools",
            "triggers": ["equation"],
            "skills": ["latex-*"],
            "checks": [],
            "provision": [],
        }
        if extra:
            profile.update(extra)
        manifest = {
            "version": 1,
            "harnesses": {"test": {"skills_dir": ".test-harness/skills"}},
            "profiles": {"manuscript": profile},
        }
        (self.root / "agent_environment" / "dependencies.json").write_text(
            json.dumps(manifest), encoding="utf-8"
        )

    def run_tool(self, *args: str, cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(self.root / "tools" / "agentctl"), *args],
            cwd=cwd or self.root,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_discovers_root_from_nested_directory(self) -> None:
        nested = self.root / "one" / "two"
        nested.mkdir(parents=True)
        result = self.run_tool("root", cwd=nested)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(Path(result.stdout.strip()), self.root)

    def test_lists_and_routes_canonical_skills(self) -> None:
        listed = self.run_tool("skills", "--json")
        self.assertEqual(listed.returncode, 0, listed.stderr)
        self.assertEqual(json.loads(listed.stdout)[0]["name"], "latex-equation-resolver")
        routed = self.run_tool("route", "explain equation 74", "--json")
        self.assertEqual(routed.returncode, 0, routed.stderr)
        value = json.loads(routed.stdout)
        self.assertEqual(value["profiles"], ["manuscript"])
        self.assertEqual(value["skills"][0]["name"], "latex-equation-resolver")

    def test_dry_run_does_not_provision(self) -> None:
        self.write_manifest({"provision": [{"argv": ["git", "--version"]}]})
        result = self.run_tool("route", "equation", "--provision", "--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("would run: git --version", result.stdout)
        markers = list((self.root / ".git").glob("agentctl/profiles/*.json"))
        self.assertEqual(markers, [])

    def test_profile_is_provisioned_only_once(self) -> None:
        counter = "agent_environment/provision-count.txt"
        command = [
            "python3",
            "-c",
            "from pathlib import Path; p=Path('agent_environment/provision-count.txt'); "
            "p.write_text((p.read_text() if p.exists() else '') + 'x')",
        ]
        self.write_manifest({"provision": [{"argv": command}]})
        first = self.run_tool("activate", "test", "equation", "--provision")
        second = self.run_tool("activate", "test", "equation", "--provision")
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual((self.root / counter).read_text(encoding="utf-8"), "x")
        self.assertIn("provisioned", first.stdout)
        self.assertIn("ready", second.stdout)

    def test_activate_installs_only_routed_skill(self) -> None:
        other = self.root / "agent_environment" / "skills" / "moose-builder"
        other.mkdir()
        (other / "SKILL.md").write_text(
            "---\nname: moose-builder\ndescription: Build simulator applications.\n---\n",
            encoding="utf-8",
        )
        result = self.run_tool("activate", "test", "equation", "--json")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.root / ".test-harness" / "skills" / "latex-equation-resolver" / "SKILL.md").is_file())
        self.assertFalse((self.root / ".test-harness" / "skills" / "moose-builder").exists())

    def test_activation_refreshes_changed_helper_files(self) -> None:
        source = self.root / "agent_environment/skills/latex-equation-resolver"
        (source / "scripts").mkdir()
        helper = source / "scripts/resolve.py"
        helper.write_text("print('one')\n", encoding="utf-8")
        self.run_tool("activate", "test", "equation")
        helper.write_text("print('two')\n", encoding="utf-8")
        result = self.run_tool("activate", "test", "equation")
        self.assertEqual(result.returncode, 0, result.stderr)
        installed = self.root / ".test-harness/skills/latex-equation-resolver/scripts/resolve.py"
        self.assertEqual(installed.read_text(encoding="utf-8"), "print('two')\n")

    def test_hook_install_uses_repository_relative_local_config(self) -> None:
        (self.root / ".githooks").mkdir()
        (self.root / ".githooks" / "pre-commit").write_text("#!/bin/sh\n", encoding="utf-8")
        result = self.run_tool("hooks", "install")
        self.assertEqual(result.returncode, 0, result.stderr)
        configured = subprocess.run(
            ["git", "config", "--local", "--get", "core.hooksPath"],
            cwd=self.root,
            text=True,
            capture_output=True,
            check=True,
        )
        self.assertEqual(configured.stdout.strip(), ".githooks")

    def test_rejects_absolute_manifest_path(self) -> None:
        outside = str(Path(self.tempdir.name).resolve() / "dependencies.json")
        result = self.run_tool("profiles", "--manifest", outside)
        self.assertEqual(result.returncode, 2)
        self.assertIn("repository-relative", result.stderr)

    def test_check_has_machine_independent_output(self) -> None:
        result = self.run_tool("check", "--json")
        self.assertEqual(result.returncode, 0, result.stderr)
        value = json.loads(result.stdout)
        self.assertEqual(value["root"], ".")
        self.assertEqual(value["failures"], [])


if __name__ == "__main__":
    unittest.main()
