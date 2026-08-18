# SPE3 retrograde-condensate gas-cycling verification report

## Verdict

Status: **pending implementation** for both `SPE3CASE1.DATA` and
`SPE3CASE2.DATA`. No SPE3 deck, compositional property package, run artifact,
or reference comparison has been produced in this repository.

## Provenance

- Official problem: *Third SPE Comparative Solution Project: Gas Cycling of
  Retrograde Condensate Reservoirs*, D. E. Kenyon and G. A. Behie,
  SPE-12278-PA (1987).
- Case scope: OPM `spe3/SPE3CASE1.DATA` and `spe3/SPE3CASE2.DATA`; each case
  requires its own deck fingerprint, artifact bundle, metrics, and verdict.
- Pinned source repository: `opm-data` commit
  `eaa2261683a97027e057c2bc49612ad1c86390b3`, as recorded in
  `validation/reference_data/opm_spe_manifest.yml`. Per-deck SHA-256 values have
  not yet been recorded.
- Published-reference links are indexed under `spe3` in
  `validation/spe_benchmark_inventory.yml`.

## Active and inactive physics

Planned active physics are multicomponent compositional storage and transport,
the official EOS or K-value flash, retrograde dropout and revaporization, phase
appearance/disappearance, gas cycling, sales-gas handling, and well controls.
The production-theory path also requires chemical potentials, reconstructed
`tau`, directional phase availability, finite-rate transfer, dissipation,
conversion energy, reference-solid mechanics, solid mass, and phase volume.

Electrical forcing, surface-energy gradients, fracture/dual porosity, and
chemical reactions unrelated to phase transfer are deliberately inactive.
Thermal terms may be inactive only if each official case is confirmed
isothermal and that source is recorded.

## Deck provenance and CG/EG spaces

`deck_status: missing`.

- Parent decks and include fragments: missing for both cases.
- Geometry, properties, initialization, cycling schedule, sales-gas handling,
  completions, and controls must be imported separately from each pinned case.
- Planned production spaces: Q2 Lagrange displacement; P1 continuous pressure
  and `tau` backbones with P0 enrichments; P2 continuous phase-saturation
  backbones with P0 enrichments and admissibility control.
- Independent composition variables, flash unknowns, their polynomial orders,
  phase-appearance formulation, thermal variables, and stabilization remain
  unresolved acceptance blockers.
- Internal units will be SI, with explicit conversion to official surface and
  reservoir units.

## Reproduction commands and artifacts

`command_status: missing`. Each case requires its own source hash, assembled deck
and include manifest, command, environment/executable fingerprints, solver log,
CSV and fields, gate summary, flash/EOS diagnostics, reference data, and plots.

## Quantitative gates

No metric has been measured. Internal gates must cover every component and
solid balance, phase volume, admissibility, flash residual, `tau` evolution and
offsets, chemical-potential/affinity identities, kinetic residual, dissipation,
energy if active, mechanics/Jacobian, controls, and convergence. Numerical
tolerances must be fixed before acceptance runs.

For each case, results must lie inside the selected participant envelope and
remain within 5% relative error of a named authoritative time series. Case 1
and Case 2 metrics must be reported separately.

## Convergence, robustness, and performance

+`status: pending`. Each case requires independent spatial, timestep, and
composition/phase-state approximation studies, phase-appearance timestep-cut
tests, nonlinear robustness over cycling switches, and wall-time/iteration
reporting on declared hardware. Case 1 and Case 2 may not share convergence
evidence unless their discrete models and schedules are identical.

## Plots and source-data provenance

`source_data_status: missing`.

Each case requires pressure, condensate saturation, composition and phase-state
snapshots; component/phase rates and recovery; flash, kinetic, dissipation,
balance, energy, mechanics, and control histories; convergence; and reference
overlays.

+No plot or plot-source artifact exists. Each future figure must identify its
case-specific field/CSV input and artifact provenance manifest.

## Official reference comparison

`official_horizon_status: pending`.

The authoritative series, report times, interpolation, unit conversions,
envelope distance, and zero-reference error policy remain to be selected. No
comparison exists.

## Remaining blockers

Record per-deck hashes; implement the compositional/flash package; assemble both
CG/EG decks; define gates and reference processing; complete convergence; and
publish separate Case 1 and Case 2 comparisons.
