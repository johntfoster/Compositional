# Multicomponent Reactive Flow Manuscript

This repository contains the LaTeX source and research context for the
multicomponent reactive flow manuscript.

The repository is now organized around the theory manuscript, a clean MOOSE app
scaffold, a companion finite-element implementation paper, validation assets,
and agent-facing simulator workflow templates.

## Manuscript

`main.tex` is the manuscript root. It declares the packages, loads `defs.tex`,
sets the title/author block, inputs the manuscript sections, and owns the
bibliography.

Current section files live in `sections/`:

- `sections/material_mass.tex`
- `sections/variational_derivation.tex`
- `sections/coleman_noll.tex`

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

## Editing and Preview

The repository is configured for the LaTeX Workshop VS Code extension.

Open the folder in VS Code, then use:

```text
LaTeX Workshop: Build with recipe
```

The default full recipe is:

```text
pdflatex -> bibtex -> pdflatex x2
```

Build output is written to `build/`, and generated LaTeX files are ignored by
git.

## Research PDFs and Notes

Use `references/pdfs/` for source PDFs that should be available as research
context. Use `references/notes/` for short human-written notes, derivation
checks, or reading summaries.

Generated retrieval/cache state such as `.codex-research/`, `.latex-edit-pi/`, and
`.mechpi/` is local workflow state and is ignored by git. The source of truth
for manuscript claims remains the TeX source rooted at `main.tex`.

See `references/README.md` for the PDF ingestion and note-taking workflow.

## Collaboration With Codex

For manuscript questions or edits, ask against the root manuscript context.
Examples:

```text
Check the derivation from eq:material_mass_2 to eq:component_spatial_mass.
```

```text
Compare our definition of intrinsic density against the ingested PDFs, then
identify any notation mismatch in the manuscript source.
```

Codex should cite manuscript source as `file:line` and should prefer narrow
edits to the relevant section files.
