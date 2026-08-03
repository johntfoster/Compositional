# Comprehensive Technical Review of the Theory Manuscript

Date: 2026-07-26  
Repository baseline: `master` at `4dba770`  
Immediate owner: theory manuscript  
Status: closed; every Priority 0, Priority 1, Priority 2, and citation finding
has been repaired and independently validated

## Purpose and scope

This document records the comprehensive technical review of the active theory
manuscript so that every finding can be tracked through revision.

The review covered the complete `main.tex` compilation graph:

- `main.tex`
- `defs.tex`
- `sections/introduction.tex`
- `sections/technical_setting.tex`
- `sections/material_mass.tex`
- `sections/conservation_of_charge.tex`
- `sections/virtual_power_derivation.tex`
- `sections/multicomponent_solids.tex`
- `sections/pulled_back_solid_skeleton.tex`
- `sections/correspondence_to_other_theories.tex`
- `sections/conclusions.tex`
- `all.bib`

The inactive file `sections/variational_derivation.tex` was excluded because it
is not included by `main.tex`. The first review preceded the introduction and
conclusions; both sections were added after its technical findings were closed
and are included in the post-expansion review cycle.

The review covered:

- balance laws and observer choices;
- the Hamilton--d'Alembert and Onsager constructions;
- electrical, chemical, thermal, and mechanical coupling;
- Coleman--Noll restrictions and dissipative closures;
- nonlinear and component-level Biot transformations;
- reservoir and classical-model reductions;
- closure and unknown counts;
- prose, notation, displayed mathematics, and layout;
- bibliography integrity and selected claim-level citation support.

## Overall assessment

The repaired manuscript has a strong and unusually coherent architecture. Its
mass and charge bookkeeping, phase-attached variational structure, solid
kinematics, entropy exploitation, Biot reduction, and reservoir
specializations now use consistent notation and explicit scope assumptions.
All structural findings in this review are closed. The manuscript may proceed
to introduction/conclusion drafting and the independent post-expansion review
cycle required before submission.

## Validation performed

- [x] Reviewed the active source graph rooted at `main.tex`.
- [x] Inspected `defs.tex` before interpreting project-local notation.
- [x] Audited every active section for balance-law, state-dependency,
      chain-rule, force--flux, and closure consistency.
- [x] Scanned labels, references, citations, and display environments.
- [x] Rebuilt with `pdflatex -> bibtex -> pdflatex -> pdflatex`.
- [x] Confirmed a clean 78-page PDF after every Priority 0, Priority 1,
      Priority 2, and citation repair.
- [x] Confirmed a clean 81-page post-expansion PDF after adding the introduction,
      conclusions, and the literature comparison following
      `eq:MC_bulk_transport_interaction_admissibility`.
- [x] Removed the forced page break before
      `eq:MC_electrostatic_power_identity`; the identity and the following
      subsystem energy balance now paginate without the former large blank area.
- [x] Found no undefined references or citations.
- [x] Found no reported LaTeX warnings, errors, overfull boxes, or underfull
      boxes in the final build log.
- [x] Visually inspected all rendered pages and inspected dense displays at
      larger scale.

## Final end-to-end balance audit

An independent final audit accepted all five global balances under the
conservation and constitutive-admissibility assumptions stated in the
manuscript:

- [x] **Mass.** Summing
      `eq:averaged_global_component_balance` over components recovers
      `eq:spatial_mass_4` because every mechanism is mass conservative and the
      component-relative fluxes are phasewise zero-sum:
      `sections/material_mass.tex:259-288` and
      `sections/material_mass.tex:560-639`. The skeleton transformation retains
      the conservative relative phase flux:
      `sections/multicomponent_solids.tex:106-183`.
- [x] **Free charge and current.** Constant component charge per mass,
      mechanismwise charge conservation, and the compatible prescribed
      external-charge triplet close `eq:mixture_charge_balance`; differentiating
      Gauss' law gives the Eulerian, reference, and skeleton compatibility
      equations:
      `sections/conservation_of_charge.tex:49-249` and
      `sections/virtual_power_derivation.tex:1349-1446`.
- [x] **Momentum.** Antisymmetric pairwise forces cancel from the sum. Phase
      mass balance converts the acceleration form to conservative momentum, and
      the remaining transfer-potential term vanishes by the zero-sum insertion
      constraint. The pressure, Maxwell, and capillary rollups give
      `eq:MC_overall_momentum_nonlinear_biot`:
      `sections/virtual_power_derivation.tex:46-55`,
      `sections/virtual_power_derivation.tex:1249-1265`, and
      `sections/multicomponent_solids.tex:3767-3926`.
- [x] **Material-plus-field total energy.** The two thermal-subsystem balances,
      phase kinetic-energy balances, and the single global field-power identity
      close after generalized transfer power, volume-constraint power,
      pairwise mechanical work, ordinary heat exchange, and
      reaction-associated allocations cancel under their stated identities:
      `sections/multicomponent_solids.tex:808-1001`,
      `sections/multicomponent_solids.tex:2692-2722`, and
      `sections/multicomponent_solids.tex:2955-3215`. Mechanical, thermal, and
      electrical boundary-power signs are explicit.
- [x] **Entropy.** Skeleton-relative internal-energy and entropy transport,
      global electrical power, charge projection, reaction and relative-flux
      rate spaces, plasticity, bulk phase interaction, drag, heat exchange, and
      Fourier conduction are all retained in
      `eq:MC_entropy_inequality` through `eq:MC_residual_dissipation`.
      Nonnegativity follows only under the stated positive-mobility closures and
      the joint bulk-transport/interaction condition:
      `sections/multicomponent_solids.tex:1211-1842` and
      `sections/multicomponent_solids.tex:2268-3292`.

## Priority 0: governing-theory issues

These items should be treated as potential submission blockers.

### P0.1 Complete and reconcile the electrical action, power, and entropy rates

Status: [x]

Evidence after repair:

- The stored energy intentionally contains material Helmholtz energy,
  interfacial energy, and phase electric enthalpy, but no
  \(\varrho\varphi\) potential energy:
  `sections/virtual_power_derivation.tex:65-71`.
- Bulk and boundary free charge now appear explicitly in the source virtual
  work: `sections/virtual_power_derivation.tex:72-81`.
- The selected source-work ensemble and its division of electrical force and
  rate coupling are stated at
  `sections/virtual_power_derivation.tex:98-118`.
- The combined field-energy and source-work variation now gives both
  \((\nabla_{\mathbf x}\cdot\mathbf d-\varrho)\delta\varphi\) and the natural
  electrical boundary condition:
  `sections/virtual_power_derivation.tex:524-575`.
- Component-carried and independently prescribed bulk charge are distinguished
  at `sections/conservation_of_charge.tex:12-51`.
- The shared field-coordinate rate is now displayed and balanced against bulk
  free-charge source power and electrical boundary power in
  `eq:MC_electrostatic_power_identity`:
  `sections/multicomponent_solids.tex:650-692`.
- The two thermal-subsystem balances now retain only phase material-state and
  Maxwell power contributions; the common field-coordinate power is removed
  globally before the fluid and solid balances are divided by different
  temperatures: `sections/multicomponent_solids.tex:694-806`.
- The nonporous single-phase energy limit now retains
  \(-\varrho\dot\varphi+\nabla\cdot(\dot\varphi\mathbf d)\):
  `sections/multicomponent_solids.tex:808-851`.
- The charge accumulation, conversion, and relative-transport rate is shown
  explicitly in `eq:MC_charge_rate_entropy_projection`, which shifts the
  neutral potential to the electrochemical potential without adding the
  electrical contribution twice:
  `sections/multicomponent_solids.tex:2031-2060`.

Original technical concern and reopened propagation gap:

The prior draft wrote one functional but subsequently asserted the variation
of an unstated free-charge term. It also did not maintain the distinction
between independently prescribed charge and charge carried by the material
fields. If a conservative mobile-charge potential energy had instead been
selected,

\[
\varrho
=
\sum_{\xi,\alpha}
z_\xi^\alpha\phi_\xi\bar\rho_\xi\eta_\xi^\alpha,
\]

then the charge/potential coupling would contribute not only to
\(\delta\varphi\), but also to the \(\delta\phi_\xi\),
\(\delta\bar\rho_\xi\), \(\delta\eta_\xi^\alpha\), material-insertion, and
phase-map variations. The implemented source-work ensemble avoids those
duplicate material terms by assigning mechanical electrical force to the
Maxwell stress and charge-dependent rate work to the electrochemical Onsager
constraint.

The first repair completed the variational source-work ensemble but did not
propagate the bulk source power \(-\varrho\dot\varphi\) through the first law.
It also asserted that Gauss' law removed the field rate in the entropy
reduction without displaying a valid operation for
\(\theta_{\mathcal F}\ne\theta_{\mathcal S}\). The missing decomposition is

\[
\sum_\xi\phi_\xi\mathbf d_\xi\cdot\nabla\dot\varphi
=
\nabla\cdot(\dot\varphi\mathbf d)
-
\varrho\dot\varphi .
\]

Because \(\varphi\) is one shared field, this identity must be applied globally,
not independently inside the two temperature-weighted subsystem balances.
Separately, the component charge rate must be projected onto the component
balance to generate \(z_\xi^\alpha\varphi\) in the electrochemical potential.

Recommended resolution:

- [x] Choose and state the electrical ensemble: prescribed potential,
      prescribed free charge, or mobile material charge.
- [x] Write the complete action, including the appropriate charge coupling and
      electrical boundary work with a sign consistent with the selected
      electric-enthalpy convention.
- [x] Distinguish prescribed external charge from component-carried charge.
- [x] Recompute the coefficients of every material and electrical variation.
- [x] Propagate the bulk source power and electrical boundary flux through the
      first law.
- [x] Separate the common field-coordinate power globally before applying the
      two subsystem temperatures.
- [x] Display the charge-rate projection that converts neutral chemical
      potentials to electrochemical potentials.
- [x] Recheck the definitions of the electrochemical potential, Maxwell stress,
      phase pressure, and equivalent pore pressure after the action is repaired.
- [x] Rebuild and visually validate the extended energy and entropy displays.
- [x] Recheck the abstract and summary tables after the rederivation.

Resolution implemented:

- The manuscript now states a free-charge source-work ensemble in the
  Hamilton--d'Alembert principle. The phase electric enthalpy remains in the
  stored energy and generates the Maxwell stress, while bulk and boundary free
  charge enter as generalized work conjugate to the electric-potential
  variation.
- Component-carried charge is evaluated from the current component material
  measures, whereas independently prescribed bulk charge is a known additive
  field source and is excluded from the component charge balances.
- Because charge is source work rather than a separately varied
  \(\varrho\varphi\) potential energy, it contributes to
  \(\delta\varphi\) but does not create duplicate phase-map,
  material-insertion, density, volume-fraction, or composition terms. Maxwell
  stress carries the mechanical electric force, and the charge-weighted
  Onsager constraint carries the electrochemical insertion and transport work.
- The natural electrical boundary condition is now explicit:
  \(\mathbf d\cdot\mathbf n=\bar q\) on the prescribed-free-charge boundary;
  \(\delta\varphi=0\) on the prescribed-potential boundary.
- The electrochemical potential, Maxwell stress, phase-pressure and equivalent
  pore-pressure relations, abstract, and model counts were rechecked. Their
  existing forms are consistent with this ensemble. The summary-table energy
  row now cites the global field-power identity; the count remains unchanged
  because that identity follows from Gauss' law and is not an independent field
  equation.
- The shared field-coordinate rate is now carried by one global, entropy-free
  electrostatic power identity. The two material thermal balances therefore do
  not require an arbitrary fluid/solid allocation of
  \(-\varrho\dot\varphi\) when the temperatures differ.
- The charge-weighted component-rate identity is now displayed at the
  Coleman--Noll source-force step. It supplies the
  \(z_\xi^\alpha\varphi\) part of the electrochemical potential, whereas the
  global field identity supplies the \(\dot\varphi\) power. These are distinct
  rate channels and neither remains as an independent residual-dissipation
  term.

### P0.2 Restore relative energy and entropy transport in the skeleton frame

Status: [x]

Completed repair:

- [x] Derived the phase mass balance in the skeleton observer and the exact
      Eulerian--skeleton--phase transport identity:
      `sections/multicomponent_solids.tex:106-177`.
- [x] Rewrote the two thermal-subsystem energy balances in conservative
      skeleton form with explicit
      \(\rho_\xi e_\xi(\mathbf v_\xi-\mathbf v_{\mathcal S})\) transport:
      `sections/multicomponent_solids.tex:795-888`.
- [x] Retained the corresponding
      \(\rho_\xi\mathfrak s_\xi(\mathbf v_\xi-\mathbf v_{\mathcal S})\)
      entropy convection:
      `sections/multicomponent_solids.tex:1141-1170`.
- [x] Fixed the material-source convention: bulk mass transports internal
      energy, while generalized conversion work remains
      \(-L_\xi^\alpha\dot c_\xi^\alpha\):
      `sections/multicomponent_solids.tex:709-723`.
- [x] Propagated the resulting bulk free-energy convection through the reduced,
      collected, and residual entropy inequalities:
      `sections/multicomponent_solids.tex:1195-1308`,
      `sections/multicomponent_solids.tex:1733-1760`, and
      `sections/multicomponent_solids.tex:2567-2596`.
- [x] Identified the distinct bulk phase force--flux pair and imposed its joint
      admissibility condition with interphase mechanical-energy exchange:
      `sections/multicomponent_solids.tex:2599-2610` and
      `sections/multicomponent_solids.tex:2828-2892`.
- [x] Qualified the pairwise drag-heating construction so that it is not
      claimed to dispose of the bulk transport term:
      `sections/multicomponent_solids.tex:2920-3001`.
- [x] Propagated that qualification into the solid-reference Darcy reduction:
      positive-definite drag controls its own dissipative part, while the
      complete model remains subject to the joint bulk transport--interaction
      condition:
      `sections/pulled_back_solid_skeleton.tex:33-54` and
      `sections/pulled_back_solid_skeleton.tex:148-180`.
- [x] Confirmed that the single-phase limit is unchanged because
      \(\mathbf v_\xi=\mathbf v_{\mathcal S}\), and that the summed balance
      retains the relative material-energy flux until the phase kinetic-energy
      balances and interaction-energy identity are added:
      `sections/multicomponent_solids.tex:891-916` and
      `sections/multicomponent_solids.tex:934-977`.
- [x] Verified citation support: Hassanizadeh and Gray equation (35) supports
      the solid-observed saturation rate; Seguin and Walkington equations
      (10)--(12) support skeleton-following storage together with relative
      energy and entropy fluxes; Drumheller equation (50) supports the
      constituent internal-energy/source-work convention.
- [x] Rebuilt the manuscript with the workspace
      `pdflatex -> bibtex -> pdflatex x2` recipe. The new transport identities,
      energy balance, entropy inequality, residual inequality, and coupled
      admissibility condition render as equations (125), (126), (152), (157),
      (182), and (192), respectively, with no LaTeX warnings or overfull boxes.

Full-text evidence checked:

- Hassanizadeh and Gray (1993), DOI `10.1029/93WR01495`, equation (35).
- `references/pdfs/seguin-walkington-2019-multicomponent-multiphase-flow-poroelastic.pdf`,
  equations (2) and (10)--(12).
- `references/pdfs/drumheller-mix.pdf`, equation (50).

### P0.3 Correct the compositional-limit chemical potentials

Status: [x]

Evidence after repair:

- The classical closure now defines the absolute chemical potential from the
  specific Gibbs energy by

\[
\mu_f^\alpha
=
g_f
+
\frac{\partial g_f}{\partial\eta_f^\alpha}
-
\sum_\beta
\eta_f^\beta
\frac{\partial g_f}{\partial\eta_f^\beta}.
\]

  The source also states its equivalent component-mass derivative
  interpretation and its invariance to the chosen differentiable off-simplex
  extension: `sections/correspondence_to_other_theories.tex:52-110`.
- Transport now uses component \(N\) as reference, \(N-1\) independent mass
  fractions, chemical-potential differences, and a zero-total-relative-flux
  reconstruction: `sections/correspondence_to_other_theories.tex:70-110`.
- The chemical-potential tangent and effective diffusion--dispersion tensor are
  both restricted to the same \(N-1\) composition tangent space:
  `sections/correspondence_to_other_theories.tex:112-161`.
- The Fickian balance is written only for the \(N-1\) independent components,
  and the source explains how the reference-component balance follows:
  `sections/correspondence_to_other_theories.tex:163-201`.
- Absolute chemical-potential equality remains the phase-equilibrium
  condition, while the Fickian specialization uses only intrinsic potential
  differences.
- The current clean 69-page build resolves the repaired displays as equations
  (277)--(280) on page 60. They and the adjacent pages were visually
  rechecked after the common \(N-1\) rate-space repair.

Completed resolution:

- [x] Define absolute chemical potentials through the component-mass
      derivative interpretation.
- [x] Use \(N-1\) independent mass fractions and
      \(\mu_f^\alpha-\mu_f^N\) for transport.
- [x] Rewrite the composition-gradient tangent in the same coordinate system.
- [x] Restrict diffusion/dispersion mobility and the thermodynamic tangent to
      the composition tangent space.
- [x] Recheck the phase-equilibrium and Fickian specializations.

### P0.4 Establish the assumptions behind the additive component Biot rule

Status: [x]

Evidence after repair:

- The phase Legendre transform and nonlinear coefficient remain the general,
  authoritative construction:
  `sections/multicomponent_solids.tex:3290-3450`.
- The component construction is now explicitly an optional common-pressure
  specialization rather than a consequence of additivity:
  `sections/multicomponent_solids.tex:3854-3898`.
- The pressure-average differential demonstrates why fixed phase pressure does
  not generally fix each component pressure, after which the admissible
  common-pressure EOS path is stated explicitly:
  `sections/multicomponent_solids.tex:3863-3898`.
- Composition, temperature, internal variables, and accumulated conversion are
  held fixed on that path; unequal component pressures require direct use of the
  phase coefficient.
- The additive specific-volume derivative uses the current mass fractions
  \(\eta_s^\alpha\), and the component Piola stresses consequently use
  \(\rho_{s0}\eta_s^\alpha\):
  `sections/multicomponent_solids.tex:3900-3981`.
- The displayed summation proves
  \(\sum_\alpha(1-B_s^\alpha)=1-B_s\) under the stated path:
  `sections/multicomponent_solids.tex:3983-4024`.
- The boxed component mixture rule is identified as a path-dependent
  compatibility result, not a general replacement for \(B_s\):
  `sections/multicomponent_solids.tex:4051-4084`.
- The abstract now makes the same qualification:
  `main.tex:51-54`.
- An independent reread returned `ACCEPT` for the pressure-path assumptions,
  component weights, phase stress roll-up, and one-component limit. The current
  build resolves the repaired displays as equations (239)--(248c) on pages
  54--55; pages 52--56 were visually rechecked.

Completed resolution:

- [x] Specify the component EOS and the allowed component-pressure path during
      deformation.
- [x] State that the optional decomposition uses a common equilibrated
      component pressure.
- [x] Prove that the summed component transform equals the phase transform under
      those assumptions.
- [x] Preserve the phase transform as the general result and qualify the
      component rule as an optional specialization.

### P0.5 Resolve the crystallization-pressure sign convention

Status: [x]

Evidence after repair:

- The crystallization subsection now states the tension-positive Cauchy-stress
  convention and identifies
  \(-\operatorname{tr}\boldsymbol\sigma_s'/3\) as positive compression:
  `sections/multicomponent_solids.tex:4319-4326`.
- The progress-variable normalization and its mass- and molar-basis alternatives
  are explicit:
  `sections/multicomponent_solids.tex:4326-4331`.
- The pressure-work derivation gives
  \(\mathcal A_{(m)}=\bar v_s[
  \bar p_{\mathrm{xtal},s}+\operatorname{tr}\boldsymbol\sigma_s'/3]\), so
  positive crystallization pressure balances positive compression:
  `sections/multicomponent_solids.tex:4333-4348`.
- The supersaturation form and reversible-equilibrium threshold retain that
  sign:
  `sections/multicomponent_solids.tex:4350-4394`.
- The stress-free, compressive, precipitation, and dissolution limiting cases
  are stated and checked:
  `sections/multicomponent_solids.tex:4396-4403`.
- An independent reread returned `ACCEPT` for the sign, normalization, and
  limiting cases. The current build resolves these displays as equations
  (264)--(267) on pages 57--58; both pages were visually rechecked.

Completed resolution:

- [x] Declare the stress and pressure sign conventions immediately before the
      crystallization relation.
- [x] Derive the mechanical contribution to the affinity using that convention
      and state its normalization.
- [x] Check the supersaturation formula and the equilibrium, stress-free,
      compressive, precipitation, and dissolution limits.

### P0.6 Remove the circularity in the Onsager rate constraint

Status: [x]

Evidence after repair:

- The independent reaction and \(N-1\) dispersion and diffusion rates, together
  with the state held fixed during stationarity, are stated explicitly:
  `sections/virtual_power_derivation.tex:1289-1309`.
- The electrochemical potentials are fixed thermodynamic state coefficients,
  not rate-constraint multipliers:
  `sections/virtual_power_derivation.tex:1311-1326`.
- The dependent accumulation rate is eliminated through the component
  conservation law before the Rayleighian is formed:
  `sections/virtual_power_derivation.tex:1328-1403`.
- The linear thermodynamic-rate variation contains only reaction and
  independent-flux variations; no redundant
  \(\delta\mu_\xi^\alpha\) multiplier row remains:
  `sections/virtual_power_derivation.tex:1484-1578`.
- The text identifies the component balance as the independent conservation
  law and does not claim to regenerate it by Onsager stationarity:
  `sections/virtual_power_derivation.tex:1579-1584`.
- An independent derivation audit confirmed the reaction and transport signs,
  dimensions, and force--rate pairing against the residual entropy inequality.

Completed resolution:

- [x] List the independent process rates and held-fixed state precisely.
- [x] Eliminate component accumulation through the balance before forming the
      reduced Rayleighian.
- [x] Retain the linear thermodynamic rate rather than substituting into an
      identically zero constraint residual.
- [x] Remove the redundant multiplier variation while preserving the component
      conservation law.

### P0.7 Write transport stationarity intrinsically on the zero-sum subspace

Status: [x]

Evidence after repair:

- The kinematic combined zero sum is distinguished from the block-diagonal
  constitutive specialization that makes dispersion and diffusion separately
  zero-sum: `sections/material_mass.tex:579-593`.
- Each flux family is parameterized by \(N-1\) independent components, and its
  reference-component flux is reconstructed explicitly:
  `sections/virtual_power_derivation.tex:1291-1305`.
- The reduced mobilities and their inverses act in the same \(N-1\)
  coordinates; the stationarity equations use only
  \((\mu_\xi^\alpha-\mu_\xi^N)/\theta_{\mathcal G}\):
  `sections/virtual_power_derivation.tex:1407-1447,1525-1686`.
- The entropy product rule, residual inequality, constitutive stationarity,
  closures, and positive-definite dissipation proof use the same reduced
  coordinates:
  `sections/multicomponent_solids.tex:2409-2480,2530-2552,2646-2789`.
- The classical compositional and Nernst--Planck--Darcy reductions use the same
  reference component and reconstruct its flux and balance:
  `sections/correspondence_to_other_theories.tex:52-108,391-429`.
- The existing model table count of \(2d(N-1)\) relative-flux unknowns per
  phase is therefore now derived rather than implicit.
- The 69-page build is warning-free. The affected displays and page boundaries
  were visually checked on pages 8, 23--25, 41--44, 59--60, and 62--64; two
  avoidable whitespace defects found during that check were corrected.

Completed resolution:

- [x] Use \(N-1\) independent fluxes and potential-difference forces.
- [x] Reconstruct each reference-component flux explicitly.
- [x] Use reduced positive-definite mobilities and reduced inverses
      consistently in the variational and constitutive sections.
- [x] Propagate the same formulation through the dissipation proof and special
      limits.

## Priority 1: completeness and modeling assumptions

### P1.1 Add objectivity, material symmetry, and angular-momentum restrictions

Status: [x]

Completed repair:

- [x] Added the superposed rigid-observer transformation rules for position,
      phase velocity and velocity differences, deformation factors,
      electrostatic potential and field, electric displacement, relative and
      heat fluxes, and Cauchy stress as equations (1a)--(1e):
      `sections/technical_setting.tex:85-160`.
- [x] Imposed frame indifference on the solid Helmholtz energy and phase
      electric enthalpy as equations (2a)--(2b), and required equivariance of
      tensor mobilities, permeabilities, conductivities, and vector closures:
      `sections/technical_setting.tex:162-204`.
- [x] Distinguished spatial observer changes from intermediate-configuration
      basis changes and required the plastic and stress-free laws to be
      invariant under both:
      `sections/technical_setting.tex:195-200`.
- [x] Identified the consequence of the present single-vector electrical state
      set: \(\mathbf d_\xi\parallel\mathbf E\), so the dielectric response is
      electrically isotropic and the Maxwell stress is symmetric.  Permanent
      polarization and bedding-directed dielectric anisotropy are now stated
      to require an added structural argument and torque bookkeeping:
      `sections/technical_setting.tex:206-227` and
      `sections/multicomponent_solids.tex:510-539`.
- [x] Stated the nonpolar angular-momentum assumptions and the resulting
      constituent total-stress symmetry as equation (4):
      `sections/technical_setting.tex:229-248`.
- [x] Preserved general mechanical anisotropy, stated the material-symmetry
      requirement, and identified when isotropic tensor representations are
      required.
- [x] Rebuilt the complete manuscript and visually inspected equations
      (1a)--(4) and the surrounding section on pages 3--4.

### P1.2 Add boundary conditions, initial conditions, and gauges

Status: [x]

Completed repair:

- [x] Derived the mechanical surface work and the complementary essential and
      natural constituent-traction conditions, including the overall
      Maxwell--Biot traction rollup:
      `sections/virtual_power_derivation.tex:113-132` and
      `sections/virtual_power_derivation.tex:670-711`.
- [x] Added compatible initial data for storage, temperatures, phase fractions,
      internal variables, electrostatic potential, and transfer potential, with
      the mean-zero initial gauge for \(\tau\):
      `sections/technical_setting.tex:322-342`.
- [x] Added complementary prescribed-total-flux and prescribed
      temperature-weighted electrochemical-potential boundary partitions.  The
      external-reservoir work has the sign needed to recover the nonzero
      prescribed potential difference, acts only on the dispersion-plus-
      diffusion relative flux, and holds phase advection fixed:
      `sections/virtual_power_derivation.tex:1541-1596` and
      `sections/virtual_power_derivation.tex:1710-1773`.
- [x] Added thermal temperature/heat-flux partitions, outward-flux sign
      convention, and pure-Neumann energy compatibility for both thermal
      subsystems:
      `sections/technical_setting.tex:396-439`.
- [x] Added electrostatic potential/displacement partitions, total-charge and
      charge-rate compatibility, and the electrostatic gauge:
      `sections/technical_setting.tex:250-302`.
- [x] Added the current, external-charge, and integrated component-balance
      compatibility conditions:
      `sections/technical_setting.tex:441-448`.
- [x] Independently re-audited the repaired source and visually inspected the
      relevant pages.  The 77-page build is clean, with no warnings, undefined
      references, or box diagnostics.

### P1.3 Define the admissible phase/component domain

Status: [x]

Completed repair:

- [x] Stated the active-domain requirements
      \(J_\xi>0\), \(\bar\rho_\xi>0\), \(0<\phi_\xi<1\),
      \(\eta_\xi^\alpha\ge0\), and both normalization constraints:
      `sections/technical_setting.tex:19-38`.
- [x] Restricted divisions by phase fractions or active component fractions and
      inverse mobility operators to their corresponding active subspaces:
      `sections/technical_setting.tex:38-40`.
- [x] Stated that phase appearance, phase disappearance, and changes of active
      component set require a complementarity or active-set treatment outside
      the local constitutive equations:
      `sections/technical_setting.tex:40-43`.
- [x] Independent source re-audit accepted the domain statement without
      mathematical correction.

### P1.4 Clarify source-carried energy and entropy

Status: [x]

Completed repair:

- [x] Identified recipient-phase energy and entropy transport as an adopted
      local-equilibrium source closure, not a general balance identity:
      `sections/multicomponent_solids.tex:714-718`.
- [x] Displayed the source-carried energy and entropy identities using the
      phase-following material rates, equation (170):
      `sections/multicomponent_solids.tex:720-769`.
- [x] Kept generalized insertion work distinct and stated what additional data
      a non-equilibrium source state would require:
      `sections/multicomponent_solids.tex:771-785`.
- [x] Required mechanism-by-mechanism conservation of reaction-associated
      internal-energy allocation and made the cross-subsystem allocation
      explicit, equations (203a)--(203b):
      `sections/multicomponent_solids.tex:2691-2721`.
- [x] Coupled charged cross-subsystem reaction rates to their energy-transfer
      allocation in the admissible Onsager block:
      `sections/multicomponent_solids.tex:2745-2751`.
- [x] Displayed the complete cancellation of mechanical, ordinary-heat, and
      reaction-associated internal exchange in the summed first law, equation
      (220), and connected it to the global field-power identity:
      `sections/multicomponent_solids.tex:3140-3214`.
- [x] Independent source re-audit accepted the source convention, exchange
      allocation, and total cancellation after the phase-following-rate
      correction.
- [x] Rebuilt cleanly and visually inspected equations (170), (203), and
      (219)--(223) on pages 34, 47, and 50.

### P1.5 Reconcile mass-based and molar stoichiometry

Status: [x]

Completed repair:

- [x] Stated the units of the component source, mass-based and molar progress
      rates, dimensionless mass yields, and mass coefficients:
      `sections/technical_setting.tex:304-320`.
- [x] Defined the molar-to-mass conversion as signed molar stoichiometry times
      component molar mass:
      `sections/technical_setting.tex:313-316`.
- [x] Recast carbonic-acid dissociation on a molar progress basis and displayed
      both its exact mass and charge checks, equation (224):
      `sections/multicomponent_solids.tex:3304-3349`.
- [x] Identified the one-to-one phase-transfer example as a mass-progress
      closure with dimensionless yields:
      `sections/multicomponent_solids.tex:3351-3363`.
- [x] Defined the ion-exchange site charge and neutral solid-site compounds,
      converted the molar coefficients to mass coefficients, and displayed the
      exact mass and charge checks, equation (228):
      `sections/multicomponent_solids.tex:3404-3456`.
- [x] Independent source re-audit accepted the units, conversions, and
      conservation checks after the explicit sum-sign correction.
- [x] Rebuilt cleanly and visually inspected equations (224)--(228) on
      pages 51--52.

### P1.6 Define saturation derivatives intrinsically

Status: [x]

Completed repair:

- [x] Defined every displayed held-fixed saturation derivative using an
      arbitrary \(C^2\) ambient extension of the intrinsic simplex potential
      and stated that admissible saturation variations remain tangent to
      \(\sum_fS_f=1\):
      `sections/virtual_power_derivation.tex:344-359` and
      `sections/virtual_power_derivation.tex:404-407`.
- [x] Proved in prose that two extensions differ on the simplex by a common
      normal component, which cancels from \(\gamma_f\), from every
      \(\gamma_f-\gamma_g\), and from
      \(\sum_fS_f\gamma_f\):
      `sections/virtual_power_derivation.tex:350-359` and
      `sections/virtual_power_derivation.tex:422-424`.
- [x] Added the intrinsic tangent-direction definition of capillary pressure
      as equation (77), so the sign convention is explicit without requiring
      an off-simplex coordinate variation:
      `sections/virtual_power_derivation.tex:436-453`.
- [x] Corrected the nonisothermal weighted-gradient identity to
      \[
      \sum_fS_f\nabla_{\mathbf x}\gamma_f
      =
      \left.
      \frac{\partial\gamma}{\partial\theta_{\mathcal F}}
      \right|_{\{S_f\}}
      \nabla_{\mathbf x}\theta_{\mathcal F},
      \]
      and propagated the resulting
      \(-\phi\gamma_{,\theta_{\mathcal F}}\nabla_{\mathbf x}\theta_{\mathcal F}\)
      thermocapillary force through the fluid rollup and overall spatial
      momentum balance, equations (227)--(230):
      `sections/multicomponent_solids.tex:3553-3681`.
- [x] Pulled the same force back to the solid reference configuration in both
      the general overall momentum equation (275) and its reservoir-solve copy
      (276):
      `sections/pulled_back_solid_skeleton.tex:340-378` and
      `sections/pulled_back_solid_skeleton.tex:391-421`.
- [x] Made the one-fluid Biot reduction set \(\gamma=0\), because no
      fluid--fluid interface remains, before identifying
      \(\bar p_E=\bar p_f\):
      `sections/correspondence_to_other_theories.tex:533-560`.
- [x] Verified extension-shift invariance, the wetting/non-wetting directional
      derivative sign, pressure-gradient dimensions, the isothermal recovery,
      and the one-fluid limit.
- [x] Rebuilt the complete manuscript and visually inspected equations (77),
      (227)--(230), (275)--(276), and (301) on pages 16, 51, 60--61, and 66.

### P1.7 Correct the time derivative in charge--Gauss compatibility

Status: [x]

Evidence after repair:

- The total charge balance is now written first in Eulerian form and then in its
  exact skeleton-observed conservative form:
  `sections/conservation_of_charge.tex:218-250`.
- Differentiating Gauss' law at fixed spatial position gives the Eulerian
  compatibility equation with
  \(\partial\mathbf d/\partial t\), total material-plus-external current, and
  the external charge supply:
  `sections/virtual_power_derivation.tex:1290-1308`.
- The exact solid-reference Piola form differentiates
  \(J\mathbf F^{-1}\mathbf d\) at fixed \(\mathbf X\) and transports current
  relative to the skeleton:
  `sections/virtual_power_derivation.tex:1310-1329`.
- Its push-forward contains the skeleton convective and deformation terms
  required by the ordinary-dot convention:
  `sections/virtual_power_derivation.tex:1331-1353`.
- The curl-equivalent compact form, sign derivation, dimensions, and
  zero-external and neutral limits are stated at
  `sections/virtual_power_derivation.tex:1356-1375`.
- An independent derivation reread accepted the Eulerian, Piola, and pushed
  forms without algebraic correction.
- The clean 73-page build resolves the compatibility forms as equations
  (116a)--(116c) on page 24; the complete page was visually rechecked.

Completed resolution:

- [x] Use the Eulerian partial derivative obtained by differentiating Gauss'
      law at fixed \(\mathbf x\).
- [x] Derive the equivalent skeleton-observed, solid-reference Piola, and
      pushed-forward forms with all convective terms.
- [x] Check signs, dimensions, curl equivalence, and stationary-skeleton,
      material-only, and neutral limits.

### P1.8 Complete the prescribed-charge model

Status: [x]

Evidence after repair:

- Total charge is split into component-carried charge and prescribed
  \(\varrho_{\rm ext}\), whose external current and supply satisfy their own
  conservative balance:
  `sections/conservation_of_charge.tex:32-59`.
- Static spatial, transported, and externally supplied loadings are
  distinguished, and only two members of the loading triplet may be prescribed
  independently:
  `sections/conservation_of_charge.tex:61-77`.
- The component current, material-carried balance, and combined total balance
  are kept distinct:
  `sections/conservation_of_charge.tex:158-250`.
- Charge attached to deforming solid sites remains component-carried charge and
  is explicitly excluded from the external contribution:
  `sections/conservation_of_charge.tex:252-264`.
- Electrical-displacement data are distinguished from current data; the
  pure-Neumann Gauss and fixed-domain rate compatibility conditions, additive
  potential gauge, and normal-current data are stated at
  `sections/technical_setting.tex:250-300,321-342`.
- The source-work ensemble and field-power identity retain total
  \(\varrho\) without adding stored \(\varrho\varphi\), a second electrical body
  force, or a duplicate \(\mathbf i\cdot\mathbf E\) term:
  `sections/virtual_power_derivation.tex:98-118` and
  `sections/multicomponent_solids.tex:788-799`.
- The Nernst--Planck--Darcy limit sets all external-charge data to zero:
  `sections/correspondence_to_other_theories.tex:335-345`.
- The abstract distinguishes material-carried from prescribed charge, and the
  model summary records the external triplet as loading data that adds no
  primary unknown or independent field equation:
  `main.tex:64-68` and `sections/multicomponent_solids.tex:4429-4435`.
- An independent source reread accepted the complete model, boundary/gauge
  consequences, source-work bookkeeping, and limiting cases without
  mathematical correction.
- The clean 73-page build resolves the external loading, total charge, and
  skeleton-observed balance as equations (44)--(55) on pages 10--12, the
  pure-Neumann compatibility as equations (5a)--(5b) on page 4, and the
  model-count qualification on page 58; all affected pages were visually
  rechecked.

Completed resolution:

- [x] Define static, transported, and externally supplied prescribed-charge
      loadings.
- [x] Include their current and supply in total charge conservation.
- [x] Keep external loading distinct from charge attached to a solid component.
- [x] Propagate the split through Gauss compatibility, boundary/gauge
      compatibility, field power, the Nernst--Planck--Darcy limit, abstract, and
      model count.

### P1.9 Qualify the finite-deformation Biot storage tangent

Status: [x]

Completed repair:

- [x] Derived the current-to-reference fluid-storage balance with the material
      derivative following the solid skeleton and the exact Piola transform:
      `sections/correspondence_to_other_theories.tex:604-662`.
- [x] Identified the porosity tangent as an adopted finite-deformation storage
      closure, not a consequence of the phase energy, and stated the additional
      reciprocity, integrability, and internal-storage assumptions:
      `sections/correspondence_to_other_theories.tex:691-708`.
- [x] Mapped the manuscript coefficient \(B\) to the classical
      Detournay--Cheng coefficient \(\alpha\) and stated the source's
      homogeneous-solid, coincident-unjacketed-moduli, and
      porosity-invariant-under-uniform-unjacketed-\(\Pi\)-loading
      specialization:
      `sections/correspondence_to_other_theories.tex:697-702`.
- [x] Verified the exact coefficient
      \(1/M=\phi/K_f+(\alpha-\phi)/K_s\) against Detournay and Cheng,
      Section 3.2.2 and Table 2, and added the verified chapter DOI:
      `all.bib:221-230`.
- [x] Required \(1/M>0\), stated the exact density-gradient term in the
      mass-to-volume flux conversion, and identified the small-strain and
      small-compressibility approximation:
      `sections/correspondence_to_other_theories.tex:711-755`.
- [x] Froze \(B\), \(M\), permeability, viscosity, and density at the reference
      state for the linearization and stated the incompressible, rigid-skeleton,
      and undrained limits:
      `sections/correspondence_to_other_theories.tex:774-821`.
- [x] Independently re-audited the derivative, source restriction, stability
      condition, limiting cases, and rendered equations.  The current 78-page
      theory build is clean.

### P1.10 Reclassify the modified-permeability positivity condition

Status: [x]

Completed repair:

- [x] Identified \(\sum_\alpha\dot c_f^\alpha\) as the net conversion
      phase-mass source, rather than a transport mobility or an independent
      dissipative coefficient:
      `sections/pulled_back_solid_skeleton.tex:82-88`.
- [x] Reclassified the inverse as a conversion-corrected mobility, recorded its
      resistance and mobility units, and distinguished it from permeability:
      `sections/pulled_back_solid_skeleton.tex:90-110`.
- [x] Stated exact eigenvalue-by-eigenvalue nonsingularity, the stronger
      positive-resistance condition, and the spectral condition number as
      separate requirements:
      `sections/pulled_back_solid_skeleton.tex:111-174`.
- [x] Replaced the approximate reaction-time statement by the exact first
      singular threshold and distinguished loss of positive definiteness from
      later eigenvalue crossings:
      `sections/pulled_back_solid_skeleton.tex:175-198`.
- [x] Kept thermodynamic dissipation attached to the underlying drag and
      component-transport closures:
      `sections/pulled_back_solid_skeleton.tex:223-234`.
- [x] Propagated the force, terminology, and invertibility distinction through
      the companion implementation weak form and closure contract:
      `implementation_paper/sections/reference_solid_weak_forms.tex:88-145`,
      `implementation_paper/sections/scope.tex:54-64`, and
      `implementation_paper/sections/open_questions.tex:38-45`.
- [x] Independently re-audited the algebra, dimensions, consumers, and rendered
      equations; the theory and companion displays are clean.

### P1.11 Correct the scope of the reservoir-simulation summary

Status: [x]

Completed repair:

- [x] Renamed and scoped the material as a quasi-static mechanics--fluid
      subblock and stated that it is not the complete coupled model:
      `sections/pulled_back_solid_skeleton.tex:449-458`.
- [x] Classified momentum and component balances as primary residuals, the
      velocity and flux laws as constitutive reconstructions, and the capillary
      relation as an algebraic closure:
      `sections/pulled_back_solid_skeleton.tex:578-585`.
- [x] Listed the solid balances, two subsystem energy balances, Gauss' law,
      kinetics, solid internal-variable evolution, and remaining constitutive
      restrictions required by the full model:
      `sections/pulled_back_solid_skeleton.tex:586-590`.
- [x] Independently audited the scope and the rendered summary pages.

### P1.12 Move the general effective Piola definition before its first use

Status: [x]

Completed repair:

- [x] Defined
      \(\mathbf P^{\prime\prime}=J\boldsymbol{\sigma}^{\prime\prime}
      \mathbf F^{-T}\) before the solid-reference overall momentum equation:
      `sections/pulled_back_solid_skeleton.tex:394-406`.
- [x] Made the later single-fluid Biot specialization reference that general
      definition:
      `sections/correspondence_to_other_theories.tex:586-600`.
- [x] Verified the active include order and all consumers.

### P1.13 Qualify the charged two-temperature reaction closure

Status: [x]

Completed repair:

- [x] Restricted the explicit scalar temperature-weighted reaction law to
      neutral mechanisms or mechanisms conserving charge separately within
      each thermal subsystem:
      `sections/multicomponent_solids.tex:2431-2454` and
      `sections/multicomponent_solids.tex:2723-2758`.
- [x] Stated that a charged cross-subsystem mechanism replaces the scalar law
      by a gauge-invariant coupled reaction--energy Onsager block whose energy
      rate satisfies the mechanismwise energy allocation.
- [x] Propagated the qualification through the variational Onsager potential,
      ordinary heat exchange, charged sorption, the correspondence section, and
      the model-count discussion:
      `sections/virtual_power_derivation.tex:1630-1640`,
      `sections/multicomponent_solids.tex:3139-3145`,
      `sections/multicomponent_solids.tex:3394-3396`, and
      `sections/correspondence_to_other_theories.tex:281-299`.
- [x] Independently verified that no unqualified scalar charged-transfer
      closure remains.

### P1.14 Qualify the model-summary closure claim

Status: [x]

Completed repair:

- [x] Scoped the count to a reduced, fully implicit, bulk-pointwise active-phase
      formulation and stated that it is not a complete boundary-value-problem
      specification:
      `sections/multicomponent_solids.tex:4635-4642`.
- [x] Classified the normalization multipliers as eliminated, the storage
      multipliers as reconstructed algebraically, one reference-component
      equation as the evolution equation for \(\tau\), and the remaining
      componentwise forms as compatibility checks:
      `sections/multicomponent_solids.tex:4643-4653`.
- [x] Identified the uncounted initial/boundary data, gauges, pure-Neumann
      compatibility, active-set logic, and optional charged reaction--energy
      closure:
      `sections/multicomponent_solids.tex:4663-4669`.
- [x] Renamed both table captions to state their bulk active-phase scope and
      independently recomputed every row; the printed unknown and equation
      totals agree:
      `sections/multicomponent_solids.tex:4692-4770`.

### P1.15 Make the special-case assumptions fully explicit

Status: [x]

Completed repair:

- [x] In the Nernst--Planck--Darcy limit, set external charge loading, fixed
      solid charge, and solid electrical displacement to zero, while stating
      the alternative effective-dielectric interpretation:
      `sections/correspondence_to_other_theories.tex:332-346`.
- [x] In the black-oil limit, imposed the neutral nonelectrical specialization
      on electric enthalpy, component charge, external charge/current/supply,
      electric field, and displacement before using the classical capillary
      laws:
      `sections/correspondence_to_other_theories.tex:448-460`.
- [x] Stated that the present algebraic capillary closure excludes dynamic
      capillary pressure, drainage--imbibition hysteresis, and independent
      interfacial-area evolution:
      `sections/virtual_power_derivation.tex:486-491`.
- [x] Independently audited the specializations and their rendered equations.

## Priority 2: prose, notation, and displayed mathematics

### P2.1 Split the collected entropy inequality

Status: [x]

Completed repair:

- [x] Preserved `eq:MC_collected_entropy` as the master inequality and split its
      unchanged right-hand side into five labelled continuations:
      elastic/distension, density/composition, temperature,
      reaction/transport, and residual dissipation:
      `sections/multicomponent_solids.tex:1188-1596`.
- [x] Added prose stating explicitly that the five blocks form one inequality:
      `sections/multicomponent_solids.tex:1599-1606`.
- [x] Added a compact block-to-rate/restriction audit table:
      `sections/multicomponent_solids.tex:1608-1652`.
- [x] Verified the rendered master collection as equation (158), with
      subequations (158a)--(158e) on pages 33--34 and the audit table on page 35.

### P2.2 Repair the local-thermal-equilibrium reaction display

Status: [x]

Completed repair:

- [x] Converted the reaction-power result to a single aligned equality in an
      `align` environment and punctuated its final row:
      `sections/multicomponent_solids.tex:2224-2234`.
- [x] Stated
      \(\theta_{\mathcal F}=\theta_{\mathcal S}=\theta\) in prose or as a
      separately punctuated condition rather than a chained equality:
      `sections/multicomponent_solids.tex:2220-2222`.

### P2.3 Number or inline the unnumbered positivity displays

Status: [x]

Completed repair:

- [x] Numbered and descriptively labelled the quadratic-form positivity,
      scalar eigenvalue, and reaction time-scale displays:
      `sections/pulled_back_solid_skeleton.tex:97-128`.
- [x] Verified the displays as equations (253)--(255) on page 54.

### P2.4 Correct display punctuation in the deformation-gradient definition

Status: [x]

Completed repair:

- [x] Removed punctuation from the first, nonfinal equality and punctuated the
      final row as part of its surrounding sentence:
      `sections/material_mass.tex:77-81`.

### P2.5 Correct local wording errors

Status: [x]

- [x] Changed “mass conversation” to “mass conservation”:
      `sections/material_mass.tex:285-288`.
- [x] Replaced “compositional balance per unit mass” with “mass-based component
      balance per unit current mixture volume”:
      `sections/correspondence_to_other_theories.tex:30-34`.

### P2.6 Remove global `\sloppy` after the technical revision

Status: [x]

Completed repair:

- [x] Removed the document-wide `\sloppy`; `\begin{document}` now occurs
      directly at `main.tex:38`.
- [x] Rebuilt the manuscript and repaired the two local overfull lines by
      revising their prose without changing mathematical content.
- [x] Reinspected the entropy collection on pages 33--35, the reaction display
      on page 39, the positivity displays on page 54, and the model-summary
      tables on pages 52--53.
- [x] Confirmed that the final log contains no LaTeX warnings, errors, overfull
      boxes, underfull boxes, or undefined references.

### P2.7 Add a technical assumptions and notation section

Status: [x]

Completed repair:

- [x] Added `sections/technical_setting.tex` before the main derivation and
      included it from `main.tex:74`.
- [x] Defined phase, component, subsystem, and mechanism index sets; current and
      reference domains; measure conventions; active-state positivity; and
      phase/component active-set scope:
      `sections/technical_setting.tex:9-43`.
- [x] Defined observer and rate conventions:
      `sections/technical_setting.tex:45-58`.
- [x] Stated stress and pressure signs, thermal grouping, energy
      normalizations, constitutive regularity, objectivity, material symmetry,
      and angular-momentum implications:
      `sections/technical_setting.tex:60-95`.
- [x] Stated the electroquasistatic ensemble, source-work interpretation,
      electrical boundary partition, gauge fixing, and constitutive electrical
      scope:
      `sections/technical_setting.tex:97-117`.
- [x] Defined the admissible mass-based and molar progress-rate/stoichiometric
      pairings and their units:
      `sections/technical_setting.tex:119-135`.
- [x] Listed the required initial and complementary boundary-data classes and
      compatibility conditions:
      `sections/technical_setting.tex:137-154`.

## Citation and bibliography review

### Bibliography integrity

- [x] Every citation key used by the active manuscript exists in `all.bib`.
- [x] BibTeX completes successfully.
- [x] The final build contains no undefined citations.

### Claim-level findings

#### C1. Seguin and Walkington

Status: [x]

The cited solid-observer framework is now used consistently: the manuscript
retains skeleton-following storage together with the relative internal-energy
and entropy fluxes present in equations (10)--(12). The former claim that bulk
relative motion appeared only in momentum and interaction powers was removed.

Local source:

`references/pdfs/seguin-walkington-2019-multicomponent-multiphase-flow-poroelastic.pdf`

#### C2. Kim, Tchelepi, and Juanes

Status: [x]

The paper supports the nonelectrical equivalent-pressure relation
\(p_E=p-U\), where \(U\) is interfacial energy. It does not directly establish
the manuscript's phase-attributed electrical correction
\(\sum_fS_f\omega_f^+\).

Local source:

`references/pdfs/kim-tchelepi-juanes-2013-spej.pdf`

Resolution:

- [x] The text now cites Kim et al. only for the neutral
      capillary/interfacial relation.
- [x] The electrical subtraction is explicitly identified as the present
      extension derived from the manuscript's phase-pressure relation.

#### C3. Foster and Xu

Status: [x]

The local manuscript supports the nonlinear Biot coefficient interpreted as a
specific-volume derivative at fixed pore pressure.

Local source:

`references/pdfs/foster-xu-2026-nonlinear-biot.pdf`

#### C4. Ignatova and Shu

Status: [x]

The cited equations (1.1)--(1.5) support the stated
Nernst--Planck--Darcy system.

Source:

<https://arxiv.org/abs/2107.13655>

#### C5. Yamamoto, Doi, and Andelman

Status: [x]

The source supports Maxwell and osmotic effects in electrowetting, but it does
not by itself verify the exact phase-averaged electrocapillary pressure-jump
formula used in the manuscript.

Source:

<https://arxiv.org/abs/1510.00613>

Resolution:

- [x] The prose is limited to consistency with related electrowetting
      interface balances and related Maxwell forces; it does not attribute the
      manuscript's phase-averaged jump formula to Yamamoto et al.

#### C6. Montanaro metadata

Status: [x]

The official arXiv record was submitted in 2009 and revised in 2015, while the
current BibTeX entry presents it simply as a 2015 preprint:
`all.bib:7440-7446`.

Source:

<https://arxiv.org/abs/0910.1344>

Resolution:

- [x] The bibliography now records the original 2009 submission year and the
      2015 version-3 revision.
- [x] The equation-(12)/(16) comparison was checked against arXiv:0910.1344v3.
      Equation (12) supplies
      \(\rho\dot\varepsilon=\boldsymbol{\tau}:\nabla\boldsymbol v
      -\operatorname{div}\boldsymbol q
      +\boldsymbol E^M\cdot\rho\dot{\boldsymbol\pi}+\rho r\), while equation
      (16) contains the electric-work term
      \(-\boldsymbol E^M\cdot\boldsymbol\pi\). Their combination gives the
      displayed \(-\boldsymbol P\cdot\dot{\boldsymbol E}^M\) term.

#### C7. Book-specific equation claims

Status: [x]

The exact Balhoff and Coussy equation claims were not verifiable from locally
available full text. They are not rejected; they remain `not-verifiable`.

Resolution:

- [x] The unverified Balhoff equation-number locator was removed. Balhoff is
      retained as the general reservoir-simulation source for the standard
      advective component-balance structure.
- [x] The Balhoff bibliography entry now records the official
      *Developments in Petroleum Science* series volume 75.
- [x] The manuscript no longer attributes its finite-deformation porosity
      tangent to Coussy. It identifies that tangent as an adopted extension,
      uses Coussy for the classical poromechanics context, and gives the
      quantitative small-strain storage formula under the explicit
      Detournay--Cheng assumptions.
- [x] Exact full-text equation evidence is recorded above for the claims that
      retain equation-level attribution.

## Revision sequence

The recommended order is important because early corrections propagate into
later sections.

### Stage 1: fundamental balance and variational repair

- [x] Resolve P0.1: electrical action and ensemble.
- [x] Resolve P0.2: skeleton-frame energy and entropy balances.
- [x] Rebuild the electrical and thermal parts of the Coleman--Noll
      exploitation.
- [x] Confirm summed mass, charge, momentum, total energy, and entropy balances.

### Stage 2: component thermodynamics and rate spaces

- [x] Resolve P0.3: chemical potentials on the composition simplex.
- [x] Resolve P0.6 and P0.7: independent Onsager rates and projected transport
      stationarity.
- [x] Recheck reaction affinities, diffusion, dispersion, phase equilibrium,
      and the compositional-flow reduction.

### Stage 3: solid pressure transforms and reaction mechanics

- [x] Resolve P0.4: additive component Biot assumptions.
- [x] Resolve P0.5: crystallization-pressure sign.
- [x] Recheck phase and overall stress roll-ups.
- [x] Recheck the single-solid/single-fluid Biot limit.

### Stage 4: mathematical completeness

- [x] Add objectivity and angular-momentum restrictions.
- [x] Add admissible phase/component domains.
- [x] Add boundary, initial, and gauge conditions.
- [x] Complete or qualify the charged reaction--energy closure.
- [x] Clarify source-carried energy and stoichiometric units.

### Stage 5: summary and special-case audit

- [x] Reaudit the reservoir solve block.
- [x] Reaudit the unknown/equation tables.
- [x] Recheck the black-oil, compositional, Nernst--Planck--Darcy, and Biot
      reductions.
- [x] Qualify any remaining “complete,” “general,” or “thermodynamically
      consistent” claims to match the final scope.

### Stage 6: presentation and publication polish

- [x] Split the collected entropy display.
- [x] Correct display style and punctuation.
- [x] Add the assumptions/notation section.
- [x] Remove global `\sloppy` and visually recheck the PDF.
- [x] Complete the full-text citation audit.
- [x] Write the introduction and conclusions only after the governing theory and
      its scope are stable.

## Final acceptance checklist

The technical review can be considered closed when:

- [x] the written electrical functional generates every stated electrical
      Euler--Lagrange and constitutive contribution;
- [x] every observer transformation in the energy and entropy balances is
      explicit;
- [x] chemical potentials and transport forces live on a well-defined
      composition/flux space;
- [x] the phase and component Biot transforms use demonstrably compatible
      held-fixed paths;
- [x] stress, pressure, and crystallization signs are unambiguous;
- [x] balance laws, constitutive restrictions, and dissipative closures are
      separated cleanly;
- [x] objectivity, angular momentum, state domains, gauges, boundary conditions,
      and initial conditions are stated;
- [x] all advertised special limits follow under explicit assumptions;
- [x] the model-summary counts match the actual retained equations and closure
      blocks;
- [x] every equation-specific citation has full-text support;
- [x] the final PDF builds cleanly and every multi-page display has been
      visually inspected.
