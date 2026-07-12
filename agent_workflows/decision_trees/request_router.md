# Agent Request Router

Use this tree before doing repository work. It is a fast routing layer; it does
not replace `AGENTS.md`, `VISION.md`, `main.tex`, or `defs.tex`.

## Startup

1. Read `AGENTS.md` and `VISION.md`.
2. Classify the immediate task owner:
   - `theory-manuscript`
   - `moose-implementation`
   - `validation`
   - `agent-workflow`
   - `cross-track-planning`
3. If the task touches manuscript notation, equations, labels, or references,
   read `main.tex` and `defs.tex` before interpreting section-local text.

## Route

| User request pattern | Primary route | Required companion file |
| --- | --- | --- |
| "What does this mean?", "is this correct?", "do we need this?" | Interpretive manuscript answer | `AGENTS.md`, source locations |
| "Change", "revise", "fix", "remove", "box", "rename" | Manuscript edit | `agent_workflows/decision_trees/manuscript_edit.md` |
| Rendered equation number such as `(71)` or "equation 144" | Equation lookup first | `agent_workflows/decision_trees/equation_number_lookup.md` |
| Symbol or notation change | Propagation plan before edit | `agent_workflows/checklists/pre_edit_scope.md` |
| Citation reality, BibTeX, DOI, or source-support question | Citation verification | `agent_workflows/checklists/citation_verification.md` |
| Summary table, model count, governing-law row | Table audit before edit | `agent_workflows/checklists/post_edit_validation.md` |
| MOOSE kernel/material/action planning | Implementation traceability | `moose_app/doc/theory_traceability.yml` |
| Validation case or benchmark design | Validation matrix | `validation/validation_matrix.yml` |
| Input deck generation or run setup | Structured problem spec | `agent_workflows/schemas/problem_spec.schema.json` |
| Failed MOOSE run | Layered failure triage | `agent_workflows/runbooks/moose_failure_triage.md` |

## Response Choice

- For interpretive questions, cite manuscript source locations and answer before
  proposing edits.
- For edit requests, make the smallest scoped source change and then validate
  labels, references, and displays affected by the edit.
- For citation verification, check both metadata reality and source support for
  the manuscript claim before changing prose or BibTeX.
- For implementation or validation planning, map every object or test back to a
  manuscript equation, section, assumption, or special-case reduction.
- For underspecified simulation setup, ask only the questions that change the
  governing equations, closures, boundary conditions, initial conditions, or
  validation target.
