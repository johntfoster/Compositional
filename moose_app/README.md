# Multicomponent Reactive Flow MOOSE App

This directory is the clean MOOSE application scaffold for the compositional
reacting-mixture implementation. It is intentionally independent of the earlier
three-phase/Talha application: use that code as technical memory and design
evidence, not as a code base to copy.

Current implemented scope:

- Input-deck phase registration with arbitrary phase names and per-phase
  momentum-model selection.
- Solid-reference kinematics, registered mobile-phase history kinematics,
  Helmholtz EOS closure materials, restricted two-phase constant-K split,
  reference component-balance kernels, Darcy reference-flux materials, selectable
  full/relative-flux phase momentum objects, and a quasi-static reference-solid
  momentum slice.
- Regression tests under `test/tests` tied to `doc/theory_traceability.yml`,
  `../implementation_paper/equation_to_moose_map.yml`, and
  `../validation/validation_matrix.yml`.

## Layout

- `include/base/`, `src/base/` - app registration and executable entry point.
- `include/kernels/`, `src/kernels/` - weak-form residual kernels.
- `include/materials/`, `src/materials/` - thermodynamic, kinematic, and
  constitutive materials.
- `include/actions/`, `src/actions/` - future input-deck assembly helpers.
- `include/bcs/`, `src/bcs/` - future boundary conditions.
- `include/userobjects/`, `src/userobjects/` - future EOS, phase-equilibrium,
  reaction-network, and tabulation helpers when material properties need shared
  state.
- `test/` - MOOSE regression tests.
- `examples/` - human-readable decks that illustrate validated reductions.
- `doc/implementation_notes.md` - design notes and equation-to-code mapping.

## Build

```bash
tools/agentctl provision moose
agent_environment/skills/setup-moose-conda/scripts/moose_conda_env.sh run -- make -C moose_app -j1
```

The expected executable name is `multicomponent_reactive_flow-opt`.
