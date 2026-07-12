# MOOSE Failure Triage Runbook

Use this when a generated or hand-written MOOSE input fails. Diagnose in layers
and stop at the first layer that explains the failure.

## 1. Input Syntax

- Check block names, parameter spelling, file paths, and object registration.
- Confirm variables referenced by kernels, materials, BCs, ICs, and outputs
  exist.
- Confirm generated decks match the selected schema or template.

## 2. Missing Objects

- Identify whether the required kernel, material, user object, action, BC, or
  postprocessor exists in `moose_app/`.
- If the object is planned but absent, update traceability notes instead of
  inventing input syntax.

## 3. Variable and Material Consistency

- Confirm every residual consumes the expected AD material properties.
- Check units and reference/current configuration choices.
- Check phase, component, and mechanism indices against the manuscript notation.

## 4. Solver and Executioner

- Check nonlinear tolerances, linear solver, preconditioning, time step, and
  scaling.
- If the physics is stiff, reduce the case before changing the model.

## 5. Discretization and Stabilization

- Identify FE versus FV variables explicitly.
- Surface upwinding, stabilization, and displaced-mesh assumptions.
- Record any stabilization not present in the manuscript as an implementation
  assumption.

## 6. Model Assumptions

- Revisit closures, boundary conditions, initial conditions, and validation
  target.
- If the requested scenario requires a theory approximation, record it in
  `moose_app/doc/theory_traceability.yml` or the validation matrix.

## Report Format

Report:

- first failing layer
- exact error symptom
- controlling file or object
- proposed narrow fix
- whether the fix changes theory, implementation, validation, or workflow files
