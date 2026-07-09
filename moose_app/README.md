# Multicomponent Reactive Flow MOOSE App

This directory is the clean MOOSE application scaffold for the compositional
reacting-mixture implementation. It is intentionally independent of the earlier
three-phase/Talha application: use that code as technical memory and design
evidence, not as a code base to copy.

Current scope:

- Provide a buildable MOOSE app shell.
- Keep source categories ready for kernels, materials, actions, boundary
  conditions, user objects, tests, and examples.
- Record implementation decisions before residual objects are written.
- Tie future MOOSE objects to equations in the theory manuscript and companion
  implementation paper.

No physics kernels have been implemented yet.

## Layout

- `include/base/`, `src/base/` - app registration and executable entry point.
- `include/kernels/`, `src/kernels/` - future weak-form residual kernels.
- `include/materials/`, `src/materials/` - future thermodynamic, kinematic, and
  constitutive materials.
- `include/actions/`, `src/actions/` - future input-deck assembly helpers.
- `include/bcs/`, `src/bcs/` - future boundary conditions.
- `include/userobjects/`, `src/userobjects/` - future EOS, phase-equilibrium,
  reaction-network, and tabulation helpers when material properties need shared
  state.
- `test/` - MOOSE regression tests once objects exist.
- `examples/` - human-readable decks that illustrate validated reductions.
- `doc/implementation_notes.md` - design notes and equation-to-code mapping.

## Build

```bash
cd moose_app
eval "$(~/miniconda3/bin/conda shell.bash hook)"
conda activate moose
export MOOSE_DIR=~/.local/moose
make -j$(nproc)
```

The expected executable name is `multicomponent_reactive_flow-opt`.
