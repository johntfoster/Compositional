# Theory-implementation audit of the current SPE1 model (2026-08-07)

## Verdict

The current finite-deformation solid-reference mixture theory is internally
consistent with the current manuscript, and every active SPE1 object in the
current implementation traces to a current-manuscript equation with matching
signs and conventions.  The AD Jacobian is exactly consistent with the
residual (FD comparison ratios <= 2.1e-12 across all tested entries), so the
Newton-stall signature is a near-degeneracy/conditioning property of the
assembled discrete system, not a residual-vs-Jacobian inconsistency.

Two caveats bound this verdict:

1. The AD-vs-FD Jacobian test proves the Jacobian is the derivative of the
   *implemented* residual.  It cannot detect a formula error that is shared
   identically by the residual and the Jacobian.  The theory cross-audit below
   is the evidence against that class of error, and it found no divergence for
   the audited active objects.
2. The historical passing one-day run (`full_active_..._f92a425`) is NOT
   evidence for the current theory.  Its transient deck (`6b13de3b`) used the
   legacy `matrix_volume_fraction` + `porosity` solid formulation and predates
   the current conserved-solid storage rewrite (`c08c9636`,
   `matrix_reference_component_storage` = 1855 = 0.7 * 2650).  All comparisons
   against that run's initial residual (|R|0 = 441.94) are comparisons against
   a different model and must not be read as a regression signal.

## Active and inactive physics in the current SPE1 deck

Active (per `moose_app/examples/spe1_case1_q2_eg_transient.i`, sha
`c08c9636`):

- Finite-deformation solid-reference mixture momentum (Q2 displacement).
- Conserved solid storage `J phi_s rho_s` with quartz-like solid density 2650.
- CG/EG pressure (P1 + P0 enrichment) with reconstructed total pressure.
- CG/EG water and gas saturations (P2 + P0 enrichment) with entropy viscosity.
- Black-oil PVT: PVTW, PVDG, PVTO with DRSDT = 0 (history-limited R_s,
  Fischer-Burmeister gas-appearance complementarity).
- Solution-gas parent continuous closure (`solution_gas_oil_ratio` P1).
- Peaceman wells with BHP/rate complementarity and free-gas/oil/solution-gas
  surface-rate split.
- Oil <-> gas conversion reaction driven by undersaturation-gap affinity,
  kinetic mobility 1e-8.
- Two-temperature energy subsystem (equal initial temperatures, adiabatic).
- Entropy-viscosity stabilized saturation transport.
- Fischer-Burmeister gas appearance complementarity.

Inactive: fracture mechanics, plastic flow, thermal schedule (equal initial
temperatures), electrokinetic fields (zero charges), reaction network beyond
the single oil<->gas mechanism.

## Object-by-object audit vs the current manuscript

All current-manuscript citations below are `file:line` or label references in
the working tree at 2026-08-07 (manuscript tree `b575aeaa`).

| Object | Manuscript basis | Audit result |
|---|---|---|
| ADReferenceSolidMomentum | `(solid_reference_overall_momentum)` at `sections/pulled_back_solid_skeleton.tex:506` | Quasi-static `Grad test : P'' - test.(b0 + J*volume_force)`; matches |
| ADPhaseMomentumConversionInsertionTerm | same label, conversion source `-J*rate_scale*rate*(F^-T grad tau - v_xi)`, `v_xi = v_S + F*c_xi` | Signs verified with deck stoich `-1 1`; matches |
| ADStandardDarcyReferenceFluxMaterial | `eq:black_oil_darcy_flux` at `sections/correspondence_to_other_theories.tex:490`; mobility `rho_bar k_rf k / mu` | `W_f = mobility*J*F^-1*(grad(p+p_enr+cap) - rho g ...)`; matches |
| ADMixtureGravityMaterial | mixture body force `J * sum_f rho_bulk * g` | Summed bulk densities; matches |
| ADBlackOilPhasePressureDifferenceMaterial | `eq:black_oil_capillary_pressure_closures` at `sections/correspondence_to_other_theories.tex:508` | `p_w - p_o = -p_cow(S_w)`, `p_g - p_o = +p_cgo(S_g)`; table interp; matches |
| ADBlackOilStoredCapillaryGradientMaterial | stored capillary contributions | Reference gradients via slope*grad S chain rule; matches |
| ADBlackOilRateBHPComplementarity | well complementarity | sqrt(a^2+b^2)-a-b; matches |
| BlackOilNodalWellControl / ADBlackOilPeacemanWellMaterial | standard black-oil Peaceman | `q_water = WI mob_w (p - bhp)`, free-gas surface split `q_free = q_gas_res/B_g`, `q_gas_total = q_free + Rs*q_oil`; sources `-rho_surf*q_surf/V_ref`; matches |
| ADReactionNetworkMaterial | `eq:MC_affinity_projection` at `sections/multicomponent_solids.tex:3090` | Affinity `A = -sum mu nu`; mechanistic sources `nu*rate` J-weighted; matches |
| ADBlackOilPhaseTransformationThermodynamicsMaterial | same affinity label; electrochemical mu from Helmholtz + pressure work | `A = mu_dissolved - mu_free`; density-positivity guard is a guard, not a physics term; matches |
| ADGeneralizedTransferWorkMaterial | `eq:MC_generalized_transfer_phase_offset` family | tau-transfer-offset correction; matches |
| ADEntropyViscosityReferenceFluxMaterial | entropy viscosity | raw_value gated by `differentiate_viscosity=false`; matches |
| ADReferenceRelativeVelocityMaterial | `eq:reference_relative_mass_flux` at `sections/pulled_back_solid_skeleton.tex:308` | `c = W/(J*rho_bulk) = F^-1 (v_f - v_S)`; matches |
| ADReferenceComponentSourceTerm | source terms | `-scale*q`; matches |
| ADSolidPhaseMassVolumeMaterial | `eq:solid_reference_solid_component_balance` at `sections/pulled_back_solid_skeleton.tex:437` | `storage = J phi_s rho_s`, `residual = storage_dot - J*source`, `phi_f = 1 - phi_s`; matches |
| ADBlackOilBenchmarkPVTMaterial | black-oil storage identifications at `sections/correspondence_to_other_theories.tex:439`; DRSDT=0 | storage = J phi_f rho_f eta; history-limited R_s; matches |
| ADEnrichedGalerkin family (ScalarBalance, EnrichmentBalance, FluxDG, CrossFluxDG, SymmetryDG, CrossSymmetryDG) | standard SIPG (eps=-1) with adjoint-consistency terms | matches |

Manuscript working-tree edits since the implementation era (`git diff HEAD` on
`sections/virtual_power_derivation.tex` removed helper labels
`reaction_transport_dissipation_variation`,
`onsager_thermodynamic_rate_variation`, `onsager_component_boundary_term`,
`normal_total_component_mass_flux`, `el_conversion_affinity`,
`hamilton_dispersion_force_balance`, `hamilton_diffusion_force_balance`,
`onsager_affinity_constitutive_relation`) are reorganization of intermediate
identities.  None of these removed labels is referenced by implementation
source or by remaining manuscript text (verified by grep); the one moved label
`MC_dynamic_capillary_resistance_admissibility` is still present in
`multicomponent_solids.tex:3645` and referenced from
`validation/validation_matrix.yml:817`.  No physics term in the implementation
depends on a deleted manuscript identity.

## Reproduction commands and artifacts

Not a run report.  The grind reference is
the archived `spe1_bisect/baseline_curlib.log` (reduced 18-element production deck,
current lib): 22 nonlinear iterations, |R|0 = 2675.735 (full mesh |R|0 =
470.63), Newton ratios 0.9945-0.997, linear solves sometimes converge to 1e-5
in one iteration while the nonlinear residual moves by <0.2%, and some linear
solves show increasing linear residual (9e3-1.9e4) - the near-degenerate
Jacobian signature.  Newton drives oil/gas densities nonpositive and the
phase-transform thermodynamics guard aborts.

## Quantitative gates

Not applicable to a code audit (no SPE comparison claimed here).  The prior
one-day report (`validation/reports/spe1_case1.md`) remains the historical
record and is explicitly NOT evidence for the current theory.

## Convergence, robustness, and performance

The grind is reproducible at reduced mesh (|R|0 = 2675.735) and full mesh
(|R|0 = 470.63).  The characteristic 1-Krylov-iteration "exact" linear solve
combined with ~0.2% nonlinear reduction is the signature of a near-degenerate
discrete system: the dominant residual mode is nearly orthogonal to the
Newton search space, or a coupling row is numerically weak.  Candidate
contributors observed in the deck:

- Fischer-Burmeister complementarity rows at the active constraint boundary
  are nondifferentiable in the limit and contribute an almost-flat row;
- the P0 enrichment rows with `anchor_coefficient = 1e-12` deliberately pin a
  redundant P1/P0 decomposition with a weak anchor;
- the conserved solid storage row (`storage_dot - J*source`, source = 0) is a
  pure time-derivative constraint with no spatial coupling, so its Jacobian
  block is diagonal-dominant only through the time derivative;
- kinetic mobility 1e-8 makes the reaction-rate row weakly coupled.

None of these is demonstrated to be a theory or implementation error; they are
conditioning candidates to be tested with scaling/jacobian-norm analysis.

## Official reference comparison

Not applicable.

## Plots and source-data provenance

Not applicable.

## Remaining blockers

1. Resolve whether the near-degenerate grind is removable by scaling or
   solver configuration (i.e., confirm the conditioning hypothesis) or whether
   a specific row/coupling is genuinely misimplemented.  The most direct test
   is a Jacobian null-space / smallest-singular-vector inspection at the
   initial state, then targeted scaling fixes.
2. Produce a NEW provenance-locked one-day SPE1 run from the CURRENT committed
   state (closure `86ab61e8`, tree `7d75523a`) as the baseline for the current
   theory, replacing the historical `2339d82d` gap.
3. Re-run the official-horizon CG/EG comparison and report on the current
   theory; the historical one-day run cannot serve as that evidence.
4. Reconcile `validation/code_only_acceptance_audit.yml` status fields for the
   two partial Table 3 rows only after the current-theory run evidence exists.
