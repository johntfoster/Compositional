# SPE2 three-phase coning verification report

## Verdict

Status: **implementation in progress; benchmark acceptance not yet claimed**.
The primary tables, SI conversions, exact radial Q2 mesh, Stone-II relative
permeability, and the revised saturation-force pressure identity have passing
regressions. The coupled 900-day CG/EG solve, reference comparison, convergence
study, field plots, and final performance record remain outstanding.

The current workflow state is **candidate-only**. All eleven reusable SPE2
fragments are registry candidates at `0.1.0-candidate`; none has a protected
verified payload. The deck assembler must therefore reject a production SPE2
assembly until explicit promotion is authorized and supported by fresh mapped
evidence.

## Provenance

- Primary paper: H. G. Weinstein, J. E. Chappelear, and J. S. Nolen,
  *Second Comparative Solution Project: A Three-Phase Coning Study*,
  SPE-10489-PA (1986), [archival PDF](https://www.ipt.ntnu.no/~kleppe/pub/SPE-COMPARATIVE/papers/second.pdf).
- Machine-readable transcription:
  [`spe2_primary_tables.yml`](../reference_data/spe2_primary_tables.yml),
  SHA-256 `71c763e8d7312d916a17b745f5066308ea45e270b18f967b23212c52fac3184b`.
- SI conversion record:
  [`spe2_si_conversions.yml`](../reference_data/spe2_si_conversions.yml),
  SHA-256 `fbe4b1653072fa3cfc4d27ade9760d9981bdd57cfdfe9c26cd0ca1fad7d0c458`.
- Theory-manuscript fingerprint at this checkpoint:
  `3b2612b65e4e694d7b73687e6c573e23be9b55ebac657ed6f3af87ff3354a0f1`.
- MOOSE base commit: `abafb58b67a6037c6723ffeb19647c84484466da`.
- Applied MOOSE patch: `0001-skip-automatic-premake-check.patch`, SHA-256
  `4e2f5980525c3b0c23743135a9ce0b69caea310a2c5c96101da6060b44923ee5`.
- Application library at this checkpoint: SHA-256
  `d35793e147d8d0bc2d64d0ec5197b6a55894a483559f0a8f35fc713cfa6ca20b`.

The source audit preserves two printed PVT inconsistencies instead of changing
the paper's values. At 800 psia, the printed saturated-oil density differs from
the mass/FVF identity by `0.1345621 lbm/ft3`. At 1200 psia, the printed gas
density differs by `0.0178398 lbm/ft3`. Every other oil row agrees within
`0.009274 lbm/ft3`, every other gas row within `0.000454 lbm/ft3`, and every
water row within `0.003074 lbm/ft3`.

The theory source advanced after that checkpoint. The candidate audit was
re-read against `sections/virtual_power_derivation.tex` SHA-256
`d621f9242b66827b9e5843d78c7b7f1320b097fa4cf320a600650a0deadbb121`
and `sections/multicomponent_solids.tex` SHA-256
`5e55454b51edc52a3d8a58808c9cab2ec1fb4a939a08ed32be4b55e4f04f0b0c`.
The current equations identify phase-pressure force differences with
generalized saturation-force differences, close those forces through a
symmetric positive-semidefinite resistance, and carry the dynamic lag into the
summed momentum balance. The candidate gates now require the phase-pressure
force identity, saturation-redistribution dissipation, and the official
zero-resistance dynamic-lag specialization. Current-theory coverage remains
pending until the repository-wide momentum audit is reconciled.

## Active and inactive physics

SPE2 is a phase-transforming black-oil problem. Dissolved gas leaves or enters
the oil phase as free gas appears, disappears, and reappears during drawdown
and repressuring. The production model therefore requires the full
nonequilibrium structure, including the shared transfer potential `tau`, the
dissolved- and free-gas electrochemical potentials `mu`, their affinity,
finite-rate phase conversion, nonnegative conversion dissipation, and the
associated mass, momentum, and energy transfer terms. These terms may not be
replaced by an equilibrium-only flash in the acceptance run.

The manuscript revision represented by the fingerprint above introduces the
generalized saturation forces explicitly. For oil as the reference fluid,
the implemented pressure identities are

```text
p_w - p_o = (gamma_w - gamma_o)
            + (omega_w^+ - omega_o^+)
            + (L_w^sat - L_o^sat),

p_g - p_o = (gamma_g - gamma_o)
            + (omega_g^+ - omega_o^+)
            + (L_g^sat - L_o^sat).
```

The generalized-force differences are supplied by the complete symmetric
Onsager matrix

```text
L_f^sat - L_o^sat = sum_g T_fg dot(S_g).
```

`ADSaturationOnsagerForceMaterial` evaluates the cross-coupled force,
`dot(S)^T T dot(S)`, and `phi dot(S)^T T dot(S)/theta_F`. It rejects
nonsymmetric and indefinite matrices. `ADBlackOilPhasePressureDifferenceMaterial`
then stitches the stored surface-energy, electrical-enthalpy, and Onsager terms
together as independent input-deck selections.

The official SPE2 data activate gravity segregation, water and gas coning,
tabulated PVT, equilibrium capillary surface energy, Stone-II three-phase
relative permeability, two completion cells, the prescribed oil-rate schedule,
and the 3000-psia minimum flowing-BHP control. The electrical specialization is
neutral, so the electrical-enthalpy differences evaluate to zero in the
official run while remaining present as selectable terms. Dynamic capillary
resistance is not specified by SPE2; its official coefficients are therefore
zero, while the full matrix path is implemented and regression tested.
Fracture and dual-porosity physics are outside the current scope.

The production-theory run will retain solved reference-solid mass, phase-volume
closure, Q2 displacement, momentum, and two temperature equations. The SPE2
thermal data define an isothermal specialization, so the fluid and solid
temperature solutions must remain constant while their complete storage,
transport, exchange, conversion-work, stress-power, and electrical-energy
families remain assembled.

## Deck provenance and CG/EG spaces

`deck_status: candidate_only`.

The primary grid has 10 radial cells and 15 vertical layers. The finite-element
mesh uses exactly 150 `QUAD9` elements and 651 nodes in MOOSE `RZ` coordinates.
It spans radii `0.0762–624.84 m` and depths `2743.2–2852.6232 m`. Completion
blocks 107 and 108 are the innermost radial cells in layers 7 and 8.

The mesh include is
[`spe2_rz_q2_quad9.i`](../../moose_app/input/includes/mesh/spe2_rz_q2_quad9.i),
SHA-256 `a31d4c4810319aceb89b8abdb2a3d772f539556e9db4d4e3f11f28595f081534`.
MOOSE RZ quadrature gives

- total physical volume: `134213723.41922 m3`;
- layer-7 completion volume: `2.8022399126271 m3`;
- layer-8 completion volume: `2.8022399126271 m3`.

The relative errors against the analytic annular volumes are
`1.11e-16`, `8.56e-15`, and `8.56e-15`, respectively. The preserved CSV is
[`spe2_mesh_volume_audit.csv`](../results/spe2/mesh_audit/spe2_mesh_volume_audit.csv),
SHA-256 `81446523ea7342509b80725fef7ba5a2e982060ce124964c09dda59fca70ce4b`.

The planned production spaces are Q2 Lagrange solid displacement; P1
continuous oil/equivalent-pressure and `tau` backbones plus P0 enrichments;
P2 continuous water and gas saturation backbones plus P0 enrichments; P2
phase-pressure-difference fields for the capillary/electrical/Onsager closure;
and the continuous parent solution-gas field. Reconstructed physical
saturations retain coefficient bounds and entropy-viscosity stabilization.
No finite-volume variable or finite-volume acceptance path is used.

The candidate registry records are exact-byte audited as follows. Every entry
is `0.1.0-candidate`; these hashes qualify static candidate provenance and are
not protected production payloads.

| Candidate fragment | SHA-256 |
|---|---|
| `mesh.spe2_rz_q2_quad9` | `a31d4c4810319aceb89b8abdb2a3d772f539556e9db4d4e3f11f28595f081534` |
| `fields.spe2_black_oil_q2_eg` | `72d39af2cfe625bff93afd6d7df2540a111ed2e1f91be2310dfe161e28932df6` |
| `ics.spe2_layer_solid_storage` | `11860a5cff26a2feea7175de4fe68549586052c516abf070d37577e89b28fdc9` |
| `materials.spe2_black_oil_pvt` | `ecc33670e527d2d3b6ad9bd548dcc40c15b4f5694fed95a9273dc9f689c20aad` |
| `materials.spe2_layer_permeability` | `524c34807187c7a638dfb4ac0a94c1d36b1a64b1883733955ea162aaadf40aec` |
| `materials.spe2_phase_pressure_closure` | `c38c0fe691d12dfa6b4187c62105405d3e0fadafb5b6abdd4e41c040f47485c6` |
| `operators.spe2_phase_pressure_closure` | `abd39e0a26666ffec4209f6353c922f1e51cf1235d1e4f8c19517c876ec73ee7` |
| `fields.spe2_producer_control` | `ddf47d55c8202c6d17a6be7e303095b7e6373b7aec7f35b51f4ddc0badab631d` |
| `schedules.spe2_oil_rate_schedule` | `f8d3f9e66568693a253e488d690b3390ec1bafe68e0da1afd7e7713c06d71cf6` |
| `materials.spe2_producer_well` | `d93ad40507c075f3d8699162046bb3da1635c6d00004d07cba2e153c58998203` |
| `operators.spe2_producer_control` | `ee43ad16a43c86248cd319c0c22f9e40765dbc482ecdac4c5ce1fb6581a2c999` |

## Quantitative gates

The focused command

```bash
agent_environment/skills/setup-moose-conda/scripts/moose_conda_env.sh run -- \
  .agent-runtime/moose/scripts/run_tests -j 1 \
  --re='phase_pressure_difference_all_terms|saturation_onsager_force|stone_ii_spe2_table|spe2_(primary_tables|rz_q2_mesh_volume)'
```

passes 7 tests with 0 skipped and 0 failed:

1. primary-table structure, units, density identities, and SI conversion;
2. exact Q2 RZ mesh node, element, reservoir-volume, and completion-volume audit;
3. exact SPE2 saturation-table interpolation and Stone-II oil mobility;
4. full cross-coupled generalized saturation-force, dissipation, and entropy production;
5. rejection of a nonsymmetric Onsager resistance matrix;
6. rejection of an indefinite Onsager resistance matrix;
7. exact stitched stored surface-energy, electrical-enthalpy, and generalized-force pressure differences.

These tests verify the named constitutive and geometry components. They are not
evidence for a completed 900-day reservoir solve.

## Reproduction commands and artifacts

`command_status: candidate-static-only`. The executed static audit command was

```bash
python3 validation/scripts/run_spe2_candidate_verification.py \
  --output-dir .agent-runtime/results/spe2-candidate-static-audit-3
```

It returned `coupled_pending`, validated the problem schema and eleven exact
candidate digests, and generated the initial-state audit. Its `/tmp` output is
diagnostic and is not a durable acceptance artifact. The runner rejects
`--claim production`. A coupled invocation must additionally supply the actual
result CSV and a preserved output directory; it remains unavailable until the
revised theory objects and scenario deck compile and pass.

The structured candidate problem is
[`spe2_black_oil_coning_candidate.problem.json`](../../agent_workflows/specs/spe2_black_oil_coning_candidate.problem.json).
It fixes the exact RZ geometry, Q2/P1+P0/P2+P0 spaces, four-phase registry,
phase-transforming thermodynamics, anisotropic Darcy closure, two-completion
control, two-temperature specialization, required observables, and forbidden
reductions. It intentionally omits `deck_assembly`: that schema field accepts
verified block identifiers, while every SPE2 block is still a candidate.

The machine-readable gate contract is
[`spe2_candidate_gates.yml`](../reference_data/spe2_candidate_gates.yml). The
provenance runner
[`run_spe2_candidate_verification.py`](../scripts/run_spe2_candidate_verification.py)
validates the problem schema, confirms exact candidate registry digests,
generates the initial state, optionally runs the focused atomic tests under the
shared SPE lock, and evaluates a supplied coupled CSV. It rejects a production
claim before execution. A static audit confirms all eleven candidate digests
and leaves the coupled status explicitly `pending`.

The deterministic hydrostatic/capillary initializer is
[`generate_spe2_initial_state.py`](../scripts/generate_spe2_initial_state.py).
It anchors oil pressure at 3600 psia at the 9035-ft gas-oil contact, integrates
gas and water pressure from the published contacts, inverts the official SGOF
and SWOF capillary curves, and uses the benchmark PVT mass/FVF identities. At
layer centers it obtains

- oil: `28.8926614 million STB`;
- water: `73.9317206 million STB`;
- gas: `47.0898953 billion scf`, comprising `6.9301650` free and `40.1597303`
  dissolved billion scf.

All three totals lie inside the published participant envelopes. These values
qualify the initial-state generator; they are not results from the coupled
finite-element deck.

The report plotter
[`plot_spe2_candidate_results.py`](../scripts/plot_spe2_candidate_results.py)
consumes the provenance artifact and produces rate, water-cut, GOR, BHP,
conservation, admissibility, and initial saturation-profile figures. By
default it refuses an incomplete artifact.

## Convergence, robustness, and performance

`status: pending`. The coupled program requires radial/vertical mesh
refinement that preserves the 2050-ft outer radius, 15 layers, and completion
mapping; timestep refinement across days 1, 10, 50, and 720; pressure,
saturation, and `tau` approximation-order studies; active-set and control-switch
robustness; and partition independence. Every level must report degrees of
freedom, accepted/rejected timesteps, nonlinear and linear iterations, cuts,
memory, and wall time on stated hardware. The official 150-cell mapping remains
the reference topology rather than an assumed converged solution.

## Official reference comparison

`official_horizon_status: pending`.

`status: pending`. The final comparison must use the published participant
initial-fluid envelope and official oil-rate, water-cut, GOR, datum-BHP, and
`p(1,7)-BHP` histories at matched report times through day 900. It must record
digitization or tabulation provenance, FIELD/SI conversions, interpolation,
error denominators including zero-reference handling, and participant-envelope
distance. No coupled MOOSE history or like-for-like official comparison exists.

## Plots and source-data provenance

`source_data_status: missing`.

The acceptance artifact must contain the exact assembled deck and include
manifest, command, environment and source fingerprints, solver log, CSV and
field output, a machine-readable gate summary, and plot-generation command.
The 900-day result must report the official initial fluids in place; initial
water and gas saturation profiles; oil rate, water cut, GOR, BHP, and
`p(1,7)-BHP`; time on decline; accepted and rejected timesteps; nonlinear
updates; and wall time.

The final report will include pressure and water/gas saturation snapshots,
rate and BHP histories with control switches, cumulative production,
component-balance and admissibility histories, `tau`/`mu`/affinity and
dissipation histories, momentum and two-temperature energy residuals,
mesh/time/order convergence, and published-participant overlays. No such plot
is claimed at this checkpoint.

No generated plot artifact is linked. The future well-history plots must
consume the preserved coupled `result.csv`; field figures must consume named
Exodus or element/nodal CSV outputs; gate figures must consume
`verification_summary.json`; initial profiles must consume
`initial_saturation_profile.csv`; and official overlays must identify the
digitized/table source checksum. The candidate plotter refuses incomplete
evidence unless diagnostic override is explicitly requested.

## Remaining blockers

The next implementation step is the scenario-local exploratory CG/EG
phase-transforming deck driven by the qualified initial-state profile. It must
stitch the existing 15-layer permeability, PVT, phase-pressure, schedule, and
well candidates to anisotropic phase-transforming Darcy fluxes, component
balances, axisymmetric reference-solid momentum and mass, the current
generalized saturation-force and dynamic-lag terms, the full `tau`/`mu`
conversion row, DG facet and weak-boundary operators, and both energy equations.
Acceptance then requires authorized block promotion, protected assembly, the
900-day solve, component and solid mass conservation, phase-volume closure,
saturation admissibility, positive solid Jacobian, momentum and energy gates,
well-control complementarity, convergence studies, reference comparisons, and
the complete plot bundle.
