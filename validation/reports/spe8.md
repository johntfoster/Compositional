# SPE8 gridding-techniques verification report

## Verdict

Status: **pending implementation**. No SPE8 geometry import, selected FE mesh
family, executable deck, artifact, or comparison exists.

## Provenance

- Official problem: *Eighth SPE Comparative Solution Project: Gridding
  Techniques in Reservoir Simulation*, P. Quandalle, SPE-25263-MS (1993).
- Public specifications: the links under `spe8` in
  `validation/spe_benchmark_inventory.yml`.
- Source revision/checksum, participant data, geometry conversion, and
  run-specific manuscript/MOOSE/executable fingerprints remain unrecorded.

## Active and inactive physics

Planned active physics are official black-oil multiphase storage/transport,
geometry/fault representation, locally refined or flexible grids, conservative
facet fluxes, non-Cartesian well coupling, controls, and grid-dependent
reporting. Reference-solid mechanics, solid mass, and phase volume are required
for the production-theory comparison.

Electrical, thermal, miscible, reactive, surface-energy, and fracture/dual-
porosity physics are deliberately inactive unless explicitly required by the
pinned problem. Fault geometry is active; a separate fracture continuum is not.

## Deck provenance and CG/EG spaces

`deck_status: missing`.

- Parent deck and include fragments: missing.
- Official geometry, faults, properties, initial state, wells, schedule, and
  participant reporting definitions remain to be imported.
- Planned spaces on every selected mesh: Q2 Lagrange displacement; P1
  continuous pressure plus P0 enrichment; P2 continuous saturation backbones
  plus P0 enrichments; parent solution-gas closure where applicable.
- The reference-grid-to-FE mapping, refinement sequence, fault interfaces,
  well coupling, EG facet/weak-boundary operators, bounds, scaling, and solvers
  remain unresolved and must be identical in documented physical meaning.
- SI is required internally with explicit reporting conversions.

## Reproduction commands and artifacts

`command_status: missing`. Each mesh requires a mapping manifest, exact deck/includes,
command, environment hashes, solver log, CSV/fields, gate summary, performance
record, reference data, and plotting command.

## Quantitative gates

No metric is measured. Gates must include component/solid balances, local and
global facet conservation, phase volume, admissibility, mechanics/Jacobian,
well controls, solver completion, and systematic grid/time/order convergence.
Internal numerical limits remain unset.

Selected FE results must follow the published participant trends and remain
within 5% relative error in cumulative production on the declared reference
grid.

## Convergence, robustness, and performance

+`status: pending`. Every mesh family requires grid, local-refinement, timestep,
and approximation-order studies; fault/interface conservation and nonlinear
robustness tests; and degrees of freedom, memory, iteration, timestep-cut, and
wall-time reporting. Comparisons must separate physical mapping error from
solver and discretization error.

## Plots and source-data provenance

`source_data_status: missing`.

Required plots are mesh/fault/well layouts, pressure/saturation snapshots for
every mesh, field/well histories, local/global conservation, mechanics,
grid/time/order convergence, cumulative-production errors, and participant
envelopes.

+No plot or source artifact exists. Each future figure must name its mapping
manifest, field/CSV source, and participant-data checksum.

## Official reference comparison

`official_horizon_status: pending`.

The selected participant dataset, reference grid, mesh correspondence,
report-time interpolation, conversions, and envelope-distance rule remain to
be fixed. No comparison is claimed.

## Remaining blockers

Pin the source and participant data; define the FE mapping and mesh sequence;
build the decks; set gates; run conservation/convergence; and complete the
published comparison.
