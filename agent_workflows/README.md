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

Canonical skills live in `../agent_environment/skills/`. Use
`../tools/agentctl route QUERY` to inspect routing and `activate HARNESS QUERY`
to install only the skills needed for that request. Dependency profiles are
provisioned only with an explicit `--provision` or `provision PROFILE`; verified
deck tooling uses the `verified-decks` profile, while MOOSE setup uses the
separate `moose` profile.

## Current Framework Assets

- `decision_trees/request_router.md` -- first-pass routing for manuscript,
  MOOSE, validation, and agent-workflow tasks.
- `decision_trees/manuscript_edit.md` -- scoped manuscript edit workflow.
- `decision_trees/equation_number_lookup.md` -- rendered equation number lookup
  workflow.
- `checklists/pre_edit_scope.md` -- pre-edit scope and traceability checks.
- `checklists/citation_verification.md` -- citation reality, source-support,
  DOI, and BibTeX verification workflow.
- `checklists/post_edit_validation.md` -- post-edit validation checks.
- `schemas/problem_spec.schema.json` -- structured problem specification schema
  for generated MOOSE decks, including verified block selection.
- `../moose_app/input/verified_block_registry.yml` -- exact content digests,
  semantic object inventories, versions, status, and verification evidence for
  every canonical input fragment.
- `scripts/verified_blocks.py` -- deterministic inventory, candidate sync,
  promotion, assembly, and integrity-validation commands used by the four
  repository-local deck-block skills.
- `runbooks/moose_failure_triage.md` -- layered diagnosis path for failed
  generated or hand-written MOOSE runs.
- `runbooks/spe1_acceptance_status.md` -- authoritative SPE1 Case 1 acceptance
  status: what has been tried, where the attempt records/source/templates live,
  current state, and remaining work.
