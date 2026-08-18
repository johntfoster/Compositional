# Multicomponent Reactive Flow

This repository develops a multicomponent reactive-flow theory manuscript, its
MOOSE implementation and validation, and reusable agent-assisted simulator
workflows. The manuscript is the current source of truth for the theory.

## Manuscript

`main.tex` is the manuscript root. It declares the packages, loads `defs.tex`,
sets the title/author block, inputs the manuscript sections, and owns the
bibliography.

Current section files live in `sections/` and are input by `main.tex`:

- `sections/introduction.tex`
- `sections/material_mass.tex`
- `sections/conservation_of_charge.tex`
- `sections/virtual_power_derivation.tex`
- `sections/multicomponent_solids.tex`
- `sections/pulled_back_solid_skeleton.tex`
- `sections/correspondence_to_other_theories.tex`
- `sections/conclusions.tex`
- `sections/technical_setting.tex`
- `sections/appendix_component_potential_derivation.tex`
- `sections/appendix_single_phase_energy_audit.tex`
- `sections/appendix_nernst_planck_darcy_audit.tex`

Shared macros and notation helpers live in `defs.tex`. Bibliographic entries
live in `all.bib`.

## Implementation Track

The new MOOSE application scaffold lives in `moose_app/`. It is intentionally
independent of the earlier three-phase reacting-mixture app; that older code is
design memory, not a source tree to branch or copy.

The companion finite-element implementation and verification paper lives in
`implementation_paper/`. Its working principle is that finite-element weak
forms are written on the reference configuration of the solid skeleton.

Validation planning, reference data, and postprocessing assets live in
`validation/`. Agent-facing input-deck templates, schemas, run recipes, and
checks live in `agent_workflows/`.

## Portable agent setup

`AGENTS.md` is the universal repository entry point. Canonical, harness-neutral
skills live under `agent_environment/skills/`; no user-level skill installation
is assumed. On a fresh clone, inspect the route for a request and activate only
the matching skills:

```sh
tools/agentctl route "resolve equation 74 in the manuscript"
tools/agentctl activate codex "resolve equation 74 in the manuscript"
```

Replace `codex` with `claude`, `copilot`, `grok-build`, `opencode`, or `pi` as
needed. Activation copies only selected skills into that harness's repository
adapter directory. Add `--provision` only when the selected task needs external
dependencies. For example, manuscript equation lookup needs no MOOSE checkout,
while a MOOSE build request provisions the MOOSE profile when explicitly asked.
Run `tools/agentctl check` to audit the portable configuration.

Install the versioned Git hooks once per clone with:

```sh
tools/agentctl hooks install
```

## Editing and preview

The repository supports any editor or harness. Build from the repository root
with the standard recipe:

```sh
pdflatex -output-directory=build main.tex
(cd build && BIBINPUTS=../: BSTINPUTS=../: bibtex main)
pdflatex -output-directory=build main.tex
pdflatex -output-directory=build main.tex
```

VS Code users may run the equivalent LaTeX Workshop recipe. Build output is
always written to `build/` and is ignored by Git.

The repository versions its complete VS Code workspace configuration under
`.vscode/`, including editor behavior, LaTeX formatting/build settings, terminal
profile, and extension recommendations. Executables are resolved through
`PATH`, so these settings remain clone-location and user independent.
`extensions.lock.json` preserves the complete local extension set with versions.
Restore it only when VS Code is relevant with `tools/agentctl provision vscode`.

## Research PDFs and Notes

Use `references/pdfs/` for source PDFs that should be available as research
context. Use `references/notes/` for short human-written notes, derivation
checks, or reading summaries.

Generated retrieval, dependency, and build state lives under `.agent-runtime/`
and is ignored by Git. Legacy local cache names remain ignored. The source of truth
for manuscript claims remains the TeX source rooted at `main.tex`.

See `references/README.md` for the PDF ingestion and note-taking workflow.

## Working with AI agents

For manuscript questions or edits, ask against the root manuscript context.
Examples:

```text
Check the derivation from eq:material_mass_2 to eq:component_spatial_mass.
```

```text
Compare our definition of intrinsic density against the ingested PDFs, then
identify any notation mismatch in the manuscript source.
```

Agents should cite manuscript source as `file:line` and prefer narrow edits to
the relevant section files. The repository intentionally does not contain a
`.github/copilot-instructions.md`: duplicating universal policy there would
create a second source of truth. Harness-specific adapters install skills, while
all agents read the same `AGENTS.md` and routed resources.

AI-use facts and generated disclosures live in `provenance/`. The commit hook
updates the public and journal-facing statements on every commit. The first and
current covered dates are derived from Git instead of being hand-maintained.
See `provenance/README.md` for active-development, submission-freeze, and future
manuscript-history extraction workflows.
