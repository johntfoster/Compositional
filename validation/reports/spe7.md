# SPE7 horizontal-well verification report

## Verdict

Status: **pending implementation**. No SPE7 deck, horizontal-well model,
artifact bundle, or comparison exists.

## Provenance

- Official problem: *Seventh SPE Comparative Solution Project: Modelling of
  Horizontal Wells in Reservoir Simulation*, L. Nghiem, D. A. Collins, and
  R. Sharma, SPE-21221-MS (1991).
- Public specifications: the links under `spe7` in
  `validation/spe_benchmark_inventory.yml`.
- Source revision/checksum, digitized reference data, extractor, SI conversion,
  and run-specific manuscript/MOOSE/executable fingerprints are not yet pinned.

## Active and inactive physics

Planned active physics are the official two- or three-phase reservoir model,
horizontal trajectory and completion coupling, well index or resolved inflow,
along-well pressure drop, coning/breakthrough, and rate/BHP controls. The
production path also requires reference-solid mechanics, solid mass, phase
volume, and conservative component transport.

Electrical forcing, surface-energy gradients, fracture/dual porosity,
miscibility, thermal energy, and reaction/finite-rate phase transfer are
deliberately inactive unless the pinned official case requires one of them.

## Deck provenance and CG/EG spaces

`deck_status: missing`.

- Parent deck and include fragments: missing.
- Geometry, trajectory/segments, completions, properties, initial state,
  schedule, controls, and report times remain to be transcribed.
- Planned spaces: Q2 Lagrange displacement; P1 continuous oil/equivalent
  pressure plus P0 enrichment; P2 continuous saturation backbones plus P0
  enrichments; continuous parent solution-gas closure when applicable.
- Well-segment unknowns and order, reservoir-to-well coupling, facet/boundary
  operators, bounds, scaling, timestep policy, and solvers remain unresolved.
- Internal SI and explicit official-unit conversions are required.

## Reproduction commands and artifacts

`command_status: missing`. Required artifacts include the pinned source/hash, deck and
include manifest, well-trajectory representation, command, environment hashes,
solver log, CSV/fields, gate summary, reference data, and plotting command.

## Quantitative gates

No values are measured. Gates must cover component/solid balances, phase
volume, saturation admissibility, mechanics/Jacobian, well mass conservation,
rate/BHP switching, segment-pressure solution, nonlinear completion, and
mesh/time/order/well-segmentation convergence. Internal limits are unset.

External targets are at most 2% relative error in well pressures and 5% in
cumulative phase production; segment-pressure discrepancies must be reported
separately.

## Convergence, robustness, and performance

+`status: pending`. Required studies cover reservoir mesh and timestep,
horizontal-well segment length/order, completion quadrature, nonlinear
robustness at rate/BHP and breakthrough events, and memory/wall-time/iteration
cost. Segment refinement must preserve the physical trajectory and inflow
definition.

## Plots and source-data provenance

`source_data_status: missing`.

Required plots are reservoir pressure/saturation, horizontal-well and segment
pressure, phase rates, coning/breakthrough, recovery, balances, controls,
mechanics, all convergence studies, and published-reference overlays.

+No plot or plot-source artifact exists. Future figures must name the reservoir
and well-segment outputs plus the digitized-reference provenance record.

## Official reference comparison

`official_horizon_status: pending`.

Report times, digitization, segment mapping, interpolation, unit conversions,
and relative-error rules remain to be defined. No comparison exists.

## Remaining blockers

Pin reference data; implement the well model; assemble the CG/EG deck; define
gates and segment mapping; complete convergence; and compare the official
horizon.
