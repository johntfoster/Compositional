# Pick-and-choose physics templates

These are copy templates, not directly parsed input files. Replace every
`@TOKEN@` and copy the selected object blocks into a MOOSE input deck. Atomic
objects share AD material properties, so selecting more terms changes the weak
form without duplicating expensive constitutive evaluations.

The templates use CG variables and optional P0 EG enrichments. They do not use
finite-volume discretization.

## Composition rules

Composition physics is opt-in. A noncompositional model must not instantiate
mass-fraction fields, storage multipliers, composition-projection materials, or
their algebraic kernels. A compositional manuscript-theory model selects
`theory_composition_projection.i.template`; this implements the current
theory Eqs. (182)--(183). The older `ADRegisteredPhaseFlashMaterial` is
comparison-only and must not be included in the manuscript-theory hierarchy.

For each component balance select one storage block, zero or more independently
named flux blocks (phase advection, dispersion, diffusion), and all applicable
source blocks (conversion, wells, exchange).

For a full phase momentum equation select inertia when retained, every stress
contribution, the pressure/capillary/electrical scalar-gradient contributions,
body and pairwise interaction sources, drag, and one conversion-insertion block
for every mechanism that changes that phase mass.

Any model in which mass transforms between phases must also select the complete
nonequilibrium transfer preset:

1. Helmholtz/electric-enthalpy chemical or electrochemical potentials;
2. CG+EG transfer potential `tau` and its thermodynamic evolution equation;
3. each phase material derivative of `tau`;
4. generalized affinity including transfer-work offsets;
5. an equilibrium or finite-rate kinetic equation;
6. stoichiometric mass sources;
7. conversion momentum insertion;
8. conversion power/dissipation diagnostics.

Deleting any item produces a different, thermodynamically incomplete model.
The isothermal template is a deliberate reduction of the two-temperature
energy preset, not a reason to delete the general energy implementation.

## Templates

- `theory_composition_projection.i.template`: opt-in manuscript Eqs.
  (182)--(183), storage multipliers, normalization, and solid map corrections.

- `component_mass_atomic.i.template`: storage, advection, dispersion,
  diffusion, and conversion as separate kernels.
- `multicomponent_onsager_diffusion.i.template`: tensor-valued reduced
  molecular-diffusion closure with N-1 independent fluxes, dependent reference
  flux reconstruction, reciprocity/SPD guards, and entropy audit.
- `multicomponent_onsager_dispersion.i.template`: separately selectable
  tensor-valued unresolved-dispersion closure with the same reduced-coordinate
  and audit structure.
- `fluid_solid_heat_exchange.i.template`: conservative current-volume
  fluid-solid heat exchange stitched into both solid-reference energy
  residuals with one J pull-back per subsystem.
- `phase_momentum_atomic.i.template`: all phase momentum terms.
- `surface_energy_overall_momentum.i.template`: thermocapillary,
  capillary-history-gradient, and dynamic-lag terms.
- `electric_enthalpy_maxwell.i.template`: declarative electric enthalpy,
  electric displacement, Maxwell stress, and Gauss law.
- `phase_transformation_nonequilibrium.i.template`: tau/mu generalized
  conversion and insertion. The generic mechanism consumes component-potential
  and phase-Helmholtz properties from a separately selected thermodynamic
  provider.
- `black_oil_phase_transformation_thermodynamics.i.template`: optional SPE
  black-oil mass-fraction projection, phase-pressure storage sum, absolute
  component potentials, and synthetic isothermal gas Helmholtz datum. Use
  `theory_composition_projection.i.template` for a general compositional phase,
  or supply the same properties from a noncompositional or calibrated caloric
  EOS.
- `thermal_subsystem_energy.i.template`: atomic terms for either fluid or
  solid thermal subsystem.
- `high_order_saturation_entropy_viscosity.i.template`: selectable
  P1+P0 or P2+P0 CG/EG saturation transport with a separate Lee--Wheeler
  residual entropy-viscosity flux, facet consistency, and penalty blocks.
- `black_oil_cg_eg_closures.i.template`: reconstructed CG/EG water/gas
  saturation values and rates stitched consistently into generic PVT storage,
  dynamic capillarity, and relative permeability.

The executable full phase-transformation example is
`test/tests/reaction_tau/phase_transformation_nonequilibrium_mms_1d.i`.
