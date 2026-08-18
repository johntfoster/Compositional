# Manuscript Edit Decision Tree

Use this for manuscript edits after the request has been routed to the theory
track.

## Scope

1. Identify the narrowest user-specified target: section, paragraph, equation,
   label, table, or symbol.
2. If the user says "only", "just", "do not change outside", or names a single
   line/equation, treat that as a hard scope boundary.
3. Check for `% AGENT-LOCK-BEGIN` and `% AGENT-LOCK-END`. Edit locked source
   only when the user explicitly names that locked target.

## Before Editing

Run the pre-edit checklist in `agent_workflows/checklists/pre_edit_scope.md`.

If the edit changes notation, first make an impact map:

- defining prose
- state sets and constitutive arguments
- chain-rule terms
- thermodynamic forces and restrictions
- boxed or numbered equations
- summary tables
- downstream prose and references
- scalar or special-case reductions

## Edit Rules

- Preserve existing manuscript notation unless the request explicitly changes it.
- Follow `AGENTS.md`: number and descriptively label every displayed identity
  introduced by an agent unless the author explicitly requests otherwise.
- Do not introduce new helper symbols such as `L`, `R`, `Q`, or `C` without user
  approval.
- Keep displayed equations grammatical: punctuation belongs to the sentence.
- Avoid chained one-line multiple-equals numbered displays; use aligned steps.
- Use automatic delimiters instead of manual `\Big`-style delimiter sizing.

## After Editing

Run the post-edit checklist in `agent_workflows/checklists/post_edit_validation.md`.
Compile only when the edit affects manuscript build behavior, labels, references,
equation numbers, citations, or display layout.
