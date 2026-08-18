# Verified input-block policy

These instructions apply to every file below `moose_app/input/`.

- Read `verified_block_registry.yml` before editing a canonical include. A block
  with `status: verified` is locked and has a versioned protected payload under
  `agent_environment/verified-input-blocks/`. Use that block only through assembly; do not
  edit either payload, its include-tree source, digest, object inventory,
  version, or evidence.
- Stop if a requested change touches a verified block. Obtain the author's explicit
  authorization, run the mapped MOOSE tests, and use the repository-local
  `verified-block-promotion` skill to record a higher semantic version.
- Candidate fragments may be edited during implementation and verification.
  Keep `fragment_catalog.yml` complete, then use `deck-block-inventory` and
  `sync-candidates` to refresh the candidate digest and object inventory.
- Build reusable regression, benchmark, and production decks with the
  `deck-assembler` skill. Generated decks may define substitutions and include
  scenario-local data, but protected MOOSE object sections must come from
  verified blocks.
- Run the `deck-integrity-validator` skill after every edit in this directory
  and before running or accepting an assembled deck. Treat a lock violation as
  a stop condition; do not absorb it by editing the registry.
- Current working-tree changes may belong to another agent. Re-read the target
  file and registry immediately before editing, and preserve unrelated work.
