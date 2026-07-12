# Pre-Edit Scope Checklist

Use before modifying manuscript, implementation, validation, or agent-workflow
files.

## Common

- Confirm the immediate track owner: theory manuscript, MOOSE implementation,
  validation, agent workflow, or cross-track planning.
- Identify the narrowest user-requested scope.
- Check `git status --short` and avoid reverting unrelated user changes.
- Identify downstream tracks that need follow-up, but do not edit them unless
  the request covers them.

## Manuscript

- Read `main.tex` and `defs.tex` before interpreting notation.
- Resolve rendered equation numbers through active build artifacts.
- Inspect source around labels, references, and displayed equations.
- Check for locked regions.
- For notation changes, list definitions, derivatives, inverses, state sets,
  restrictions, table rows, and special-case reductions that may be affected.

## Implementation

- Map the proposed object to a manuscript equation, section, or special-case
  reduction.
- State whether the object is a kernel, material, user object, action, boundary
  condition, test, example, or documentation item.
- Record any closure, linearization, stabilization, variable choice, or weak-form
  assumption not present in the theory manuscript.

## Validation

- Identify the physical regime, governing reduction, variables, observables,
  pass/fail criterion, and expected output files.
- Decide whether the case is a routine regression test, smoke test, expensive
  benchmark, or reference-data generator.
