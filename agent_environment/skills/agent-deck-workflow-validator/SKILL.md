---
name: agent-deck-workflow-validator
description: Validate agent-generated MOOSE problem specifications, input-deck templates, run recipes, and troubleshooting workflows. Use when creating or checking structured problem specs, generated MOOSE decks, schemas, parameter templates, validation checks, run commands, postprocessing recipes, or failed simulation setup in the agent-assisted simulator workflow.
---

# Agent Deck Workflow Validator

Use this skill for agent-facing simulator workflow artifacts.

## Workflow

1. Read `AGENTS.md` and `VISION.md`.
2. Open `agent_workflows/schemas/problem_spec.schema.json` when validating a
   structured problem spec.
3. Check required categories:
   - variables
   - kernels or FV kernels
   - materials and user objects
   - boundary conditions
   - initial conditions
   - units
   - mesh and displaced-mesh assumptions
   - executioner and solver settings
   - outputs and postprocessors
   - validation matrix entry
   - manuscript or implementation-paper basis
4. If a generated deck fails, use
   `agent_workflows/runbooks/moose_failure_triage.md`.
5. Ask clarification questions only when the missing information changes the
   governing equations, closures, boundary conditions, initial conditions, or
   validation target.

## Output

Report schema/template problems as actionable blocking items. For valid specs,
state the selected validation matrix entry and the MOOSE object families needed.
