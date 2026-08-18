#!/usr/bin/env python3
"""Check or restore the repository's versioned VS Code extension set."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LOCK = ROOT / ".vscode/extensions.lock.json"


def desired() -> set[str]:
    data = json.loads(LOCK.read_text(encoding="utf-8"))
    if data.get("schema_version") != 1:
        raise ValueError("unsupported VS Code extension lock schema")
    values = data.get("extensions")
    if not isinstance(values, list) or not all(isinstance(value, str) and "@" in value for value in values):
        raise ValueError("extensions must be id@version strings")
    return set(values)


def installed() -> set[str]:
    if not shutil.which("code"):
        raise RuntimeError("VS Code command 'code' is unavailable")
    result = subprocess.run(
        ["code", "--list-extensions", "--show-versions"],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    values = {line.strip().lower() for line in result.stdout.splitlines() if "@" in line}
    if result.returncode and not values:
        raise RuntimeError(result.stderr.strip() or "could not list VS Code extensions")
    return values


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["check", "install"])
    args = parser.parse_args()
    missing = sorted(desired() - installed())
    if args.command == "check":
        for value in missing:
            print(f"missing VS Code extension: {value}", file=sys.stderr)
        return 1 if missing else 0
    for value in missing:
        subprocess.run(["code", "--install-extension", value, "--force"], cwd=ROOT, check=True)
    print(f"VS Code extension set ready ({len(desired())} locked extensions)")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, RuntimeError, json.JSONDecodeError) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(2)
