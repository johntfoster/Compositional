# SPE11 CO2-storage verification report

## Verdict

Status: **pending implementation** for all three official subcases: SPE11A,
SPE11B, and SPE11C. No CO2-brine property package, executable deck, artifact,
official-checker result, or reference-envelope comparison exists.

## Provenance

- Official problem: SPE11 CO2 storage benchmark, J. M. Nordbotten,
  M. A. Ferno, B. Flemisch, A. R. Kovscek, and K.-A. Lie,
  SPE-218015-PA (2024).
- Data DOI: `10.18419/DARUS-4750`; problem and analysis repository:
  `Simulation-Benchmarks/11thSPE-CSP`, as indexed under `spe11` in
  `validation/spe_benchmark_inventory.yml`.
- Subcase scope: SPE11A, controlled laboratory-scale 2D; SPE11B, vertical 2D
  field-scale transect; SPE11C, full 3D field-scale model. Each requires a
  separate deck, artifacts, official metrics, and verdict.
- Dataset/repository commit and checksums, extraction/SI conversion, official
  checker version, and run-specific fingerprints remain to be pinned.

## Active and inactive physics

Planned active physics are CO2-H2O partitioning, pure-phase and mixture
properties, multiphase component transport, capillary pressure, relative
permeability, dissolution and convection, heterogeneity, injection controls,
and thermal effects where enabled by the official subcase. The general
production path also requires chemical potentials, reconstructed `tau`,
finite-rate transfer, dissipation, conversion energy, reference-solid
mechanics, solid conservation, and phase-volume closure.

Electrical forcing, Maxwell stress, surface-energy gradients, fracture/dual
porosity, and chemical reactions beyond CO2-H2O phase partition/dissolution are
deliberately inactive unless a pinned subcase explicitly requires them. Thermal
terms must be classified separately for A, B, and C rather than globally.

## Deck provenance and CG/EG spaces

`deck_status: missing`.

- Parent decks and include fragments: missing for SPE11A, SPE11B, and SPE11C.
- Each official geometry, heterogeneous fields, initial/boundary conditions,
  injection schedule, controls, and sparse/dense reporting definitions must be
  imported independently.
- Planned production spaces: Q2 Lagrange displacement; P1 continuous pressure
  and `tau` plus P0 enrichments; P2 continuous phase saturation plus P0
  enrichment with admissibility stabilization.
- CO2/H2O composition and property variables, flash unknowns/orders,
  temperature spaces, dissolution treatment, capillary discretization, bounds,
  scaling, timestep strategy, and solvers remain unresolved.
- Internal SI must be reconciled explicitly with official sparse/dense formats.

## Reproduction commands and artifacts

`command_status: missing`. Each subcase requires dataset/analysis hashes, generated
deck and include manifest, command, environment hashes, solver log, sparse and
dense outputs, fields, gate summary, official-checker output, reference data,
and plotting command.

## Quantitative gates

No metric is measured. Gates must cover CO2 and H2O plus solid conservation,
phase volume, composition/saturation admissibility, property/flash residuals,
`tau`/chemical-potential kinetics, dissipation, energy where active,
mechanics/Jacobian, leakage and boundary-flux accounting, controls, solver
completion, and spatial/time/order convergence.

For A, B, and C separately, all required sparse quantities must pass the pinned
official checker and official global-distance metrics must lie within the
accepted participant reference envelope. No substitute numerical threshold is
invented here.

## Convergence, robustness, and performance

+`status: pending`. SPE11A, B, and C each require spatial, timestep, and
composition/phase-state order studies, plume/inventory metric convergence,
robustness around phase appearance and injection events, and performance data.
SPE11C additionally requires partition independence and strong/weak scaling.

## Plots and source-data provenance

`source_data_status: missing`.

Each subcase requires geometry/property views, pressure, saturation,
composition and temperature fields, plume location, dissolved/trapped/free CO2
masses, inventories, energy/dissipation, leakage/boundary fluxes, controls,
mechanics, convergence, sparse-data comparisons, and official distance metrics.

+No plot or source artifact exists. Future figures must name the SPE11 subcase,
sparse/dense source artifact, official-analysis revision, and gate summary.

## Official reference comparison

`official_horizon_status: pending`.

The analysis commit, official input/output schema, sparse/dense report times,
interpolation, unit conversions, mass classification, distance metric, and
accepted envelope remain to be pinned and recorded per subcase. No comparison
exists.

## Remaining blockers

Pin dataset and analysis revisions; implement and validate the CO2-brine
property/flash package; build A, B, and C decks; define internal gates; produce
official sparse/dense output; run convergence; and pass/report the official
analysis separately for every subcase.
