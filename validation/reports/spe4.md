# SPE4 steam-injection verification report

## Verdict

Status: **pending implementation**. No SPE4 thermal deck, calibrated property
package, run artifact, or quantitative comparison exists.

## Provenance

- Official problem: *Fourth SPE Comparative Solution Project: Comparison of
  Steam Injection Simulators*, K. Aziz, A. B. Ramesh, and P. T. Woo,
  SPE-13510-PA (1987).
- Public specifications: the links under `spe4` in
  `validation/spe_benchmark_inventory.yml`.
- Source revision/checksum, local reference data, extractor, and SI conversion
  record are not yet pinned. Run-specific manuscript, MOOSE, patch, and
  executable fingerprints also remain required.

## Active and inactive physics

Planned active physics are steam/water/oil storage and Darcy transport,
advective and conductive energy transport, temperature-dependent properties,
steam quality, latent/conversion energy, thermal well sources, and controls.
Separate fluid/solid temperature balances, reference-solid mechanics, solid
conservation, and phase-volume closure are required in the production solve.

Electrical forcing, surface-energy gradients, fracture/dual porosity,
miscibility, and reactions beyond water/steam phase transformation are
deliberately inactive. Capillarity, gravity, and heat loss may be classified
only after the specification is pinned.

## Deck provenance and CG/EG spaces

`deck_status: missing`.

- Parent deck and fragments: missing.
- Official geometry, property tables, initial thermal state, completions,
  injection enthalpy/quality, schedule, boundaries, and report times remain to
  be transcribed.
- Planned production spaces: Q2 Lagrange displacement; P1 continuous pressure
  and `tau` backbones with P0 enrichments; P2 continuous phase-saturation
  backbones with P0 enrichments and admissibility stabilization.
- Exact steam-quality/composition and temperature spaces, energy upwinding,
  bounds, scaling, timestep strategy, and solvers remain unresolved.
- SI will be used internally with explicit thermal, rate, pressure, and
  cumulative-unit conversions.

## Reproduction commands and artifacts

`command_status: missing`. Required artifacts are the pinned source and hashes,
assembled deck/include manifest, command, environment fingerprints, solver log,
CSV and fields, gate summary, energy/well accounting, reference data, and plots.

## Quantitative gates

All values are **not measured**. Gates must cover component/solid mass and total
energy, phase volume, saturation/steam-quality admissibility, transfer kinetics
and dissipation, temperature bounds, mechanics/Jacobian, thermal well controls,
solver completion, and convergence. Internal tolerances remain to be defined.

External targets are at most 5% relative error in energy and cumulative phase
quantities and temperature-front agreement within one matched grid cell or the
published comparison tolerance, as selected from the pinned source.

## Convergence, robustness, and performance

+`status: pending`. Required studies cover spatial and timestep convergence of
temperature and steam fronts, temperature/enthalpy approximation order,
nonlinear robustness at phase and well-control transitions, energy-conservative
timestep cuts, and wall time plus nonlinear/linear iterations on stated
hardware.

## Plots and source-data provenance

`source_data_status: missing`.

Required plots include temperature and steam fronts, steam quality and
saturations, pressure, heat and phase rates, cumulative heat/recovery, mass and
energy balances, dissipation, mechanics, controls, convergence, and official
overlays.

+No plot or source CSV/field artifact exists. Future figures must name the
thermal run artifact and reference-data revision.

## Official reference comparison

`official_horizon_status: pending`.

Report times, front extraction, grid matching, interpolation, conversions,
energy normalization, and the applicable published tolerance remain undefined.
No like-for-like comparison exists.

## Remaining blockers

Pin the problem data; implement and calibrate thermal properties and energy;
assemble the CG/EG deck; define gates and reference processing; run convergence;
and complete the official-horizon comparison.
