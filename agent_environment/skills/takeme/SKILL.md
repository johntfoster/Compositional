---
name: takeme
description: Resolve a requested manuscript location for editor navigation. Use when the user says "takeme", "take me", "jump me", "go to", or asks to move the cursor/editor to an equation number, label, file location, or contextual text pattern. In LaTeX manuscripts, resolve rendered equation numbers through build artifacts before navigating.
---

# Takeme

Move the user's editor to a concrete source location.

## Fast path

Run the deterministic helper directly for ordinary navigation. Use delegation
only when the target is genuinely ambiguous or the user requests it.

## Workflow

1. Identify the target phrase after `takeme`, `take me`, `jump me`, `go to`, or similar.
2. If the target looks like a rendered LaTeX equation number, resolve it from build artifacts before jumping. Prefer the existing `latex-equation-resolver` workflow/script when available.
3. Otherwise locate the target as a source label, file path, or freeform contextual pattern.
4. Use the active harness's editor-navigation capability when one is exposed.
   Otherwise return the repository-relative `file:line` location.

## Helper Script

Use `scripts/takeme_resolve.py` from this skill for deterministic lookup:

```bash
python3 agent_environment/skills/takeme/scripts/takeme_resolve.py --repo . --target "151"
python3 agent_environment/skills/takeme/scripts/takeme_resolve.py --repo . --target "solid_specific_volume_deformation_chain_rule"
python3 agent_environment/skills/takeme/scripts/takeme_resolve.py --repo . --target "component nonlinear Biot coefficient"
```

The script prints repository-relative `file:line` candidates. Use the first
exact or highest-confidence match unless source context suggests a better one.

## Target Rules

- Equation number: resolve from aux/build artifacts, never from source order.
- Label: search for `\label{...}` and jump to that line.
- File path with optional line: jump directly after making it absolute.
- Freeform pattern: search source files first (`.tex`, `.bib`, `.md`, `.sty`, `.cls`), then fall back to all tracked text-like files if needed.
- Ambiguous matches: inspect a few candidates and pick the one best matching the user's context; if still ambiguous, show the candidates briefly instead of jumping.

## Reporting

For successful jumps, answer only with a terse done message plus the resolved label/pattern and clickable source link. For failures, report only the reason and the best candidate information available.
