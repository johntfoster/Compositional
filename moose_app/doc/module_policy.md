# MOOSE module policy

The application builds against the MOOSE framework and the Solid Mechanics
module. Its finite-deformation mixture mechanics, phase closure, transport,
reactions, black-oil PVT, and stabilization objects are implemented in
`moose_app/src/` and registered by `MulticomponentReactiveFlowApp`. The
application label is registered explicitly before its objects and actions are
loaded. The
application directly registers Solid Mechanics for the
`ADMaterialTensorAverage` postprocessor used by the nonlinear-Biot tests. It
intentionally does not call the blanket MOOSE `ModulesApp` registrar, so a
shared MOOSE checkout built previously with optional modules enabled cannot
reintroduce their registrations.

`moose_app/Makefile` fixes `ALL_MODULES := no`, enables Solid Mechanics, and
disables every other optional MOOSE module. In particular, PorousFlow is
disabled. The repository has no `PorousFlow` headers, input-object types, or
link-time use. This keeps the application from linking the PorousFlow stack and
its transitive Chemical Reactions, Fluid Properties, and Misc dependencies.

The following modules are intentionally disabled: Chemical Reactions, Contact,
Electromagnetics, External PETSc Solver, Fluid Properties, FSI, Functional
Expansion Tools, Geochemistry, Heat Transfer, Level Set, Misc, Navier--Stokes,
Optimization, Peridynamics, Phase Field, PorousFlow, Ray Tracing, RDG, Reactor,
Richards, Scalar Transport, Solid Properties, Stochastic Tools, Subchannel,
Thermal Hydraulics, and XFEM. Framework objects such as
`ADParsedMaterial`, `ADDerivativeParsedMaterial`, finite-volume kernels, and
rank-two tensors remain available without those optional modules.

Build with the fixed wrapper from the repository root:

```bash
cmake -P moose_app/cmake/build_opt.cmake
```

MOOSE 0.9 uses a Makefile application interface. The CMake script is a fixed,
noninteractive wrapper around that supported interface; it does not configure
or modify the durable MOOSE checkout. To add a MOOSE module, first establish a
source or input-deck dependency, change the corresponding `:= no` entry in the
Makefile, restore a deliberately scoped module registration in the application,
and update this policy and the setup skill in the same change.
