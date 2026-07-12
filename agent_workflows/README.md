# Agent Workflows

This directory is for agent-facing simulator assets that are not MOOSE source
code and are not manuscript prose.

Planned contents:

- input-deck templates
- parameter schemas
- model-selection checklists
- validation checklists
- run recipes
- postprocessing recipes
- failure-diagnosis notes

Do not place transient run output here. Durable workflow assets should point
back to validated MOOSE examples and the equations they instantiate.

## Current Framework Assets

- `decision_trees/request_router.md` -- first-pass routing for manuscript,
  MOOSE, validation, and agent-workflow tasks.
- `decision_trees/manuscript_edit.md` -- scoped manuscript edit workflow.
- `decision_trees/equation_number_lookup.md` -- rendered equation number lookup
  workflow.
- `checklists/pre_edit_scope.md` -- pre-edit scope and traceability checks.
- `checklists/post_edit_validation.md` -- post-edit validation checks.
- `schemas/problem_spec.schema.json` -- structured problem specification schema
  for future generated MOOSE decks.
- `runbooks/moose_failure_triage.md` -- layered diagnosis path for failed
  generated or hand-written MOOSE runs.
