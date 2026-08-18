---
name: deck-block-inventory
description: Inventory MOOSE input fragments and every named input object, reconcile the include tree with the fragment catalog and verified-block registry, and report candidate or locked coverage. Use when adding or splitting .i fragments, auditing individual Kernels/DGKernels/Materials or related objects, checking whether every reusable block is accounted for, or preparing blocks for verification.
---

# Inventory Deck Blocks

Work from the repository root. Read `AGENTS.md`, `VISION.md`, and
`moose_app/input/AGENTS.md` before acting.

Run the deterministic inventory:

```bash
python3 tools/run_python_profile.py verified-decks agent_workflows/scripts/verified_blocks.py inventory
```

Use `--output <repository-path>` only when a durable report is requested. The
inventory scans canonical includes, templates, tests, and examples. It reports
each named MOOSE object with its section, type when present, source lines, and
content digest.

Before accepting the inventory, run:

```bash
python3 tools/run_python_profile.py verified-decks agent_workflows/scripts/verified_blocks.py validate
```

If a new canonical include is absent from `fragment_catalog.yml`, add its
stable ID, path, compatibility, dependencies, and provided capabilities. Then
refresh candidate records with `sync-candidates`. This command may update only
candidate records; it preserves verified records byte-for-byte.

Do not edit a verified fragment or its registry digest. Route any intentional
change through `$verified-block-promotion` as a new semantic version.
