# Comprehensive Technical Review of the Theory Manuscript

Date: 2026-07-26  
Repository baseline: `master` at `4dba770`  
Immediate owner: theory manuscript  
Status: review plus tracked repairs; P0.1 and all Priority 2 items are fully
repaired and validated

## Purpose and scope

This document records the comprehensive technical review of the active theory
manuscript so that every finding can be tracked through revision.

The review covered the complete `main.tex` compilation graph:

- `main.tex`
- `defs.tex`
- `sections/technical_setting.tex`
- `sections/material_mass.tex`
- `sections/conservation_of_charge.tex`
- `sections/virtual_power_derivation.tex`
- `sections/multicomponent_solids.tex`
- `sections/pulled_back_solid_skeleton.tex`
- `sections/correspondence_to_other_theories.tex`
- `all.bib`

The inactive file `sections/variational_derivation.tex` was excluded because it
is not included by `main.tex`. The introduction and conclusions were excluded
because they have not yet been written.

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

The manuscript has a strong and unusually coherent architecture. Its mass and
charge bookkeeping, phase-attached variational structure, solid kinematics,
entropy exploitation, Biot reduction, and reservoir specializations are
organized around a largely consistent notation.

It is not yet technically ready for submission. The electrical variational
ensemble, moving-fluid energy and entropy balances, compositional chemical
potentials, additive Biot specialization, and several rate-space and
completeness issues must be resolved first. These are structural matters that
can propagate into the entropy restrictions, closures, special limits, abstract,
and summary tables.

## Validation performed

- [x] Reviewed the active source graph rooted at `main.tex`.
- [x] Inspected `defs.tex` before interpreting project-local notation.
- [x] Audited every active section for balance-law, state-dependency,
      chain-rule, force--flux, and closure consistency.
- [x] Scanned labels, references, citations, and display environments.
- [x] Rebuilt with `pdflatex -> bibtex -> pdflatex -> pdflatex`.
- [x] Confirmed a 66-page PDF after the P0.1 and Priority 2 repairs.
- [x] Found no undefined references or citations.
- [x] Found no reported LaTeX warnings, errors, overfull boxes, or underfull
      boxes in the final build log.
- [x] Visually inspected all rendered pages and inspected dense displays at
      larger scale.

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

Status: [ ]

Evidence:

- The classical closure set states
  \(\mu_f^\alpha=\partial g_f/\partial\eta_f^\alpha\):
  `sections/correspondence_to_other_theories.tex:52-76`.
- The subsequent chemical-potential tangent and effective Fick tensor use the
  unconstrained Hessian of \(g_f\):
  `sections/correspondence_to_other_theories.tex:79-106`.
- The manuscript elsewhere recognizes that only \(N-1\) composition
  coordinates are independent: `sections/multicomponent_solids.tex:398-401`.

Technical concern:

For a specific mixture Gibbs energy defined on
\(\sum_\alpha\eta_f^\alpha=1\), absolute chemical potentials are not generally
the unconstrained mass-fraction derivatives of \(g_f\). In \(N-1\) independent
coordinates, the derivatives give chemical-potential differences. With an
appropriate off-simplex extension, one standard representation is

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

Recommended resolution:

- [ ] Define chemical potentials through derivatives with respect to component
      masses at fixed pressure, temperature, and the other component masses; or
- [ ] use \(N-1\) independent mass fractions and
      \(\mu_f^\alpha-\mu_f^N\).
- [ ] Rewrite the composition-gradient tangent in the same coordinate system.
- [ ] Project the diffusion/dispersion mobility and thermodynamic Hessian onto
      the composition tangent space.
- [ ] Recheck the phase-equilibrium and Fickian specializations.

### P0.4 Establish the assumptions behind the additive component Biot rule

Status: [ ]

Evidence:

- The general phase transform exchanges intrinsic specific volume for the
  common equivalent/phase pressure:
  `sections/multicomponent_solids.tex:2952-3134`.
- The component specialization holds each
  \(\bar p_s^\alpha\) fixed independently:
  `sections/multicomponent_solids.tex:3532-3605`.
- The component corrections are summed to define the phase coefficient:
  `sections/multicomponent_solids.tex:3620-3659`.

Technical concern:

Holding the phase pressure

\[
\bar p_s
=
\sum_\alpha
\phi_s^\alpha\bar p_s^\alpha
\]

fixed does not generally imply that every component pressure is fixed. The
component fixed-pressure derivatives therefore do not automatically decompose
the phase derivative at fixed \(\bar p_s\).

Recommended resolution:

- [ ] Specify the component EOS and the allowed component-pressure path during
      deformation.
- [ ] State whether component pressures are independent, equilibrated, or tied
      to one common pressure.
- [ ] Prove that the summed component transform equals the phase transform under
      those assumptions.
- [ ] If that proof does not hold generally, present the component rule as an
      optional additive approximation rather than a decomposition of the
      general phase coefficient.

### P0.5 Resolve the crystallization-pressure sign convention

Status: [ ]

Evidence:

- The overall stress uses the conventional pressure contribution
  \(-B\bar p_E\mathbf I\):
  `sections/multicomponent_solids.tex:3368-3387`.
- The crystallization affinity uses
  \[
  \mathcal A_{(m)}
  =
  \bar v_s
  \left[
  \bar p_{\mathrm{xtal},s}
  -
  \frac13\operatorname{tr}\boldsymbol\sigma_s'
  \right]:
  \]
  `sections/multicomponent_solids.tex:3819-3918`.

Technical concern:

Under a tension-positive Cauchy-stress convention, the positive compressive
mechanical pressure is
\(-\operatorname{tr}\boldsymbol\sigma_s'/3\). As written, positive
crystallization pressure equilibrates with positive tensile mean stress unless
\(\bar p_{\mathrm{xtal}}\) is intentionally defined with a tensile sign.

Recommended resolution:

- [ ] Declare the stress and pressure sign conventions immediately before the
      crystallization relation.
- [ ] Derive the mechanical contribution to the solid chemical potential using
      that convention.
- [ ] Check the supersaturation formula and the equilibrium statement.

### P0.6 Remove the circularity in the Onsager rate constraint

Status: [ ]

Evidence:

- The text says that
  \(\dot{\mathcal C}_\xi^\alpha/J_\xi\) is evaluated from reaction and relative
  flux rates:
  `sections/virtual_power_derivation.tex:1244-1249`.
- The same equation is then imposed as a multiplier constraint:
  `sections/virtual_power_derivation.tex:1251-1271`.

Technical concern:

If \(\dot{\mathcal C}_\xi^\alpha/J_\xi\) is already a dependent expression, the
constraint residual is identically zero before variation. If it is an
independent accumulation rate, that must be stated and included among the
varied rates.

Recommended resolution:

- [ ] List the independent rates in the Onsager principle precisely.
- [ ] Decide whether component accumulation is independent or eliminated.
- [ ] If it is independent, retain the multiplier constraint.
- [ ] If it is eliminated, substitute the balance before forming the reduced
      dissipation potential and remove the redundant multiplier variation.

### P0.7 Write transport stationarity intrinsically on the zero-sum subspace

Status: [ ]

Evidence:

- The mobility inverse is said to act only on the zero-sum relative-flux
  subspace: `sections/virtual_power_derivation.tex:1341-1345`.
- The stationarity equations are displayed as unrestricted componentwise
  equalities: `sections/virtual_power_derivation.tex:1517-1549`.
- The later constitutive section acknowledges singular full-space mobilities:
  `sections/multicomponent_solids.tex:2450-2526`.

Technical concern:

Variation subject to
\(\sum_\alpha\delta\mathbf j_\xi^\alpha=\mathbf0\) produces a projected force
balance. It does not require the full component-force vector to vanish. The
current equation is correct only if “equals zero” is read as an equality in the
quotient/tangent space, which should not be left implicit.

Recommended resolution:

- [ ] Introduce an explicit tangent-space projector; or
- [ ] write the force balance modulo a common phase potential; or
- [ ] use \(N-1\) independent fluxes and forces.
- [ ] Use the same formulation in both the variational and constitutive
      sections.

## Priority 1: completeness and modeling assumptions

### P1.1 Add objectivity, material symmetry, and angular-momentum restrictions

Status: [ ]

Evidence:

- The solid free energy depends on
  \(\bar{\mathbf F}_s^e\) and \(\mathbf A_s^e\):
  `sections/multicomponent_solids.tex:358-395`.
- No explicit frame-indifference, angular-momentum, or stress-symmetry
  restriction is stated in the active manuscript.

Recommended resolution:

- [ ] State the transformation of every kinematic and electrical variable under
      a superposed rigid motion.
- [ ] Impose frame indifference on the solid free energy and dissipative
      closures.
- [ ] State the angular-momentum balance and the resulting stress-symmetry
      conditions, including any electromagnetic qualifications.
- [ ] State material symmetry assumptions for isotropic specializations.

### P1.2 Add boundary conditions, initial conditions, and gauges

Status: [ ]

Evidence:

- Mechanical boundary terms are omitted:
  `sections/virtual_power_derivation.tex:233-247`.
- Constraint and electrical boundary terms are omitted:
  `sections/virtual_power_derivation.tex:650-668` and
  `sections/virtual_power_derivation.tex:785-803`.
- Onsager entropy-flux boundary terms are omitted:
  `sections/virtual_power_derivation.tex:1386-1434`.

Recommended resolution:

- [ ] Derive the natural mechanical tractions.
- [ ] State essential and natural phase-motion conditions.
- [ ] State component no-flux, prescribed-flux, and chemical-potential
      conditions.
- [ ] State thermal Dirichlet and heat-flux conditions for both subsystems.
- [ ] State electrostatic potential and electric-displacement boundary
      conditions.
- [ ] State electrical and transfer-potential gauges.
- [ ] State initial conditions for storage variables, temperature, internal
      variables, phase fractions, and the transfer potential.

### P1.3 Define the admissible phase/component domain

Status: [ ]

Evidence:

- The material constraint divides by
  \(\phi_\xi\bar\rho_\xi\eta_\xi^\alpha\):
  `sections/virtual_power_derivation.tex:74-79`.
- Other constitutive and stationary relations repeatedly divide by phase
  fractions and component mass fractions or invert mobilities.

Recommended resolution:

- [ ] State whether the present theory assumes
      \(\phi_\xi>0\), \(\bar\rho_\xi>0\), and
      \(\eta_\xi^\alpha>0\).
- [ ] Explain how phase appearance, phase disappearance, and absent components
      are handled.
- [ ] For reservoir simulation, identify whether complementarity, variable
      switching, regularization, or an active-set formulation is required.

### P1.4 Clarify source-carried energy and entropy

Status: [ ]

Evidence:

- Inserted or removed component mass is assumed to carry the recipient phase
  specific internal energy:
  `sections/multicomponent_solids.tex:630-635`.

Technical concern:

Mass transferred between phases or created by a reaction generally carries a
source-specific energy and entropy. Setting it equal to the recipient phase
value is a closure assumption, not a general balance identity.

Recommended resolution:

- [ ] Define source-carried energy and entropy or state the equilibrium
      assumption that makes them equal to recipient values.
- [ ] Show explicitly how latent heat, reaction energy, and interphase energy
      supply preserve the summed total-energy balance.

### P1.5 Reconcile mass-based and molar stoichiometry

Status: [ ]

Evidence:

- \(\nu_{\xi(m)}^\alpha\) is defined as a mass-based coefficient:
  `sections/material_mass.tex:240-260`.
- The chemical-reaction and ion-exchange examples are written with ordinary
  molar stoichiometric integers:
  `sections/multicomponent_solids.tex:2882-2888` and
  `sections/multicomponent_solids.tex:2940-2950`.

Recommended resolution:

- [ ] State the units of \(\dot r_{(m)}\).
- [ ] Give the conversion from molar stoichiometric coefficients to the
      manuscript's mass-based coefficients.
- [ ] Check both mass and charge conservation for the example mechanisms.

### P1.6 Define saturation derivatives intrinsically

Status: [ ]

Evidence:

- The interfacial potential is defined on the constrained saturation simplex:
  `sections/virtual_power_derivation.tex:285-301`.
- Later derivatives are written while holding all other saturations fixed.

Technical concern:

All saturations cannot be varied independently while
\(\sum_fS_f=1\). Although pressure differences may be invariant to a common
off-simplex extension, the derivative convention must be stated.

Recommended resolution:

- [ ] Use \(P_{\mathcal F}-1\) independent saturations; or
- [ ] specify an off-simplex extension of \(\gamma\) and show which results are
      extension invariant.

### P1.7 Correct the time derivative in charge--Gauss compatibility

Status: [ ]

Evidence:

- The compatibility equation is
  \(\nabla_{\mathbf x}\cdot(\dot{\mathbf d}+\mathbf i)=0\):
  `sections/virtual_power_derivation.tex:1207-1219`.
- The ordinary dot is later defined as skeleton-following:
  `sections/multicomponent_solids.tex:53-71`.

Recommended resolution:

- [ ] Use the Eulerian partial derivative implied by differentiating Gauss' law
      and combining it with the Eulerian charge balance; or
- [ ] derive the fully skeleton-observed form, including its convective terms.

### P1.8 Complete the prescribed-charge model

Status: [ ]

Evidence:

- Prescribed charge may be included as a known contribution to \(\varrho\):
  `sections/conservation_of_charge.tex:44-48`.
- The subsequent current and balance include only component-carried charge:
  `sections/conservation_of_charge.tex:129-181`.

Recommended resolution:

- [ ] Define whether prescribed charge is static, transported, or externally
      supplied.
- [ ] Include its current and source in charge conservation when applicable.
- [ ] Keep it distinct from charge attached to a solid component.

### P1.9 Qualify the finite-deformation Biot storage tangent

Status: [ ]

Evidence:

- The porosity tangent is adopted in the single-solid/single-fluid reduction:
  `sections/correspondence_to_other_theories.tex:622-650`.
- The source cited is classical poromechanics.

Recommended resolution:

- [ ] Label the tangent as an adopted finite-deformation extension unless it is
      derived from the manuscript's constitutive theory.
- [ ] Verify that the cited source supports the exact stated form.
- [ ] State the density-gradient and small-compressibility assumptions used when
      converting the reference mass flux to the small-strain volumetric flux:
      `sections/correspondence_to_other_theories.tex:652-695`.

### P1.10 Reclassify the modified-permeability positivity condition

Status: [ ]

Evidence:

- The source-corrected operator is described as a dissipative mobility and its
  positive definiteness as thermodynamic admissibility:
  `sections/pulled_back_solid_skeleton.tex:78-134`.

Technical concern:

The drag tensor is dissipative. The added scalar conversion-insertion term comes
from momentum/source algebra and is not itself an entropy-producing drag
coefficient. Positive definiteness of the combined operator is a sufficient
solvability and conditioning requirement for the algebraic flux elimination,
not automatically a second-law restriction.

Recommended resolution:

- [ ] Describe the condition as a solvability/validity criterion.
- [ ] Keep the thermodynamic admissibility statement attached to the underlying
      drag and transport mobilities.

### P1.11 Correct the scope of the reservoir-simulation summary

Status: [ ]

Evidence:

- The summary calls its displayed mechanics equation the general
  finite-deformation form while setting inertia to zero:
  `sections/pulled_back_solid_skeleton.tex:363-389`.
- It includes fluid component balances and relative fluxes but omits the solid
  component balances, subsystem energy equations, Gauss' law, and full reaction
  and constitutive closure graph:
  `sections/pulled_back_solid_skeleton.tex:390-481`.

Recommended resolution:

- [ ] Rename it the quasi-static mechanics--fluid subblock; or
- [ ] include the complete coupled solve graph.
- [ ] State explicitly which equations are primary residuals and which
      quantities are reconstructed algebraically.

### P1.12 Move the general effective Piola definition before its first use

Status: [ ]

Evidence:

- `sections/pulled_back_solid_skeleton.tex:324-348` uses
  \(\mathbf P^{\prime\prime}\) through a cross-reference to a definition located
  later in the single-solid/single-fluid special-case section:
  `sections/correspondence_to_other_theories.tex:512-519`.

Recommended resolution:

- [ ] Define the general solid-reference effective Piola stress before the
      solid-reference overall momentum equation.
- [ ] Let the later Biot special case reference that general definition.

### P1.13 Qualify the charged two-temperature reaction closure

Status: [ ]

Evidence:

- The manuscript correctly notes that a reaction transferring net charge
  between the thermal subsystems requires a coupled reaction--energy Onsager
  block:
  `sections/multicomponent_solids.tex:2195-2218` and
  `sections/multicomponent_solids.tex:2444-2448`.
- The block is not actually specified.

Recommended resolution:

- [ ] Either construct the gauge-invariant coupled block; or
- [ ] state that the current explicit kinetics apply only to neutral mechanisms
      or mechanisms conserving charge separately within each thermal subsystem.

### P1.14 Qualify the model-summary closure claim

Status: [ ]

Evidence:

- The model summary describes a reduced, fully implicit formulation of the
  complete model:
  `sections/multicomponent_solids.tex:3949-3982`.
- The unknown and equation totals match algebraically, but boundary data,
  initial data, phase appearance, constitutive-domain conditions, and the
  charged reaction--energy block are outside the count.

Recommended resolution:

- [ ] Rename the tables as bulk pointwise unknown and equation counts under the
      stated active-phase and closure assumptions.
- [ ] Add a note identifying uncounted gauges, boundary conditions, initial
      conditions, and optional coupled closure blocks.
- [ ] Clarify whether the transfer-potential compatibility equations are
      constitutive checks, algebraic constraints, or equations used to eliminate
      storage multipliers.

### P1.15 Make the special-case assumptions fully explicit

Status: [ ]

Recommended resolution:

- [ ] In the black-oil limit, explicitly set electrical enthalpy, charge, and
      electric field to zero before using classical capillary laws:
      `sections/correspondence_to_other_theories.tex:378-467`.
- [ ] In the Nernst--Planck--Darcy limit, state that solid dielectric
      displacement and fixed solid charge vanish or have already been folded
      into the effective fluid response:
      `sections/correspondence_to_other_theories.tex:276-300`.
- [ ] State that the present capillary closure excludes dynamic capillary
      pressure, hysteresis, and independent interfacial-area evolution unless
      those effects are added constitutively.

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

Status: [ ]

The paper supports the nonelectrical equivalent-pressure relation
\(p_E=p-U\), where \(U\) is interfacial energy. It does not directly establish
the manuscript's phase-attributed electrical correction
\(\sum_fS_f\omega_f^+\).

Local source:

`references/pdfs/kim-tchelepi-juanes-2013-spej.pdf`

Recommended resolution:

- [ ] Cite Kim et al. for the capillary/interfacial part.
- [ ] Present the electrical term as this manuscript's extension or support it
      with a source that derives the same homogenized pressure relation.

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

Status: [ ]

The source supports Maxwell and osmotic effects in electrowetting, but it does
not by itself verify the exact phase-averaged electrocapillary pressure-jump
formula used in the manuscript.

Source:

<https://arxiv.org/abs/1510.00613>

Recommended resolution:

- [ ] Narrow the prose to “consistent with related electrowetting balances”; or
- [ ] add a source deriving the same pressure-jump relation under matching
      homogenization assumptions.

#### C6. Montanaro metadata

Status: [ ]

The official arXiv record was submitted in 2009 and revised in 2015, while the
current BibTeX entry presents it simply as a 2015 preprint:
`all.bib:7440-7446`.

Source:

<https://arxiv.org/abs/0910.1344>

Recommended resolution:

- [ ] Record the original year and, if useful, note the 2015 revision/version.
- [ ] Recheck the manuscript's exact equation (12) and equation (16) comparison
      against the cited version.

#### C7. Book-specific equation claims

Status: [ ]

The exact Balhoff and Coussy equation claims were not verifiable from locally
available full text. They are not rejected; they remain `not-verifiable`.

Recommended resolution:

- [ ] Check Balhoff equation (7.15b) in the full book.
- [ ] Check the precise Coussy support for the finite-deformation porosity
      tangent and equivalent-pressure claims.
- [ ] Record page/equation evidence before final submission.

## Revision sequence

The recommended order is important because early corrections propagate into
later sections.

### Stage 1: fundamental balance and variational repair

- [x] Resolve P0.1: electrical action and ensemble.
- [x] Resolve P0.2: skeleton-frame energy and entropy balances.
- [x] Rebuild the electrical and thermal parts of the Coleman--Noll
      exploitation.
- [ ] Confirm summed mass, charge, momentum, total energy, and entropy balances.

### Stage 2: component thermodynamics and rate spaces

- [ ] Resolve P0.3: chemical potentials on the composition simplex.
- [ ] Resolve P0.6 and P0.7: independent Onsager rates and projected transport
      stationarity.
- [ ] Recheck reaction affinities, diffusion, dispersion, phase equilibrium,
      and the compositional-flow reduction.

### Stage 3: solid pressure transforms and reaction mechanics

- [ ] Resolve P0.4: additive component Biot assumptions.
- [ ] Resolve P0.5: crystallization-pressure sign.
- [ ] Recheck phase and overall stress roll-ups.
- [ ] Recheck the single-solid/single-fluid Biot limit.

### Stage 4: mathematical completeness

- [ ] Add objectivity and angular-momentum restrictions.
- [ ] Add admissible phase/component domains.
- [ ] Add boundary, initial, and gauge conditions.
- [ ] Complete or qualify the charged reaction--energy closure.
- [ ] Clarify source-carried energy and stoichiometric units.

### Stage 5: summary and special-case audit

- [ ] Reaudit the reservoir solve block.
- [ ] Reaudit the unknown/equation tables.
- [ ] Recheck the black-oil, compositional, Nernst--Planck--Darcy, and Biot
      reductions.
- [ ] Qualify any remaining “complete,” “general,” or “thermodynamically
      consistent” claims to match the final scope.

### Stage 6: presentation and publication polish

- [ ] Split the collected entropy display.
- [ ] Correct display style and punctuation.
- [ ] Add the assumptions/notation section.
- [ ] Remove global `\sloppy` and visually recheck the PDF.
- [ ] Complete the full-text citation audit.
- [ ] Write the introduction and conclusions only after the governing theory and
      its scope are stable.

## Final acceptance checklist

The technical review can be considered closed when:

- [ ] the written electrical functional generates every stated electrical
      Euler--Lagrange and constitutive contribution;
- [ ] every observer transformation in the energy and entropy balances is
      explicit;
- [ ] chemical potentials and transport forces live on a well-defined
      composition/flux space;
- [ ] the phase and component Biot transforms use demonstrably compatible
      held-fixed paths;
- [ ] stress, pressure, and crystallization signs are unambiguous;
- [ ] balance laws, constitutive restrictions, and dissipative closures are
      separated cleanly;
- [ ] objectivity, angular momentum, state domains, gauges, boundary conditions,
      and initial conditions are stated;
- [ ] all advertised special limits follow under explicit assumptions;
- [ ] the model-summary counts match the actual retained equations and closure
      blocks;
- [ ] every equation-specific citation has full-text support;
- [ ] the final PDF builds cleanly and every multi-page display has been
      visually inspected.
