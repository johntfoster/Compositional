# SPE10 Model 2 million-cell waterflood verification report

## Verdict

Status: **pending implementation** for SPE10 Model 2 only. No imported
million-cell FE mesh, CG/EG deck, scalable run, artifact, or comparison exists.
Model 1 is covered separately in `validation/reports/spe10_model1.md`.

## Provenance

- Official scope: the 60 x 220 x 85, 1,122,000-cell three-dimensional
  geostatistical waterflood from the Tenth SPE Comparative Solution Project.
- Paper: M. A. Christie and M. J. Blunt, SPE-66599-MS (2001).
- Sources: the official Model 2 page and OPM
  `spe10model2/SPE10_MODEL2.DATA` at `opm-data` commit
  `eaa2261683a97027e057c2bc49612ad1c86390b3`, indexed under
  `spe10_model2` in `validation/spe_benchmark_inventory.yml`.
- Deck/property/reference checksums, extraction/conversion, and run-specific
  fingerprints are not yet recorded.

## Active and inactive physics

Planned active physics are official dead-oil/water storage and Darcy transport,
the full heterogeneous porosity/permeability model, relative permeability/PVT,
central water injection, four producers, breakthrough, controls, and field/well
reporting. Production-theory acceptance also requires reference-solid
mechanics, solid mass, and phase-volume closure.

Gas/solution-gas, thermal, miscible, reactive, electrical, surface-energy, and
fracture/dual-porosity physics are deliberately inactive. Upscaling is inactive
for the fine-grid result and becomes a separately labeled study if introduced.

## Deck provenance and CG/EG spaces

`deck_status: missing`.

- Fine-grid parent deck, import pipeline, and fragments: missing.
- The official grid/properties, inactive-cell policy, initial state, central
  injector, four producers, schedule, controls, and report times must be
  preserved.
- Planned spaces: Q2 Lagrange displacement; P1 continuous oil pressure plus P0
  enrichment; P2 continuous water saturation plus P0 enrichment with
  admissibility stabilization.
- The 1,122,000-cell-to-FE mapping, partitioning, parallel I/O, EG operators,
  bounds, scaling, timestep strategy, solvers, and any upscaling remain open.
- SI is required internally with auditable official-unit conversions.

## Reproduction commands and artifacts

`command_status: missing`. Required artifacts include source/property hashes, mesh and
partition manifests, exact deck/includes, MPI command and environment hashes,
solver/performance logs, CSV/fields, gate summary, reference data, and plots.

## Quantitative gates

No values are measured. Gates must include component/solid balances, phase
volume, water-saturation admissibility, mechanics/Jacobian, controls,
partition-independent results, nonlinear completion, scalability, and
grid/time/order convergence. Internal tolerances remain unset.

External targets are at most 2% relative error in field pressure and cumulative
volumes and 5% in instantaneous rates. Water-breakthrough error must be reported
with a definition and limit fixed before execution.

## Convergence, robustness, and performance

+`status: pending`. Required studies cover selected grid/FE mappings, timestep
and saturation order, partition independence, nonlinear robustness around
breakthrough and control switches, and strong/weak scaling. Degrees of freedom,
memory, communication layout, iterations, cuts, and wall time must be recorded.

## Plots and source-data provenance

`source_data_status: missing`.

Required plots are property/partition views, pressure and water saturation,
field/well rates and BHP, breakthrough, cumulative volumes, balances,
mechanics, convergence, strong/weak scaling, and official/OPM errors.

+No plot or source artifact exists. Future large-model figures must name the
partition/mesh manifest, CSV/field source, and official/OPM reference checksum.

## Official reference comparison

`official_horizon_status: pending`.

The official reporting tables or OPM summary, output version/checksum, report
times, interpolation, conversions, inactive-cell mapping, and error denominator
remain to be pinned. No comparison exists.

## Remaining blockers

Pin all data hashes; implement the large-model import and partition policy;
assemble the deck; define gates and performance protocol; run convergence and
scaling; and complete the official-horizon comparison.
