#!/usr/bin/env python3
"""Resolve a takeme target to source locations.

Prints candidates as: repository/path:line<TAB>kind<TAB>detail
"""
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

TEXT_EXTS = {
    ".tex", ".bib", ".md", ".sty", ".cls", ".txt", ".yaml", ".yml",
    ".json", ".py", ".sh", ".toml", ".ini", ".cfg",
}

NEWLABEL_RE = re.compile(
    r"""\\newlabel\{(?P<label>[^}]+)\}\{\{(?P<number>(?:[^{}]|\{[^{}]*\})*)\}"""
)


def run(cmd: list[str], cwd: Path, env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=str(cwd), env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def repo_root(path: str) -> Path:
    p = Path(path).expanduser().resolve()
    cp = run(["git", "rev-parse", "--show-toplevel"], p)
    if cp.returncode == 0:
        return Path(cp.stdout.strip()).resolve()
    return p


def emit(path: Path, line: int, kind: str, detail: str, root: Path) -> None:
    try:
        display = path.resolve().relative_to(root.resolve())
    except ValueError:
        return
    print(f"{display}:{line}\t{kind}\t{detail}")


def normalize_number(value: str) -> str:
    value = value.strip()
    if value.startswith("(") and value.endswith(")"):
        value = value[1:-1]
    value = re.sub(r"\s+", "", value)
    return value.replace(r"\theequation", "")


def strip_tex_markup(value: str) -> str:
    value = value.replace(r"\relax", "")
    value = re.sub(r"\\(?:textup|mathrm|mathbf|mathit|textrm)\{([^{}]*)\}", r"\1", value)
    value = re.sub(r"\\[a-zA-Z]+", "", value)
    return normalize_number(value.replace("{", "").replace("}", ""))


def parse_aux(path: Path) -> list[tuple[str, str, Path]]:
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return []
    out = []
    for match in NEWLABEL_RE.finditer(text):
        label = match.group("label")
        number = strip_tex_markup(match.group("number"))
        if number:
            out.append((label, number, path))
    return out


def root_aux_files(root: Path) -> list[Path]:
    preferred = [root / "build/main.aux", root / "main.aux", root / "out/main.aux", root / "latex.out/main.aux"]
    seen, files = set(), []
    for p in preferred + sorted(root.rglob("*.aux")):
        if not p.is_file() or {".git", ".ragpi", ".mechpi", ".latex-edit-pi"}.intersection(p.parts):
            continue
        r = p.resolve()
        if r not in seen:
            seen.add(r)
            files.append(p)
    return files


def compile_temp_records(root: Path) -> list[tuple[str, str, Path]]:
    main = root / "main.tex"
    if not main.is_file():
        return []
    env = os.environ.copy()
    cache_root = root / ".agent-runtime" / "tex-cache"
    texmf_var = cache_root / "var"
    texmf_cache = cache_root / "cache"
    texmf_var.mkdir(parents=True, exist_ok=True)
    texmf_cache.mkdir(parents=True, exist_ok=True)
    env.setdefault("TEXMFVAR", str(texmf_var))
    env.setdefault("TEXMFCACHE", str(texmf_cache))
    with tempfile.TemporaryDirectory(prefix="takeme-latex-") as tmp_s:
        tmp = Path(tmp_s)
        cmd = ["lualatex", "--interaction=nonstopmode", "-halt-on-error", "-draftmode", f"-output-directory={tmp}", "main.tex"]
        cp = run(cmd, root, env=env)
        aux = tmp / "main.aux"
        if not aux.is_file():
            sys.stderr.write(cp.stderr or cp.stdout[-2000:])
            return []
        return parse_aux(aux)


def source_files(root: Path) -> list[Path]:
    suffixes = {".tex", ".ltx", ".sty", ".cls"}
    ignored = {".git", "build", "out", ".ragpi", ".mechpi", ".latex-edit-pi"}
    return [p for p in root.rglob("*") if p.is_file() and p.suffix in suffixes and not ignored.intersection(p.parts)]


def label_locations(root: Path, labels: list[str]) -> dict[str, list[tuple[Path, int]]]:
    pats = {label: re.compile(r"\\label\{" + re.escape(label) + r"\}") for label in labels}
    locs = {label: [] for label in labels}
    for path in source_files(root):
        try:
            lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        except OSError:
            continue
        for lineno, line in enumerate(lines, 1):
            for label, pat in pats.items():
                if pat.search(line):
                    locs[label].append((path, lineno))
    return locs


def direct_file(target: str, root: Path) -> bool:
    m = re.match(r"^(.+?)(?::(\d+))?$", target)
    if not m:
        return False
    raw, line_s = m.group(1), m.group(2)
    p = Path(raw)
    if p.is_absolute():
        return False
    p = root / p
    if p.exists() and p.is_file():
        emit(p, int(line_s or 1), "file", target, root)
        return True
    return False


def resolve_equation(target: str, root: Path) -> bool:
    t = target.strip()
    m = re.match(r"^(?:eq(?:uation)?\s*)?\(?([0-9]+[a-z]?)\)?$", t, re.I)
    if not m:
        return False
    number = normalize_number(m.group(1))
    records = []
    for aux in root_aux_files(root):
        records.extend(parse_aux(aux))
    if not records:
        records.extend(compile_temp_records(root))
    matches = []
    seen = set()
    for label, rendered, aux in records:
        if rendered == number and (label, rendered) not in seen:
            seen.add((label, rendered))
            matches.append((label, rendered, aux))
    if not matches:
        return False
    locs = label_locations(root, [label for label, _, _ in matches])
    found = False
    for label, _, _ in matches:
        for path, line in locs.get(label, []):
            emit(path, line, "equation", label, root)
            found = True
    return found


def search_label(target: str, root: Path) -> bool:
    cleaned = re.sub(r"^eq:", "", target.strip())
    patterns = [target.strip(), f"eq:{cleaned}"]
    found = False
    for pat in dict.fromkeys(patterns):
        cp = run(["rg", "-n", "--fixed-strings", f"\\label{{{pat}}}", "sections", "main.tex", "defs.tex"], root)
        if cp.returncode not in (0, 1):
            continue
        for row in cp.stdout.splitlines():
            file, line, *_ = row.split(":", 2)
            emit(root / file, int(line), "label", pat, root)
            found = True
    return found


def text_files(root: Path):
    cp = run(["rg", "--files"], root)
    if cp.returncode != 0:
        for p in root.rglob("*"):
            if p.is_file() and p.suffix in TEXT_EXTS:
                yield str(p.relative_to(root))
        return
    preferred, rest = [], []
    for f in cp.stdout.splitlines():
        suffix = Path(f).suffix.lower()
        if suffix in {".tex", ".bib", ".md", ".sty", ".cls"}:
            preferred.append(f)
        elif suffix in TEXT_EXTS:
            rest.append(f)
    yield from preferred
    yield from rest


def search_freeform(target: str, root: Path, limit: int) -> bool:
    files = list(text_files(root))
    if not files:
        return False
    cp = run(["rg", "-n", "-i", "--fixed-strings", target, *files], root)
    if cp.returncode == 0:
        for row in cp.stdout.splitlines()[:limit]:
            file, line, detail = row.split(":", 2)
            emit(root / file, int(line), "text", detail.strip(), root)
        return True
    tokens = [x for x in re.findall(r"[A-Za-z0-9_\\^{}-]+", target) if len(x) > 2]
    if not tokens:
        return False
    pattern = ".*".join(re.escape(x) for x in tokens[:6])
    cp = run(["rg", "-n", "-i", pattern, *files], root)
    if cp.returncode == 0:
        for row in cp.stdout.splitlines()[:limit]:
            file, line, detail = row.split(":", 2)
            emit(root / file, int(line), "context", detail.strip(), root)
        return True
    return False


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=".")
    ap.add_argument("--target", required=True)
    ap.add_argument("--limit", type=int, default=8)
    args = ap.parse_args()

    root = repo_root(args.repo)
    target = args.target.strip().strip('"\'')
    if not target:
        return 2

    if direct_file(target, root):
        return 0
    if resolve_equation(target, root):
        return 0
    if search_label(target, root):
        return 0
    if search_freeform(target, root, args.limit):
        return 0

    print(f"No location found for: {target}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
