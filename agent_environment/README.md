# Portable agent environment

`tools/agentctl` is the repository-owned entry point for harness-independent
skill discovery and dependency routing. It uses only the Python standard
library and discovers the repository root through Git, so its behavior does not
depend on the clone location or user name.

The canonical skills are the packages under `agent_environment/skills/`. Dependency
profiles are declared in `agent_environment/dependencies.json`. A route selects
profiles from query triggers and matched skill names. The first provision of a
selected profile runs only that profile's `provision` commands and records a
fingerprint below the local Git directory. Later invocations skip the commands
unless the profile changes.

Common commands are:

```sh
tools/agentctl skills
tools/agentctl profiles
tools/agentctl route "resolve equation 74"
tools/agentctl activate codex "resolve equation 74" --dry-run
tools/agentctl activate codex "resolve equation 74"
tools/agentctl activate codex "retrieve research PDFs" --provision
tools/agentctl check
tools/agentctl hooks install
```

`route` is read-only unless `--provision` is explicitly supplied. `activate`
copies only the matched canonical skills into the selected harness directory.
Pass `--provision` when the relevant query also requires that profile's
dependencies. The `--dry-run` option shows skill installation,
provisioning, and hook configuration without changing local state. Harness
locations are declarative, and `--target` supports an additional harness
without changing the CLI. `hooks install` sets the local Git `core.hooksPath` to the
repository-relative `.githooks` directory. Cloning alone cannot install Git
hooks, so each new clone must invoke this command once.

If a managed environment mounts its normal harness directory read-only,
`agentctl` places the copy under `.agent-runtime/harnesses/HARNESS/skills` and
reports that fallback. The canonical package remains directly readable under
`agent_environment/skills/`, so repository routing does not depend on the copy.
Use `tools/agentctl check --profile manuscript` (or another profile name) to
check one intentionally lazy dependency profile after provisioning it.

Provisioning commands are argument arrays, not shell strings. They run from the
repository root and should refer only to repository-relative executables and
configuration. Keep heavyweight tools in their own profiles so an unrelated
manuscript query cannot provision a simulator toolchain.
