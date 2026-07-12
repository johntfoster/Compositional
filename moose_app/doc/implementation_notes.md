# Implementation Notes

This file is the first durable map between the compositional theory manuscript,
the companion implementation paper, and future MOOSE objects.

For object-level traceability, also update `theory_traceability.yml`. For
paper-level equation mapping, update `implementation_paper/equation_to_moose_map.yml`.

## Governing Reference Configuration

Finite-element mechanics work should be written on the reference configuration
of the solid skeleton unless John explicitly changes that decision. Weak forms,
stress measures, mixture mass terms, reaction/source terms, and thermodynamic
forces should be pulled back consistently before kernels are designed.

## Initial MOOSE Design Rules

- Do not port the earlier three-phase app wholesale.
- Use MOOSE automatic differentiation objects by default.
- Put thermodynamic free energies, EOS closures, activity models, and phase
  equilibrium closures in AD materials or shared user objects before writing
  residual kernels.
- Kernels should consume already-defined AD material properties whenever
  possible, so each residual remains traceable to a weak-form term.
- Every future kernel/material/action must cite the controlling equation label
  or section from the theory manuscript or companion implementation paper.

## Planned Object Families

| Family | Directory | Purpose | Status |
| --- | --- | --- | --- |
| App shell | `include/base`, `src/base` | Register the MOOSE application | scaffolded |
| Kinematics | `materials` | Solid-skeleton deformation, pull-backs, Jacobians | planned |
| Thermodynamics | `materials`, `userobjects` | Free energies, chemical potentials, pressure relations | planned |
| Phase behavior | `materials`, `userobjects` | Phase split, saturation/composition constraints | planned |
| Transport | `kernels`, `materials` | Component/phase mass weak forms and flux closures | planned |
| Mechanics | `kernels`, `materials` | Reference-solid-skeleton momentum balance | planned |
| Reactions | `materials`, `kernels` | Reaction rates, source terms, affinities | planned |
| Actions | `actions` | Generate consistent variable/kernel/material blocks | planned |
| Validation | `test`, `examples` | Regression decks and benchmark reductions | planned |

## Open Design Question

The first architecture question is how far MOOSE AD can carry derivatives of
free-energy expressions supplied through input files or EOS objects. The answer
will determine whether the app exposes free energies as parsed expressions,
compiled material subclasses, tabulated EOS user objects, or a hybrid of these.

Current answer:

- `ADDerivativeParsedMaterial` and `DerivativeParsedMaterial` can generate
  derivatives of scalar thermodynamic potentials supplied as parsed
  expressions. This is the likely path for user-specified Helmholtz/Gibbs
  potentials, chemical potentials, oil/compositional derivatives, Hessians,
  activity-style models, and other scalar constitutive terms.
- MOOSE AD will propagate Jacobians through AD kernels and AD materials when
  residuals consume AD variables and AD material properties.
- Explicit code is still required for the topology of the equations: weak-form
  residuals, reference/current transformations, tensor kinematics, phase
  equilibrium algorithms, flash/EOS roots, tabulated data wrappers, constraints,
  flux closures, and regularization logic.

Architectural consequence: keep the thermodynamics layer declarative where
possible, but keep the mechanics, transport, closure, and reaction residuals
as explicit, inspectable MOOSE objects.
