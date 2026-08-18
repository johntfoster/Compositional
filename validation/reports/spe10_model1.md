# SPE10 Model 1 gas-injection/upscaling verification report

## Verdict

Status: **pending implementation** for SPE10 Model 1 only. No fine-grid or
upscaled CG/EG deck, artifact, or quantitative comparison exists. Model 2 is
covered separately in `validation/reports/spe10_model2.md`.

## Provenance

- Official scope: the small two-dimensional vertical gas-injection/upscaling
  problem from the Tenth SPE Comparative Solution Project.
- Paper: M. A. Christie and M. J. Blunt, SPE-66599-MS (2001).
- Source deck: OPM `spe10model1/SPE10_MODEL1.DATA` at `opm-data` commit
  `eaa2261683a97027e057c2bc49612ad1c86390b3`; official homepage and paper links
  are indexed under `spe10_model1` in `validation/spe_benchmark_inventory.yml`.
- Deck/reference checksums, extraction and SI conversion, and run-specific
  manuscript/MOOSE/executable fingerprints remain unrecorded.

## Active and inactive physics

Planned active physics are the official two-dimensional oil/gas storage and
Darcy transport, relative permeability and PVT, gas injector and producer
controls, heterogeneity, and fine-to-upscaled comparisons. Production-theory
acceptance also requires reference-solid mechanics, solid mass, and phase
volume on both selected meshes.

Water transport, thermal energy, miscibility, reaction/finite-rate transfer,
electrical and surface-energy terms, and fracture/dual porosity are deliberately
inactive unless the pinned deck explicitly activates them.

## Deck provenance and CG/EG spaces

`deck_status: missing`.

- Fine and upscaled parent decks/includes: missing.
- Official cross-section, properties, initial state, wells, schedule, and
  report times must be imported; every upscaling rule must be explicit.
- Planned spaces on each mesh: Q2 Lagrange displacement; P1 continuous oil or
  equivalent pressure plus P0 enrichment; P2 continuous gas saturation plus P0
  enrichment with admissibility stabilization.
- FE mapping, upscaled mesh/property operators, EG facet/boundary terms, bounds,
  scaling, timestep strategy, and solvers remain unresolved.
- SI is required internally with explicit official-unit conversions.

## Reproduction commands and artifacts

`command_status: missing`. Fine and each upscaled run require separate mesh/property
manifests, decks/includes, commands, environment hashes, logs, CSV/fields, gate
summaries, performance records, reference data, and plot commands.

## Quantitative gates

No values are measured. Gates must include component/solid balances, phase
volume, gas-saturation admissibility, mechanics/Jacobian, well controls, solver
completion, and spatial/time/order convergence on each mesh. Upscaling error
norms must be defined before running.

External acceptance requires at most 5% relative error in cumulative production
against the official fine-grid or named published reference, with pressure and
saturation snapshot norms reported per grid.

## Convergence, robustness, and performance

+`status: pending`. Fine and upscaled models require spatial, timestep, and
saturation-order studies, sensitivity to each upscaling operator, robustness at
well and gas-front events, and degrees of freedom, memory, iterations, timestep
cuts, and wall time. Fine-to-upscaled comparisons must use one reporting map.

## Plots and source-data provenance

`source_data_status: missing`.

Required plots are fine/upscaled mesh and property views, pressure and gas
saturation, rates and cumulative production, balances, controls, mechanics,
convergence, fine/upscaled norms, and official-reference overlays.

+No plot or source artifact exists. Future fine/upscaled figures must name the
mesh/property manifest, CSV/field source, and reference revision.

## Official reference comparison

`official_horizon_status: pending`.

The authoritative fine-grid series, report times, interpolation, unit
conversions, snapshot norm, and upscaled-to-fine mapping remain undefined. No
comparison exists.

## Remaining blockers

Pin hashes and reference data; construct fine and selected upscaled decks;
define upscaling and norms; run all gates/convergence; and complete the official
horizon comparison.
