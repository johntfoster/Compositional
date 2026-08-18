# MOOSE input hierarchy

This directory contains reusable input fragments for agent-driven setup of the
registered multicomponent reactive-flow app. Scenario decks include fragments in
this order:

1. `includes/common/defaults.i`
2. one mesh fragment from `includes/mesh/`
3. field-space fragments from `includes/fields/`
4. dimension-specific kinematics and mechanics material fragments
5. flux, tau, reaction, and EG operator fragments
6. scenario-local functions, boundary data, outputs, and postprocessors

Coupled production and MMS decks must use Q2 Lagrange solid displacement
variables and EG pressure/tau pairs. Material-only decks that only report
elementwise diagnostic material properties may keep monomial auxiliary fields.
The catalog in `fragment_catalog.yml` records compatibility rules for these
fragments.

`verified_block_registry.yml` accounts for every catalog fragment and every
named MOOSE object within it. Candidate records may evolve during implementation
and verification. A verified record binds the exact source bytes and semantic
object inventory to a version, test evidence, promotion authorization, and a
protected snapshot under `agent_environment/verified-input-blocks/`. The assembler reads
the protected snapshot. Verified fragments are assembly-only inputs; changes
proceed through a new authorized version.

Use the repository-local skills for each operation:

1. `deck-block-inventory` accounts for fragments and individual input objects.
2. `verified-block-promotion` records tested, authorized versions.
3. `deck-assembler` generates decks and provenance manifests from verified IDs.
4. `deck-integrity-validator` rejects stale candidates, lock violations, and
   assemblies whose resolved includes differ from their manifests.
