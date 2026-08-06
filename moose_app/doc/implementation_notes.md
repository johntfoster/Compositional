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
| Kinematics | `materials`, `kernels` | Solid-skeleton deformation, pull-backs, registered mobile-phase history \(F_a,J_a\) | implemented slice |
| Thermodynamics | `materials`, `userobjects` | Free energies, chemical potentials, pressure relations | implemented reduced EOS slice |
| Phase behavior | `materials`, `userobjects` | Phase split, saturation/composition constraints | implemented restricted two-phase slice |
| Transport | `kernels`, `materials` | Component/phase mass weak forms and flux closures | implemented reference-balance and charged/nonisothermal slices |
| Mechanics | `kernels`, `materials`, `bcs` | Reference-solid-skeleton momentum balance | implemented quasi-static finite-deformation slice |
| Reactions | `materials`, `kernels` | Reaction rates, source terms, affinities, and tau evolution | implemented material slice |
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

## Atomic-kernel performance policy

Atomic input-deck-selectable kernels do not create separate nonlinear systems:
MOOSE assembles their contributions into one residual and Jacobian. Constitutive
work remains shared in AD materials, so the kernel split adds object dispatch
and element-loop overhead but does not duplicate EOS/flash evaluation per term.
For the production SPE1 deck, cost is instead dominated by the higher-order
saturation and phase-transformation-rate DOFs, interior-facet material
evaluation, 128-wide local AD derivatives, active phase/well-control Newton
transitions, and monolithic factorization.

`ADEntropyViscosityReferenceFluxMaterial` therefore exposes
`differentiate_viscosity`. The default `true` retains a fully differentiated
nonlinear sensor. The production deck selects `false`, which freezes the
min/speed/entropy-residual coefficient within each residual linearization while
retaining AD derivatives of the mass coefficient and reconstructed-saturation
gradient in the conservative stabilization flux. Both modes retain identical
coefficient and flux values and are regression tested.

## Current Phase-History Kinematic Policy

`PhaseRegistry` reads an arbitrary set of unique phase names from the input
deck and identifies the registered reference phase. There is no compiled phase
enum or fixed upper bound on the number of phases. The solid skeleton remains
the reference configuration for weak forms,
Grad/Div operators, boundary measures, and Piola transformations. The material
`ADPhaseHistoryKinematicsMaterial` computes `l_a = Grad_X(v_a) F_s^{-1}` and
`c_a = W_a / (J_s rho_a)` for the selected mobile phase, where
`rho_a = phi_a rhobar_a` is the current bulk phase density (not the intrinsic
density alone), while
`ADPhaseDeformationGradientHistory` and `ADPhaseJacobianHistory` provide the
solid-frame advective residuals for \(F_a\) and \(J_a\).

The registry also assigns each phase a `momentum_models` entry: `reference`,
`full`, or `relative_flux`. `ADRegisteredPhaseMomentum` solves the complete
phase velocity residual, including the phase material acceleration, pulled-back
equivalent-pressure and optional capillary force, gravity, fluid-skeleton drag, optional additional
interaction force, conversion insertion, and optional extra Cauchy/Maxwell
stress. `ADStandardDarcyReferenceFluxMaterial` is the neutral algebraic
`relative_flux` reduction. Its `include_acceleration` switch defaults to
`false`; when enabled it requires spatial `phase_acceleration` components and
uses the body driver \(\bar\rho_a(\mbf g-\mbf a_a)\). Turning inertia off
removes acceleration from both the flux value and its AD graph. Both momentum
paths also provide `include_capillary_pressure=false` by default. Enabling it
requires a phase-specific `capillary_pressure` field \(\gamma_a\) and replaces
\(\Grad\bar p_E\) by \(\Grad(\bar p_E+\gamma_a)\); disabling it removes
\(\gamma_a\) from the residual and its AD graph. The supplied field is the
theory's phase capillary contribution, so any conventional pairwise
\(p_c=p_{\mathrm n}-p_{\mathrm w}\) law must first be mapped to the appropriate
phase \(\gamma_a\) with its sign convention. Prescribed
full-momentum tractions use
`ADRegisteredPhaseMomentumTractionBC` and are specified per reference area.
The reduced Darcy material accepts either its constant `viscosity` parameter
or a positive AD property through `viscosity_name`. The black-oil PVT material
can therefore expose pressure-tabulated water, oil, and gas viscosities to the
three phase-mobility objects without removing pressure derivatives from their
AD graphs.

The regression decks explicitly initialize a history-free phase with
\(F_a=I\), \(J_a=1\). When the
phase activity indicator is below `active_tol`, the implementation sets
both `c_a = 0` and `l_a = 0` and preserves the stored phase history, avoiding division by
vanishing phase density. A later full flash/reactivation closure must supply
consistent phase histories when a phase reappears after an inactive interval.

## Reference-Solid Mechanics Slice

`ADReferenceSolidMomentum` assembles the quasi-static skeleton residual on the
solid reference configuration,
\(\int_{\Omega_0^s}\nabla_X\delta u_i \cdot P_{iJ}\,dV
-\int_{\Omega_0^s}\delta u_i b_{0i}\,dV\). The total first Piola stress is a
material property, so constitutive stress measures remain outside the residual
kernel. `ADReferenceSolidTractionBC` prescribes the natural traction component
per unit reference area with the sign convention in the implementation-paper
weak form.

The first executable stress path uses `ADCompressibleNeoHookeanReferenceStressMaterial`
for a finite-deformation effective stress \(P''\), then
`ADReferenceSolidStressMaterial` forms
\(P''-B\bar p_E J F^{-T}\). An optional current Maxwell stress material
property can be pulled back as \(J\sigma^+F^{-T}\). Current-volume body,
thermocapillary, conversion, or other source forces may be supplied to the
kernel and are multiplied by \(J\); a reference-volume force function is also
available for manufactured solutions. Inertia and fully coupled
reaction-mechanics source reconstruction remain follow-up closures.

## EOS Derivative Audit

The general EOS path is user-defined. Each phase supplies a Helmholtz density
with `ADDerivativeParsedMaterial`, using constituent partial densities and
temperature as explicit independent variables and `derivative_order = 2`.
`ADHelmholtzEOSClosureMaterial` consumes the generated derivatives and computes
`mu_a^alpha = dA_a/drho_a^alpha`,
`p_a = sum_alpha rho_a^alpha mu_a^alpha - A_a`, and
`s_a = -dA_a/dT`, together with intrinsic density, bulk phase density, and
specific Helmholtz energy. Consequently pressure and chemical potentials are
not separate fitted inputs. Every EOS object selects a phase registered by the
input deck.

The older `ADIdealMixtureFluidEOSMaterial` remains as a restricted regression
and compatibility object; it is not the general constitutive architecture.

The ideal-mixture neutral component potential audit is recorded in
`moose_app/doc/ideal_mixture_neutral_potential_audit.md`. The implemented
positive-composition derivative is
\(\psi_{\mathrm{vol}} + p/\bar\rho + \mu_{\mathrm{ref}}^\alpha
+ R\theta\log\eta^\alpha\); the apparent \(+R\theta\) term cancels in the
fixed-other-constituent-density derivative of the normalized ideal-mixture
free energy.

## Charged and Nonisothermal Flux Slice

`ADChargedNonisothermalComponentFluxMaterial` computes a current component
flux from gradients of neutral component potential, electric potential, and
temperature. The electric contribution depends on \(\nabla\varphi\), so a
constant shift in electric potential leaves the transport force unchanged. The
material reports the transport force, current component flux, charge flux, and
direct electric-field work on that charge flux. `ADRegisteredPhaseComponentFluxMaterial`
and `ADReferenceFluidComponentFluxMaterial` can now add an AD material-provided
current extra flux before applying the solid-reference pull-back.

The regression decks in `test/tests/charged_nonisothermal_transport` use
linear potential and temperature fields in one, two, and three dimensions.
They solve the reference component balance with zero phase advection and check
the current flux, pulled-back reference flux, charge flux, and electric-field
work against closed-form values.

## Reaction and Tau Material Slice

`ADPhaseTauMaterialDerivative` computes the phase-following derivative of the
transfer potential on the solid reference mesh. Mobile phases use
\(c_\xi = W_\xi/(J\rho_\xi)\), where \(\rho_\xi\) is the current bulk phase
density, and report both \(D_\xi\tau/Dt\) and
\(D_\xi\tau/Dt-|v_\xi|^2/2\). Inactive phases below `active_tol` report zero
for the derivative, convective term, velocity square, and transfer offset.
The phase velocity may be supplied directly or reconstructed as
\(v_\xi=\dot u_s+F W_\xi/(J\rho_\xi)\), retaining AD coupling to solid
kinematics and the reference relative mass flux.

`ADGeneralizedTransferWorkMaterial` composes each selectable phase/component
transfer work as
\(L_\xi^\alpha=\hat\mu_\xi^\alpha-\psi_\xi+D_\xi\tau/Dt-|v_\xi|^2/2\).
Energy kernels consume these full transfer-work properties rather than the tau
offset alone.

`ADTauEvolutionMaterial` forms the pointwise AD residual for the solid-frame
tau equation and can be consumed by `ADMaterialPropertyResidual`, giving Newton
a consistent derivative through `tau_dot`. `ADReactionNetworkMaterial` uses a
mechanism-major stoichiometric table over registered phases and components to
assemble phase component sources, total current and reference sources,
traditional affinities, phasewise mass sums, transfer-work corrections,
generalized conversion coefficients, optional kinetic residuals, and reaction
powers. The regression pair in `test/tests/reaction_tau` validates a
phasewise mass-conserving mechanism, a phase-changing mechanism with nonzero
transfer-work correction, and a one-dimensional tau material-derivative MMS.
