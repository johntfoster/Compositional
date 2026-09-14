---
name: deck-integrity-validator
description: Verify the MOOSE input-block catalog and registry, enforce exact hashes for verified fragments, compare semantic object inventories, validate promotion evidence, and check generated deck manifests and resolved includes. Use before running or accepting assembled decks, after edits under moose_app/input, in CI, during code verification, or whenever a locked fragment may have changed.
---

# Validate Deck Integrity

Read `AGENTS.md` and `moose_app/input/AGENTS.md`. Run the repository-wide gate:

```bash
python3 tools/run_python_profile.py verified-decks agent_workflows/scripts/verified_blocks.py validate --all-assemblies
```

For a specific generated deck, pass its sidecar manifest:

```bash
python3 tools/run_python_profile.py verified-decks agent_workflows/scripts/verified_blocks.py validate \
  --manifest moose_app/input/assemblies/<deck>.i.manifest.yml
```

The gate checks one-to-one catalog/registry coverage, exact file and object
digests, evidence references, verified versions, resolved include provenance,
and direct protected-object definitions in generated or scenario files.

Treat `LOCK VIOLATION` as a stop condition. Do not update a verified digest,
edit the registry manually, weaken a test, or regenerate evidence to absorb the
change. Restore the verified source or obtain explicit authorization and use
`$verified-block-promotion` to create a higher version.

Candidate changes require a catalog review followed by:

```bash
python3 tools/run_python_profile.py verified-decks agent_workflows/scripts/verified_blocks.py sync-candidates
python3 tools/run_python_profile.py verified-decks agent_workflows/scripts/verified_blocks.py validate
```
