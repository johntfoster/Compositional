---
name: verified-block-promotion
description: Promote a tested MOOSE input fragment from candidate to verified, or replace a verified fragment through an explicitly authorized semantic-version change with validation evidence and hash locking. Use when a reusable .i fragment has passed its governing regression, MMS, benchmark, or acceptance tests; when an authorized user requests a locked-block change; or when recording a new verified version.
---

# Promote a Verified Block

Read `AGENTS.md`, `moose_app/input/AGENTS.md`, the catalog entry, and the mapped
validation evidence. Promotion changes validation governance and requires the
user's explicit authorization.

1. Run `$setup-moose-conda` before building or running MOOSE.
2. Run the exact tests that exercise the complete fragment and record their
   durable test-file selectors as `path::selector` references.
3. Confirm the fragment's catalog dependencies, provided capabilities,
   dimension, and object inventory.
4. Promote the candidate with a semantic version:

```bash
python3 tools/run_python_profile.py verified-decks agent_workflows/scripts/verified_blocks.py promote \
  --id <catalog-id> \
  --version <MAJOR.MINOR.PATCH> \
  --evidence <test-file>::<test-selector> \
  --authorized-by <user-or-reviewer> \
  --approval-ref <issue-commit-or-conversation-reference>
```

Promotion writes a new versioned payload under the protected
`agent_environment/verified-input-blocks/` store. Approve the narrow protected-path write
when prompted. The command never overwrites a different payload at the same
block ID and version.

To replace a verified version, require the exact current digest through
`--previous-sha` and select a higher semantic version. Never use
`sync-candidates` to alter a verified record.

After promotion, run the integrity validator and the same tests again. A change
to either the protected payload or its include-tree source is a lock violation.
Open a new authorized version change instead of repairing a digest in place.
