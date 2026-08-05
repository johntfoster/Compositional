---
name: deck-assembler
description: Generate reproducible MOOSE input decks from a structured problem specification and hash-verified registry blocks, with dependency, dimension, include-order, and scenario-content checks plus a provenance manifest. Use when creating regression, benchmark, production, or reusable simulation decks from approved input fragments rather than writing kernel or material objects directly.
---

# Assemble Verified Decks

Read `AGENTS.md`, `moose_app/input/AGENTS.md`, and the applicable structured
problem specification. Use only verified registry IDs in
`deck_assembly.blocks`.

Generate a deck and its provenance manifest with:

```bash
python3 agent_workflows/scripts/verified_blocks.py assemble \
  --spec agent_workflows/specs/<problem>.problem.json \
  --output moose_app/input/assemblies/<problem>.i
```

Use `--force` only to regenerate an existing generated deck from its declared
specification. The command rejects candidate blocks, missing exact
dependencies, dimension mismatches, duplicate IDs, and scenario includes that
define protected object sections.

Keep scenario includes limited to permitted problem-specific data such as
functions, initial conditions, boundary data, postprocessors, and outputs.
Move reusable residual, material, and user-object definitions into canonical
fragments and verify them through `$verified-block-promotion`.

Always run `$deck-integrity-validator` after assembly and before a MOOSE run.
Treat both the generated deck and `.manifest.yml` sidecar as generated products;
change the problem specification or selected block versions and regenerate.
