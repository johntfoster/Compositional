# Input-block verification policy

These instructions apply to verification work below `moose_app/test/`.

- Read `../input/AGENTS.md` and
  `../input/verified_block_registry.yml` before changing a test deck that uses
  reusable input fragments.
- Test success does not itself lock a fragment. Record the exact durable test
  file and selector, obtain the author's explicit authorization, and use the
  `verified-block-promotion` skill.
- Do not edit a verified input fragment while repairing a test. Diagnose the
  candidate implementation, scenario-local data, solver configuration, or an
  explicitly authorized new block version.
- Run `deck-integrity-validator` after verification changes so a passing
  physics test cannot conceal a changed locked fragment.
- Never weaken, skip, or redefine verification evidence to preserve a block's
  verified status.
