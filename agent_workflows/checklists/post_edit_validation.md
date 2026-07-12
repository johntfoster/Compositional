# Post-Edit Validation Checklist

Use after modifying repository artifacts.

## Manuscript

- Reopen the edited source span and nearby displays.
- Search for stale labels, references, old notation, and duplicated local
  equations.
- If equation labels, numbering, citations, or display layout changed, compile
  twice from `main.tex`, preferably through LaTeX Workshop.
- Inspect warnings relevant to the edited area: undefined refs, citation
  failures, overfull boxes, and display-layout regressions.
- For summary tables, compare rows against the governing equations rather than
  against nearby prose only.

## Implementation

- Confirm every new MOOSE object has a traceability note or source equation when
  the connection is non-obvious.
- Run the narrowest relevant build or test target available.
- If no executable test exists, update `moose_app/doc/theory_traceability.yml`
  or implementation notes with the remaining gap.

## Validation

- Update `validation/validation_matrix.yml` when a new case, benchmark, expected
  observable, or status changes.
- Keep generated run outputs out of durable reference-data locations unless they
  have been curated.

## Agent Workflow

- Validate schema or template changes with a representative minimal example.
- Keep templates, runbooks, and checks consistent with the current MOOSE object
  names and validation matrix entries.
