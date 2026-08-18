# SPE5 miscible-flood verification report

## Verdict

Status: **pending implementation** for official SPE5 Case 1. No production
deck, miscibility model, preserved run, or comparison exists.

## Provenance

- Official problem: *Fifth Comparative Solution Project: Evaluation of
  Miscible Flood Simulators*, J. E. Killough and C. A. Kossack,
  SPE-16000-MS (1987).
- Case scope: OPM `spe5/SPE5CASE1.DATA` and the publication links under `spe5`
  in `validation/spe_benchmark_inventory.yml`.
- Pinned source repository: `opm-data` commit
  `eaa2261683a97027e057c2bc49612ad1c86390b3`. Deck and reference-series
  checksums have not been recorded.
- Extractor/conversion commands and run fingerprints remain missing.

## Active and inactive physics

Planned active physics are the official four-component miscible or fully
compositional storage and transport model, mixing/EOS closure, phase behavior,
miscibility-dependent relative permeability, wells, component breakthrough,
and component/phase reporting. A nonequilibrium phase-transfer realization
also requires chemical potentials, reconstructed `tau`, finite-rate transfer,
dissipation, and conversion energy. Reference-solid mechanics, solid mass, and
phase-volume closure remain active in the production-theory solve.

Electrical forcing, surface-energy gradients, fracture/dual porosity, and
unrelated reactions are deliberately inactive. Thermal energy may be inactive
only after the official isothermal assumption is confirmed and cited.

## Deck provenance and CG/EG spaces

`deck_status: missing`.

- Parent deck and fragments: missing.
- Official geometry, data, initial state, mixing parameters, wells, schedule,
  and report times remain to be imported.
- Planned production spaces: Q2 Lagrange displacement; P1 continuous pressure
  and, when active, `tau`, each with P0 enrichment; P2 continuous saturation
  backbones with P0 enrichments and admissibility stabilization.
- Composition/EOS variables and orders, miscibility interpolation,
  phase-appearance policy, and thermal spaces remain unresolved.
- SI is required internally with explicit surface/reservoir conversions.

## Reproduction commands and artifacts

`command_status: missing`. Required artifacts are the pinned source/deck hash,
assembled deck and include manifest, command, environment fingerprints, solver
log, CSV and fields, gate summary, EOS/mixing diagnostics, reference series,
conversion record, and plots.

## Quantitative gates

No observations exist. Gates must cover component/solid balances, phase volume,
composition/saturation admissibility, flash/mixing residuals, transfer kinetics
and dissipation when used, energy when active, mechanics/Jacobian, controls,
solver completion, and convergence. Internal limits remain to be set.

External targets are at most 5% relative error in oil recovery and component
cumulative production. Breakthrough-time errors must be reported in days; its
acceptance limit must be fixed before execution.

## Convergence, robustness, and performance

+`status: pending`. The plan requires spatial, timestep, composition-order, and
miscibility-transition studies; robustness tests at breakthrough, phase
appearance, and control switches; and iteration, timestep-cut, memory, and wall
time reporting. Breakthrough definitions must remain unchanged across studies.

## Plots and source-data provenance

`source_data_status: missing`.

Required plots are component/miscibility fronts, pressure and phase fields,
breakthrough, rates and recovery, mass/energy and kinetic gates, mechanics,
controls, convergence, and official/OPM overlays.

+No plot or source artifact exists. Future figures must name the component
field/summary artifact, mixing-model revision, and reference-series checksum.

## Official reference comparison

`official_horizon_status: pending`.

The authoritative series, report times, interpolation, component mapping,
conversions, breakthrough definition, and zero-reference policy remain
unselected. No comparison is claimed.

## Remaining blockers

Record deck/reference hashes; implement the mixing/EOS package; assemble the
CG/EG deck; define gates and breakthrough processing; run convergence; and
complete the official-horizon comparison.
