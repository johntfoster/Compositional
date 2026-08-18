# SPE6 dual-porosity fractured-reservoir report

## Verdict

Status: **deferred by user**. SPE6 is intrinsically a fracture/matrix-transfer
benchmark and lies outside the active implementation pass. No deck, command,
run, comparison, or acceptance result is claimed; deferral is not a failure.

## Active and inactive physics

No SPE6 physics is active in a repository benchmark run. Resumed scope would
require separate matrix and fracture storage, multiphase capillary/gravity
exchange, depletion and injection schedules, fracture/matrix component
balances, phase-volume constraints, and coupled finite-deformation mechanics.
Electrical, thermal, chemical-reaction, and unrelated phase-transfer terms
would remain inactive unless the pinned official cases require them.

## Deck provenance and CG/EG spaces

`deck_status: deferred`.

The official paper links are indexed under `spe6` in
`validation/spe_benchmark_inventory.yml`; no local data revision, checksum,
extractor, SI conversion, deck, fragment, or manifest is pinned. A resumed
production path must define dual-continuum variables while retaining Q2 solid
displacement, P1+P0 EG pressure and `tau` where applicable, and admissible
higher-order CG/EG phase fields in each continuum.

## Reproduction commands and artifacts

`command_status: deferred`. No executable command or run artifact exists.
Resumed work requires exact source and deck hashes, an assembled-deck manifest,
commands, environment fingerprints, solver logs, CSV/field output, a gate
summary, reference data, and a plotting command.

## Quantitative gates

`status: deferred`. No value has been measured. Resumed gates must cover each
matrix/fracture component and solid balance, exchange antisymmetry, phase
volume, admissibility, mechanics/Jacobian, wells and controls, nonlinear
completion, and official-case horizon completion. Numerical tolerances must be
fixed before a run.

## Convergence, robustness, and performance

`status: deferred`. The eventual protocol must include matrix and fracture
mesh refinement, timestep and approximation order, exchange-shape sensitivity,
robustness at depletion/injection switches, and degrees of freedom, memory,
iterations, timestep cuts, and wall time on stated hardware.

## Official reference comparison

`official_horizon_status: deferred`.

No reference series has been digitized or selected. Resumed work must pin the
official cases, report times, unit conversions, interpolation, matrix/fracture
quantity mapping, error norms, participant envelope, and complete official
horizons before comparison.

## Plots and source-data provenance

`source_data_status: deferred`.

No plot or source artifact exists. Resumed figures must cover matrix/fracture
pressures and saturations, exchange, well histories, balances, convergence, and
official overlays, with every field/CSV and reference-data checksum recorded.

## Remaining blockers

User authorization to resume fracture and dual-porosity scope is the first
blocker. Source pinning, dual-continuum theory-to-code mapping, implementation,
deck assembly, quantitative gates, convergence, and official comparisons then
remain required.
