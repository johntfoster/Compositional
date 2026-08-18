# Q2 and EG input architecture audit

Date: 2026-08-03

This audit records the code-facing discretization status after the Q2/EG scope
correction. It applies to simulator implementation and validation files only.

## Verified repository state

- Pre-correction test-deck audit found 60 `.i` files under `moose_app/test/tests`
  and no active `!include` or `#!include` usage.
- The current tree has 126 test decks and 58 reusable include fragments under
  `moose_app/input/includes`.
- Active include usage is present in the `eg_hierarchy` leaves and in migrated
  reaction/tau, phase-history, EOS-Darcy, reference-component,
  charged/nonisothermal, two-phase split, and phase-momentum MMS decks.
- Before this milestone, the target app had no EG/DG kernels or EG weak
  boundary conditions.
- Talha's four-phase app was inspected at
  the legacy `ReactingMixtureMechanics2026-four_phase` comparison checkout, including
  `input/mesh_study/entire_domain.i`, `OverallMassBalance*`,
  `TauEvolution*`, `EGDarcyFluxDG`, `EGTauFluxDG`, `EGSymmetryDG`,
  `EGPressurePenaltyBC`, and `EGTauPenaltyBC`.

## Material-only exceptions

The following tests are material-only reductions or diagnostics. They may use
elementwise monomial auxiliary variables for material output and are not treated
as coupled production discretizations:

- `phase_registry/duplicate_phase_rejected.i`
- `phase_registry/registered_four_phase_eos_1d.i`
- `user_helmholtz_eos/user_helmholtz_eos_1d.i`
- `registered_phase_flash/registered_three_phase_flash_1d.i`
- `registered_phase_flash/registered_three_phase_flash_appearance_2d.i`
- `registered_phase_flash/registered_three_phase_flash_appearance_3d.i`
- `reaction_tau/reaction_network_sources_1d.i`
- `phase_momentum_models/relative_flux_reduction_*.i`, which are solve=false
  relative-flux material diagnostics. They now use Q2 displacement and EG
  pressure/capillary driver fragments but do not certify solved momentum
  convergence.

These decks do not certify coupled Q2 mechanics or EG pressure/tau behavior.

## Completed hierarchy migrations

The following focused groups have been refactored through the reusable include
hierarchy and passed after migration:

- `reaction_tau`: 12/12 passed. The drained, undrained, and moving-front 1D
  reaction cells use EDGE3/Q2 displacement and reconstructed P1+P0 EG
  pressure. The 2D reaction/source MMS uses QUAD9/Q2 prescribed solid
  displacement and reconstructed P1+P0 EG pressure with nonzero Darcy
  reference-component flux in both directions. Its direct summed Eq. (32)
  storage-rate, net-outward-flux, and J-weighted registered-source integrals
  are `0.0125`, `-0.009375`, and `0.003125`; its maximum reported error is
  `6.7346603619128e-16` and absolute global balance is
  `3.8294020732188e-16`. The active-policy 3D reaction/source MMS uses
  TET10/Q2 prescribed solid displacement and reconstructed P1+P0 EG pressure.
  Its direct summed Eq. (32) storage-rate, nonzero net-outward-flux, and
  J-weighted registered-source integrals are `0.0125`, `-0.010875`, and
  `0.001625`; all x/y/z flux components and all six face integrals are checked
  independently. Its maximum required quantitative error is `1.998401e-15`
  and absolute global balance is `1.7546727959505e-15`. The
  moving-front leaf couples the total stress
  `P_double_prime - B p J F_inverse_transpose`, the direct summed Eq. (32)
  storage rate, J-weighted reaction-network production, and a nonzero Darcy
  reference-component flux for the translating profile
  `eta_fluid_component0 = 0.55 + 0.2 x - 0.06 t`. Tau
  evolution/material-derivative decks use P1+P0 EG tau and total-field material
  consumption.
- `phase_history_kinematics`: 9/9 passed. Prescribed solid displacement fields
  use Q2 AuxVariables and the reusable solid-kinematics fragments.
- `ideal_mixture_eos`: 6/6 passed. EOS-Darcy decks use Q2 displacement and
  P1+P0 EG pressure drivers consumed by both EOS and Darcy materials. The pure
  EOS decks remain material-only reductions.
- `user_helmholtz_eos`: 3/3 passed. The coupled 1D and genuinely 2D acceptance
  leaves use EDGE3/Q2 and QUAD9/Q2 prescribed displacement, respectively, and
  reconstructed P1+P0 EG temperature, pressure, and two neutral component
  potentials. `ADHelmholtzEOSClosureMaterial` closes pressure and both absolute
  neutral potentials from the user-entered Helmholtz density. The reconstructed
  pressure drives the EOS-density Darcy flux, and both reconstructed
  neutral-potential gradients drive component extra fluxes. The 2D field
  `u=(0.1x,0.2y)` gives `J=1.32`; every thermodynamic driver and flux has
  independent nonzero x and y components. The two solved variables are written
  directly as `sum_xi J phi_xi fluid_intrinsic_density_xi eta_xi_component`.
  Their 2D storage-rate/net-outward-flux/J-weighted-source triples are
  `(0.0165,-0.24,-0.2235)` and `(0.033,-0.48,-0.447)`. All eight face-component
  integrals are nonzero; the maximum required error is `3.519964e-12`, the
  maximum analytic-integral error is `2.999823e-13`, and the independent global
  balances are `-2.822742040109e-14` and `-4.135580766729e-14`. The original
  `user_helmholtz_eos_1d.i` remains the material-only derivative diagnostic.
- `reference_component_balance`: 7/7 passed. Transport decks use Q2
  displacement; Darcy/storage decks use EG pressure drivers consumed by Darcy
  materials.
- `charged_nonisothermal_transport`: 7/7 passed. Component-balance decks use
  Q2 displacement and reusable solid kinematics. The two-independent-component
  Onsager leaf uses EDGE3/Q2 prescribed displacement, distinct reconstructed
  P1+P0 EG electrochemical/thermal force drivers, a nonzero symmetric cross
  coefficient, and both direct summed Eq. (32) component variables. Its maximum
  required error is `4.520667e-15`; reciprocity and both global balances are
  zero, and the nonnegative dissipation is `3.375`.
- `two_phase_constant_k_split`: 9/9 passed. Split/transport decks use Q2
  displacement, and flux-balance decks use named EG `pressure0`/`pressure1`
  driver pairs.
- `phase_momentum_models`: 16/16 passed. Full momentum decks use Q2
  displacement and EG pressure-potential/capillary drivers; relative-flux
  reductions use Q2/EG driver fragments as solve=false diagnostics.
- `reference_solid_mechanics`: 6/6 passed. The non-affine mechanics decks use
  solved Q2 displacement and reconstructed P1+P0 EG equivalent pressure. The
  3D TET10 case gives `ux_l2 = 1.1250151888783e-14`,
  `uy_l2 = 5.4773804766292e-15`, and `uz_l2 = 3.6281582279385e-15`.
- `registered_phase_flash/registered_phase_component_flux_1d.i`,
  `registered_phase_component_flux_2d.i`, and
  `registered_phase_component_flux_3d.i`: 3/3 passed. The solved component
  storage balances retain their manufactured targets while the prescribed
  solid displacement uses Q2 and all registered oil/gas/water Darcy fluxes
  consume named P1+P0 pressure driver pairs. The 3D deck uses the active TET10
  policy and the reusable reconstructed-total-pressure materials. Its current
  errors are `component_flux_x_l2 = 1.334550083904e-15`,
  `component_flux_y_l2 = 1.1708953065835e-15`,
  `component_flux_z_l2 = 1.2660593653455e-15`,
  `component_l2 = 3.7238012298709e-17`, and
  `storage0_l2 = 6.1833062299243e-17`. The 2D errors are
  `component_flux_x_l2 = 6.9776435129712e-16`,
  `component_flux_y_l2 = 1.1467453797716e-15`,
  `component_l2 = 2.7755575615629e-17`, and
  `storage0_l2 = 5.5511151231258e-17`.
- `registered_phase_flash/classical_compositional_q2_eg_mms_1d.i` closes the
  1D classical compositional-flow acceptance leaf. It uses EDGE3/Q2
  solid-reference kinematics, reconstructed P1+P0 EG oil/gas pressures, two
  active mobile phases, two Helmholtz-EOS components, registered equilibrium
  flash compositions, and registered phase-to-component flux assembly. The two
  solved conserved variables are written directly as
  `sum_xi J phi_xi fluid_intrinsic_density_xi eta_xi_component0` and
  `sum_xi J phi_xi fluid_intrinsic_density_xi eta_xi_component1`. All four
  phase/component boundary fluxes and both component sources are nonzero. The
  maximum required error is `2.359224e-15`, the maximum analytic-integral error
  is `1.998401e-15`, and the independent component balances are
  `2.3592239273285e-15` and `1.9706458687097e-15` at tolerance `1e-10`. The
  2D and 3D companions activate every spatial direction and all four or six
  faces. Their maximum required errors are `2.414735e-15` and
  `2.220446e-15`, their maximum analytic-integral errors are zero and
  `3.802514e-15`, and their independent direct summed Eq. (32) component
  balances are `(-2.4147350785597e-15, -2.1371793224034e-15)` and
  `(-2.220446049250e-15, -1.998401444325e-15)`. The focused
  `registered_phase_flash` group passes 13/13 with zero skips/failures.
- `black_oil_pvt/black_oil_three_component_storage_balance_1d.i`,
  `black_oil_three_component_storage_balance_2d.i`, and
  `black_oil_three_component_storage_balance_3d.i`: the coupled transient
  black-oil storage reductions use EDGE3/Q2, QUAD9/Q2, and active-policy
  TET10/Q2 prescribed solid
  displacement through `ADSolidReferenceKinematics`, a P1 pressure backbone
  plus P0 enrichment, and reconstructed total pressure and its AD time rate in
  `ADBlackOilPVTMaterial`. The oil balance has paired backbone/enrichment rows
  with a fluxless P0 anchor; water and gas balances solve their saturation
  fields. For the 2D case the final total-pressure, enrichment,
  water-saturation, and gas-saturation L2 errors are `2.0764388176818e-13`,
  `3.3454723020424e-16`, `2.6874220530933e-17`, and
  `2.3876248941964e-16`; all three analytic component storage-rate errors and
  the solid-reference Jacobian error are zero. In 3D the corresponding errors
  are `2.5916174936096e-12`, `1.4038894920175e-13`,
  `4.9737237718842e-16`, and `2.4981653138052e-15`; the three direct storage-rate
  errors and the Jacobian error are zero.
- `black_oil_pvt/black_oil_three_component_spatial_flux_balance_1d.i` closes
  the 1D black-oil spatial-flux leaf with EDGE3/Q2 prescribed solid
  displacement, reconstructed P1+P0 EG oil pressure, capillary-reconstructed
  water and gas pressures, production PVT and relative-permeability materials,
  three phase Darcy fluxes, and registered phase-to-component assembly. The
  analytic state is `u_x=0.1x`, `p_o=2+x`, `S_w=0.2+0.1x`, and
  `S_g=0.2+0.05x`. The maximum required field, storage, closure, flux, source,
  and direct summed Eq. (32) global-balance error is `4.965068e-16`; the
  maximum face/integral error is `3.635980e-15`. Water and gas net-outward
  reference component fluxes are `-5.818181818182e-3` and
  `-1.045454545455e-3`, respectively, and equal their J-weighted source
  integrals. All six water/oil/gas boundary flux values are nonzero. The
  genuinely 2D QUAD9 and genuinely 3D active-policy TET10 companions
  extend the affine state through every available coordinate. The 3D leaf uses
  `u=(0.1x,0.2y,0.3z)`, `J=1.716`, and nonzero x/y/z pressure and saturation
  gradients. Its maximum required error is `9.992007e-16`, its maximum
  face/integral error is `3.858025e-15`, and all eighteen water/oil/gas face
  flux integrals are nonzero. Water and gas net-outward reference component
  fluxes are `-1.959160839161e-2` and `-2.524747319347e-3`; the water, oil,
  and gas direct summed Eq. (32) balances are `-6.938893903907e-17`,
  `-9.992007221626e-16`, and `4.163336342344e-17`. The focused
  `black_oil_pvt` group passes 11/11 with zero skips and failures. The
  classical compositional reduction is verified in 1D, 2D, and 3D by the
  registered-flash group.
- `black_oil_well/q2_eg_three_component_well_source_balance_1d.i` closes the
  first integrated reservoir well/source leaf. It uses EDGE3/Q2 prescribed
  displacement with `u_x=0.1x`, reconstructed P1+P0 EG pressure consumed by
  production PVT, relative-permeability, and Peaceman-well materials, and the
  direct `sum_xi J phi_xi fluid_intrinsic_density_xi eta_xi_component`
  variables for water, stock-tank oil, and stock-tank gas. Their storage-rate
  and matching production-well source integrals are
  `-3.333333333338e-3`, `-6.428571428580e-3`, and
  `-9.666666666680e-3`. The maximum required error is `1.713248e-12`, the
  maximum analytic-integral error is `1.383268e-14`, and all three direct
  summed Eq. (32) global balances are below `1.3e-14`. The focused
  `black_oil_well` group passes 12/12 with zero skips and failures.
- `black_oil_well/q2_eg_three_component_well_source_balance_2d.i` supplies the
  genuinely 2D companion on a `2 x 3` QUAD9 reference domain. Its prescribed
  Q2 field is `u=(0.1x,0.2y)`, so both displacement components are active and
  `J=1.32`; production PVT, relative permeability, and the Peaceman completion
  all consume reconstructed P1+P0 EG pressure. The completion reference area
  is the analytic domain area `6`, and integral `J` is `7.92`. The direct
  `sum_xi J phi_xi fluid_intrinsic_density_xi eta_xi_component` storage rates
  equal the matching water, stock-tank oil, and stock-tank gas sources per
  reference area. Their expected and observed integrated source totals are
  `-3.333333333333e-3`, `-6.428571428571e-3`, and
  `-9.666666666667e-3`. Maximum required and analytic-integral errors are
  `1.114623e-13` and `5.290907e-16`; all three direct summed Eq. (32) global
  balances are below `1e-13`. The focused `black_oil_well` group passes 13/13
  with zero skips and failures.
- `black_oil_well/q2_eg_three_component_well_source_balance_3d.i` completes
  the dimensionally applicable production-well/source coverage on a `2 x 3 x
  4` active-policy TET10/Q2 reference domain. Its prescribed field is
  `u=(0.1x,0.2y,0.3z)`, so `J=1.716`; production PVT, relative permeability,
  and the Peaceman completion consume reconstructed P1+P0 EG pressure. The
  completion reference volume is `24`, `dt=37.44`, and integral `J` is
  `41.184`. The direct `sum_xi J phi_xi fluid_intrinsic_density_xi
  eta_xi_component` water, stock-tank oil, and stock-tank gas storage rates
  equal their matching production-well sources per reference volume. Their
  expected and observed integrated totals are `-3.333333333333e-3`,
  `-6.428571428571e-3`, and `-9.666666666667e-3`. Maximum required and
  analytic-integral errors are `1.926805e-15` and `3.339343e-17`; all three
  direct summed Eq. (32) global balances are below `1.6e-17`. The focused
  `black_oil_well` group passes 14/14 with zero skips and failures.

MONOMIAL CONSTANT AuxVariables remain only as elementwise material-property,
flux-component, split/flash, and residual diagnostics in these migrated decks.
They are not used as substitutes for Q2 displacement primaries or P1+P0 EG
pressure/tau fields.

## Coupled poromechanics acceptance

The mutually coupled finite-deformation poromechanics MMS is now quantitative
in 1D, 2D, and 3D. The 3D leaf uses TET10/Q2 displacement with all three
non-affine components active, reconstructed P1+P0 EG pressure, the total stress
`P_double_prime - B p_E J F_inverse_transpose`, and the direct summed Eq. (32)
storage rate `d[J phi_f fluid_intrinsic_density eta_f_alpha]/dt` with Darcy
reference flux and a J-weighted source. All eleven 3D norms are below `1e-10`;
the maximum is `ux_h1_semi = 2.115951e-11`, and the strong summed component
balance residual is `7.171978e-12`.

## MMS inventory acceptance status

The registered component-flux hierarchy, coupled reaction-mechanics front,
black-oil direct-storage, spatial-flux, and production-well/source leaves, and
classical compositional reductions are quantitatively verified in every
dimension in which they apply. The focused closure run passed `black_oil_pvt`
11/11, `black_oil_well` 14/14, `registered_phase_flash` 13/13, and
`eg_hierarchy` 7/7, for 45 passed with zero skips and failures. Every case in
`validation/mms_inventory.yml` now has `acceptance_gap: false`; SPE benchmark
acceptance remains separately tracked and does not change this MMS result.

The registered flash appearance decks are classified as material-only
diagnostics above. Their prescribed zero displacement supplies identity
solid-reference kinematics, and their elementwise flash and residual outputs do
not substitute for solved Q2 mechanics or EG pressure/tau fields.

## Implemented architecture objects

- `ADEGReconstructedScalarMaterial` declares total value, gradient, and time
  derivative for a backbone plus enrichment scalar field.
- `ADEnrichedGalerkinScalarBalance` and
  `ADEnrichedGalerkinScalarEnrichmentBalance` provide paired volume rows.
- `ADEnrichedGalerkinFluxDG` provides the enrichment interior-facet flux and
  penalty row.
- `ADEnrichedGalerkinSymmetryDG` provides the companion continuous-row symmetry
  term.
- `ADEnrichedGalerkinPenaltyBC` provides weak EG Dirichlet boundary terms.
- `ADEnrichedGalerkinMaterialPropertyResidual` applies material residuals to
  EG backbone/enrichment rows and supports a P0 anchor for fluxless tau.
- `ADScalarDiffusionReferenceFluxMaterial` provides a pressure-only reference
  diffusion flux and matching mobility tensor for isolated EG convergence
  checks.
- `ADMaterialScalarL2Error` and `ADMaterialVectorL2Error` measure reconstructed
  AD material properties directly, avoiding auxiliary-field projection in the
  convergence evidence.
- `ADStandardDarcyReferenceFluxMaterial`, `ADRegisteredPhaseMomentum`,
  `ADReferenceSolidStressMaterial`, `ADPhaseTauMaterialDerivative`,
  `ADTauEvolutionMaterial`, and `ADIdealMixtureFluidEOSMaterial` consume total
  enriched pressure, pressure-potential, capillary-pressure, or tau fields when
  enrichment variables are supplied.
- `ADEGReconstructedScalarMaterial` reports a zero total time derivative under
  steady solve=false diagnostics and uses AD time derivatives under transient
  solves.

## Three-dimensional mesh policy

Routine 3D Q2/EG decks use TET10 elements. A coupled 3D HEX27 displacement
space combined with pressure/tau P1+P0 EG fields exceeds the AD derivative
container available in the current optimized build. The fragment catalog
therefore records a build-specific reject policy for HEX27 coupled Q2/EG
production and acceptance decks. `validation/scripts/validate_validation_yaml.py`
checks that the catalog keeps TET10 as the active 3D policy and retains the
HEX27 reject rule.

## Tau enrichment assumption

For flux-carrying tau equations, the EG facet and boundary terms should be
applied with a tau mobility and tau flux. For the current fluxless tau evolution
used by the hierarchy MMS leaves, the governing equation determines the total
rate of `tau + tau_enr` but does not determine a separate elementwise enrichment
gauge. The implemented fluxless-tau include therefore applies the same material
residual to the backbone and enrichment rows and anchors `tau_enr` with an
elementwise P0 penalty. Materials consume the total field, while the anchor
removes the null mode.

## Verified hierarchy decks

- `eg_hierarchy/eg_q2_mms_1d.i`: EDGE3/Q2 mechanics, EG pressure/tau, pressure
  DG/facet and weak boundary terms; final errors are `p_total_l2 =
  1.2382401034996e-02`, `tau_total_l2 = 3.7729437576947e-15`, and `ux_l2 =
  5.2592652774114e-05`.
- `eg_hierarchy/eg_q2_mms_2d.i`: QUAD9/Q2 mechanics, EG pressure/tau, pressure
  DG/facet and weak boundary terms; final errors are `p_total_l2 =
  3.6676550906407e-02`, `tau_total_l2 = 1.4297040419762e-15`, `ux_l2 =
  3.7324952062882e-05`, and `uy_l2 = 3.6254360952343e-05`.
- `eg_hierarchy/eg_q2_mms_3d.i`: TET10/Q2 mechanics, EG pressure/tau, pressure
  DG/facet and weak boundary terms; final errors are `p_total_l2 =
  1.2021528987292e-01`, `tau_total_l2 = 7.9258971951316e-15`, `ux_l2 =
  1.1068592366529e-04`, `uy_l2 = 1.1066956646512e-04`, and `uz_l2 =
  1.1065619196730e-04`.

The focused hierarchy group passed 7/7, including the convergence script and
the quantitative 1D/2D/3D coupled-poromechanics validators.
The strict convergence script separates the evidence by mechanism:

- Pressure EG convergence uses direct reconstructed-material errors. L2 rates
  are `[1.9233455814857192, 1.9649962534878953, 1.9833855781246936]` in 1D,
  `[1.8520250950627626, 1.9301083605168239]` in 2D, and
  `[1.8641929122312608, 1.9272301065861637]` in 3D. Gradient rates are
  `[0.9977944493601018, 0.999463813536827, 0.9998677973498985]` in 1D,
  `[0.9915803899509545, 0.9978432775843264]` in 2D, and
  `[0.965936099528585, 0.9845171260752934]` in 3D.
- Fluxless tau EG convergence gives L2 rates
  `[1.9961357465879233, 1.9990342598619135, 1.999758585164086]` in 1D,
  `[1.9506451692192703, 1.987644754721795]` in 2D, and
  `[1.870297360330464, 1.9358530046263804]` in 3D. Tau gradient rates are
  `[0.9976812418797645, 0.9994205430024514, 0.999855150290632]` in 1D,
  `[1.0155319081458358, 1.0044374331793013]` in 2D, and
  `[0.9216789981214552, 0.9612560949206648]` in 3D.
- The tau null-mode perturbation check gives anchored enrichment norms
  `(2.034931e-17, 3.319883e-17)` for unshifted and shifted initial null-mode
  states, while the unanchored free-tau solve can retain a null representative
  with enrichment norms `(2.500000e-01, 9.176424e-15)` without changing the
  total tau error.
- Pressure-decoupled Q2 mechanics gives 1D displacement L2 rates
  `[2.9897782852374375, 2.9974360883234556, 2.9993584879939355]` and H1
  seminorm rates `[1.9917199996983725, 1.9979333137209208,
  1.9994835404224234]`. In 2D, displacement L2 rates are at least
  `2.9516730425772` and H1 seminorm rates are at least
  `1.9671689455104528`. In 3D, displacement L2 rates are at least
  `2.959771900825688` and H1 seminorm rates are at least
  `1.9878154510731674` on the TET10 `n = 2, 3, 4` sequence.
