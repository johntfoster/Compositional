---
name: latex-manuscript-request-router
description: Route LaTeX manuscript and repository requests in the multicomponent reactive flow workflow. Use when an agent must classify a request as interpretive manuscript work, scoped source edit, derivation audit, rendered-equation lookup, citation check, display cleanup, MOOSE implementation planning, validation planning, agent-workflow setup, or cross-track planning before acting.
---

# LaTeX Manuscript Request Router

Use this skill as the first routing layer for repository tasks that are not
obviously a one-line shell command.

## Workflow

1. Read the repository `AGENTS.md` and `VISION.md`.
2. If the task is manuscript-related, also read `main.tex` and `defs.tex`.
3. Open `agent_workflows/decision_trees/request_router.md` when it exists.
4. Classify the immediate owner:
   - `theory-manuscript`
   - `moose-implementation`
   - `validation`
   - `agent-workflow`
   - `cross-track-planning`
5. Select the narrower workflow:
   - rendered equation number -> equation resolver or equation-integrity skill
   - source edit -> manuscript edit decision tree
   - notation change -> notation propagation planner
   - summary table -> summary table auditor
   - reservoir special case -> reservoir specialization mapper
   - MOOSE object plan -> MOOSE residual traceability planner
   - generated deck/problem spec -> agent deck workflow validator

## Output

For planning or interpretive responses, state the selected route and the source
files that control the answer. For edit requests, route quickly and then make
the scoped edit; do not stop at classification unless the user asked for a plan.
