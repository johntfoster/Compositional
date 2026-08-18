# AI-use provenance workflow

This directory separates human-maintained provenance facts from generated
disclosures:

- `ai-use.yml` is the authoritative structured registry. It uses JSON syntax,
  which is a dependency-free subset of YAML.
- `AI_USE.md` is the extended public record.
- `ai_use_statement.tex` is the concise journal-facing statement.

Edit the registry when the tools, uses, verification practices, public URL, or
submission state change. Do not edit the generated files directly.

## Generate or check the disclosure

From the repository root, generate a statement covering the current `HEAD`:

```sh
python3 tools/update_ai_disclosure.py
```

Check that the generated files agree with the registry and current `HEAD`:

```sh
python3 tools/update_ai_disclosure.py --check
```

The generator derives the first commit that touched a configured manuscript
path. It records unknown tool versions and repository identifiers explicitly;
it does not infer missing historical facts.

## Install the versioned commit hook

Git does not activate repository hooks when a repository is cloned. Enable the
versioned hooks once in each clone:

```sh
git config core.hooksPath .githooks
```

On each commit, `.githooks/pre-commit` regenerates the two disclosure files for
the pending commit date and stages only those generated files. Changes to
`ai-use.yml` remain under the author's explicit staging control.

## Freeze a submission

Keep `disclosure.status` set to `active` during manuscript development. Preview
the freeze without changing Git:

```sh
python3 tools/manuscript_release.py freeze --tag manuscript-submission-v1
```

At submission:

1. Commit the final manuscript changes normally.
2. Run `python3 tools/manuscript_release.py freeze --tag
   manuscript-submission-v1 --apply`. This creates the annotated tag, freezes
   the registry, and regenerates both disclosures.
3. Commit the registry and generated disclosures as a provenance-only follow-up
   commit.

The frozen disclosure derives its final date from the tagged manuscript
commit. It identifies that snapshot by tag rather than embedding the containing
commit's own hash, which would be self-referential. A later manuscript revision
should return the registry to `active` until a new submission tag is created.

## Extract the future manuscript repository

`manuscript-export.json` lists the manuscript, research context, provenance,
and manuscript-specific agent workflow paths whose history belongs in the
eventual public manuscript repository. Audit it while this repository remains
the combined source:

```sh
python3 tools/manuscript_release.py audit
```

Preview the history-filtering commands without installing or changing anything:

```sh
python3 tools/manuscript_release.py extract --dry-run
```

When separation is desired, provision the publication profile and extract into
the ignored runtime area:

```sh
tools/agentctl provision publication
python3 tools/manuscript_release.py extract
```

The extraction uses `git-filter-repo` in a disposable clone under
`.agent-runtime/exports/`; it does not rewrite this combined repository. Review
PDF redistribution rights and sensitive history before publishing the result.

## Scope of the evidence

The Git history records changes accepted into the repository. It is not a
complete transcript of prompts, rejected suggestions, transient output, or
historical sessions that were not otherwise documented. The public statement
preserves this boundary so that publication of the repository does not
overstate what its history proves.
