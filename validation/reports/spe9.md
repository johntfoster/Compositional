# SPE9 heterogeneous black-oil verification report

## Verdict

Status: **pending implementation**. The OPM source deck is indexed, but no SPE9
CG/EG deck, run artifact, or comparison exists.

## Provenance

- Official problem: *Ninth SPE Comparative Solution Project: A Reexamination
  of Black-Oil Simulation*, J. E. Killough, SPE-29110-MS (1995).
- Source deck: OPM `spe9/SPE9.DATA` at pinned `opm-data` commit
  `eaa2261683a97027e057c2bc49612ad1c86390b3`.
- Recorded hashes: deck
  `358bbc47699a857c939eab48700018e3deeeb8478c5c0bc85c1eb5842e361f45`,
  grid `20a5840737d9f8e67f4c0bb21a5aa53f1f956750339e171d81c624ab81415e31`,
  and permeability include
  `355dfe63d2ee7bd8f420701319a1dc55ff4a9c472700687dfb0551fa3b77e381`,
  from `validation/reference_data/opm_spe_manifest.yml`.
- Extraction/SI conversion, reference-summary checksum, and run fingerprints
  remain missing.

## Active and inactive physics

Planned active physics are 9000-cell heterogeneous three-phase black-oil
storage/transport, official PVT, capillary and relative-permeability tables,
water injection, multiple producers, controls, and field/well reporting.
Reference-solid mechanics, solid conservation, and phase volume are required
for the production solve.

Electrical, thermal, miscible, reactive, surface-energy, and fracture physics
are deliberately inactive. Solution-gas and phase-appearance terms required by
the official deck remain active.

## Deck provenance and CG/EG spaces

`deck_status: missing`.

- Parent CG/EG deck and include fragments: missing.
- The official 9000-cell grid, properties, initial state, wells, schedule, and
  reporting requests must be converted without silent upscaling.
- Planned spaces: Q2 Lagrange displacement; P1 continuous oil pressure plus P0
  enrichment; P2 continuous water/gas saturation plus P0 enrichments; parent
  continuous solution-gas closure; admissibility and entropy viscosity.
- Grid-to-TET10 mapping, EG operators, capillary reconstruction, bounds,
  scaling, timestep strategy, and solvers remain to be specified.
- SI is required internally with auditable FIELD-unit reporting conversions.

## Reproduction commands and artifacts

`command_status: missing`. Required artifacts are source/hash validation, mesh mapping,
assembled deck/includes, command, environment hashes, solver log, CSV/fields,
gate summary, reference summary, and plots.

## Quantitative gates

No observations exist. Gates must cover component/solid mass, phase volume,
saturation admissibility, capillary/PVT table coordinates, mechanics/Jacobian,
well controls, nonlinear completion, and mesh/time/order convergence. Internal
limits remain unset.

External targets are at most 2% relative error in field pressure and cumulative
volumes and 5% in instantaneous phase rates at official report times.

## Convergence, robustness, and performance

+`status: pending`. Required evidence includes grid-mapping, spatial, timestep,
and saturation-order studies; robustness across well-control and phase-state
events; partition-independent checks; and degrees of freedom, memory,
iterations, timestep cuts, and wall time on stated hardware.

## Plots and source-data provenance

`source_data_status: missing`.

Required plots include pressure/saturation fields, field/well rates and BHP,
cumulative volumes, component balances, admissibility, mechanics, controls,
convergence, and OPM/published error histories.

+No plot or source artifact exists. Future plots must identify the exact MOOSE
CSV/field artifact, OPM summary checksum, and conversion manifest.

## Official reference comparison

`official_horizon_status: pending`.

The OPM reference version/output, summary extractor, report-time interpolation,
unit conversions, and error denominator remain to be pinned. No comparison has
been run.

## Remaining blockers

Implement source extraction and mesh mapping; build the CG/EG deck; generate a
pinned OPM summary; define gates; run convergence; and complete the full
official-horizon comparison.
