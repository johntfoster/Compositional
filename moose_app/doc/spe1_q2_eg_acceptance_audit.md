# SPE1 finite-deformation Q2/EG acceptance audit

Date: 2026-08-05

## Controlling model

Production acceptance is the four-phase matrix/water/oil/gas model in
`agent_workflows/specs/spe1_black_oil.problem.json`.  The fluid balances use
the solid-reference storage and flux in
`eq:solid_reference_fluid_component_balance`; the matrix balance uses
`eq:solid_reference_solid_component_balance`; and mechanics uses
`eq:solid_reference_overall_momentum` with the stress in
`eq:solid_reference_effective_piola_stress`.  The black-oil component storage,
phase flux, and capillary closures are
`eq:black_oil_storage_identifications` through
`eq:black_oil_capillary_pressure_closures`.

## Thermodynamic closure used for SPE1 acceptance

SPE1 supplies isothermal black-oil PVT and saturation tables, rather than a
caloric equation of state for the phase Helmholtz energies.  The acceptance
deck therefore uses an explicitly synthetic isothermal consistency closure for
dissolved-gas/free-gas transfer.  Stock-tank densities map (R_s) to the oil
phase gas mass fraction.  A convex penalty about the PVTO-attainable mass
fraction supplies the oil-phase Helmholtz composition derivative, and the
composition projection in `eq:MC_fluid_composition_force_difference` together
with the phase-pressure storage sums supplies the absolute component chemical
potentials.  The free-gas Helmholtz datum aligns the pure-gas absolute
potential with the oil pressure-work level at the attainable composition.

This construction enforces the manuscript's composition projection, Euler
identities, absolute-potential difference, transfer-work recovery, and
nonnegative finite-rate conversion power.  It is an isothermal black-oil
closure for this benchmark, not a predictive caloric Helmholtz EOS.  The
absolute energy datum and the chosen convex stiffness are therefore unsuitable
for temperature-dependent calorimetry or transferring the energy scale to a
different fluid system.  Such applications require a calibrated compositional
or caloric Helmholtz model while retaining the same projection and
transfer-work interfaces.

## Stage-0 equilibrium gate

The acceptance runner first advances the full finite-deformation Q2/EG system
with closed boundaries, inactive wells, zero component sources, and full
mixture gravity.  This pseudo-time stage uses the production variables,
closures, facet operators, mechanics, phase transformation, and subsystem
energy equations.  It must satisfy the component, solid, phase-volume,
mechanics, \(\tau\)-chemical-potential, and energy gates before the official
schedule starts from its checkpoint at reported time zero.

The stage record includes initial-to-final reference-mass changes for water,
oil, gas, and solid, global and local residual histories, and element-sampled
RMS/maximum deviations from the official layer-centered EQUIL/RSVD/SWOF
mapping.  The production-stage well accumulators are absent from stage 0 and
are created at zero when the official schedule begins.  Gravity homotopy is a
fallback continuation aid only; the final checkpoint must independently pass
all gates with the full acceleration.

## Current SPE1 deck classification

`examples/spe1_case1_transient.i` is a fixed-skeleton finite-element
diagnostic.  It retains the matrix/oil/gas/water registry, the P1 continuous
oil-pressure backbone with P0 enrichment, continuous water saturation, gas
saturation, and dissolved-gas fields, the three black-oil component balances,
EG oil-pressure interior-facet terms, SPE1 PVT and saturation data, completion
blocks, and one-step well controls.

The deck prescribes `solid_reference_J = 1`, `solid_reference_J_dot = 0`, and
`solid_reference_F_inv = I`.  It has no displacement variables, matrix
component balance, phase-volume residual, total-stress material, or momentum
residual.  Its Cartesian HEX mesh also conflicts with the active TET10 policy
for coupled three-dimensional Q2/EG solves.  These omissions exclude the deck
from production acceptance even though `--check-input` reports `Syntax OK`.

The cell-centered `*_fv` decks remain separately labeled diagnostics.  Their
day-151 balance and OPM comparison values are retained in the validation
inventory and have no production-acceptance role.

`examples/spe1_case1_q2_eg_transient.i` is the first executable parent-theory
slice.  It uses the 1800-element TET10 mapping, solved Q2 displacement,
reconstructed P1+P0 oil pressure, continuous black-oil state fields,
`ADSolidReferenceKinematics`, source-free matrix constituent storage
`J phi_s rho_s`, the constraint `phi_s + phi_f = 1`, compressible
Neo-Hookean effective stress, and all three total-stress momentum rows.  Wells
are inactive in this initialization slice.  The legacy FE and FV decks remain
unchanged as diagnostics.

## Exact theory-to-code gaps

1. Extend the converged initialization slice to the active INJ and PROD
   completions.  The current nodal scalar controller linearizes only against
   the P1 backbone and must be made consistent with the reconstructed total
   pressure before it can supply an AD/PETSc production Jacobian.
2. Use the reconstructed P1+P0 pressure in every PVT, stress, flux, and well
   object.  Retain the enrichment volume row, interior flux and symmetry
   terms, and any weak boundary term required by the chosen EG boundary data.
3. Reconstruct water and gas phase pressures from the SPE1 capillary tables
   before their Darcy fluxes.  The current SPE1 tables make the offsets zero,
   but the closure path must remain explicit.
4. Enforce admissible black-oil phase appearance.  The converged initialization
   has minimum gas saturation `-7.164486e-2`; this is a physical acceptance
   blocker even though the nonlinear and global-balance residuals converge.
5. Replace the explicit initialization choices `nu=0.25` and `B=1` if
   independent matrix shear or grain-compressibility evidence is obtained.
   The current values are declared untuned modeling specializations: the
   official ROCK compressibility supplies `K=1/c_r`, and `B=1` is the
   incompressible-grain limit.
6. Verify completion aggregation after each Cartesian report cell is
   subdivided into six tetrahedra, then add AD/PETSc Jacobian, mesh-convergence,
   time-step-convergence, and official report comparisons.

## Smallest executable implementation sequence

1. Correct the gas-appearance residual so the continuous phase state remains
   admissible without clipping or cached values, and add its AD Jacobian test.
2. Couple the shared well controller to reconstructed total EG pressure and
   verify one TET10 completion with the official rate/BHP data.
3. Activate both wells and the three finite-element component balances, EG facets, and one
   completion at the first SPE1 time step.  Require nonlinear convergence and
   quantitative solid/fluid balance evidence.
4. Activate the official schedule, then perform spatial and
   temporal convergence before reporting OPM discrepancies.

## Executable mesh milestone and blocker

`examples/spe1_case1_q2_eg_mesh_only.i` preserves the 10 by 10 by 3 physical
cell partition, layer IDs, completion regions, and report coordinates.  Each
Cartesian cell is split into six tetrahedra and elevated to TET10.  The run
reports 1800 elements, 3087 nodes, and 12997 degrees of freedom for Q2
displacement, P1+P0 pressure, and continuous black-oil state fields.

The optimized one-day initialization solve converged in 19 Newton iterations
with final nonlinear residual `9.227500e-10`.  It produced nonzero deformation
with average `J=1.010810`; the matrix storage-rate integral was
`8.620422e-16`, the phase-volume residual L2 norm was `9.569270e-13`, and the
water/oil/gas global defects were `4.987300e-13`, `1.635314e-11`, and
`2.167155e-13`.  The matrix balance residual L2 norm was `4.213679e-8`.

This is a genuine coupled finite-deformation Q2/EG milestone, not SPE1
production acceptance.  Wells and the official schedule remain inactive, the
matrix balance norm needs a stronger quantitative gate, and the minimum gas
saturation `-7.164486e-2` is inadmissible.  The next blocker is therefore the
continuous black-oil phase-appearance treatment, followed by a total-EG-pressure
well-control Jacobian.  No OPM quantity was used to choose the skeleton inputs.
