# Infrastructure migration — 2026-09-19

This maintenance pass changes repository infrastructure only. Manuscript source,
bibliographies, figures, submitted artifacts, and pre-existing local work are
protected. `research-project.yml` records the local authority, exact shared pin,
publication surfaces, and unfinished migration work. It uses JSON syntax, which
is valid YAML, so baseline checks need only the Python standard library.

## Commit protection

The tracked pre-commit hook defaults to manuscript-freeze mode, including in a
fresh clone. It rejects protected staged paths (including deletions and renames)
and exits before legacy disclosure/provenance generators can rewrite TeX.
The six-section commit-message checks still run. Install tracked hooks with
`tools/agentctl hooks install` after cloning.

The local setting `research.manuscriptFreeze=true` makes the freeze explicit.
Only a later task explicitly authorizing manuscript changes may end this freeze:
review the maintenance manifest and set `git config --local
research.manuscriptFreeze false` for that task. This is not permission to change
manuscripts during the current migration. Hooks protect commits, not arbitrary
filesystem writes; agents must also obey the manuscript prohibition before edits.

## Verification and remaining work

This pass checks manifest authority paths and workflow pins, protected-file
hashes, infrastructure-only hook execution, rejection of protected paths and
renames, and acceptance/rejection of synthetic process-log messages. Tests use
temporary repositories; no manuscript build or scientific simulation is run.
These checks are infrastructure evidence, not scientific validation.

The shared core is explicitly pinned to v0.2.0; the program and shared-core
repositories are authorized infrastructure exceptions. The new environment is a
digest-pinned infrastructure/source-inspection environment, not proof of a
numerical reproduction or a manuscript build. Startup initializes the shared pin,
installs hooks, and checks the project manifest without changing manuscripts.

## Reproduce infrastructure checks

```sh
git submodule update --init --recursive
tools/agentctl hooks install
tools/agentctl check
python3 .agent/shared/tools/research_project.py check
python3 .agent/shared/tools/research_project.py site
python3 .agent/shared/tools/research_project.py links .agent-runtime/site
python3 .agent/shared/tools/research_project.py package
```

Read local AGENTS and scientific setup instructions before any separately
authorized scientific test. Existing site source and scientific assets remain
unchanged; the metadata companion site links to their authoritative repository.
Licensing and hosted environment results are explicit manifest fields, never
inferred from the existence of a URL or configuration.
