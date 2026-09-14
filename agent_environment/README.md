# Compatibility layer

Reusable skills are canonical in the pinned `.agent/shared` submodule.
Entries under `agent_environment/skills/` are compatibility symlinks for older
commands. New routing uses `tools/agentctl` and `agent-profile.json`.

Compositional and verified-deck skills are canonical in `agent_local/skills/`.
Verified input blocks and dependency requirements remain project-local here.
