# Validation Matrix

This directory will hold the implementation-and-verification validation matrix,
reference data, and postprocessing scripts.

Each validation entry should record:

- target physical regime
- governing manuscript reduction
- reference-solid-skeleton weak form or finite-volume balance
- MOOSE objects required
- input deck location
- reference result or manufactured solution
- expected outputs
- current status

Generated run outputs should stay outside this directory unless they become
curated reference data.

The durable matrix lives in `validation_matrix.yml`. Add or update an entry
whenever a new validation case, benchmark, expected observable, reference-data
source, or pass/fail criterion becomes part of the implementation plan.

The acceptance inventories live in:

- `mms_inventory.yml` for manufactured-solution coverage by physics block,
  dimension, formula, norm, tolerance, observed error, and current gap.
- `spe_benchmark_inventory.yml` for in-scope SPE Comparative Solution Project
  families, public provenance, required physics, reference observables,
  tolerance policy, and implementation status.
- `code_only_acceptance_audit.yml` for the live requirement-by-requirement
  completion audit.

Validate these YAML files with:

```bash
python3 validation/scripts/validate_validation_yaml.py
```

Extract and verify the pinned SPE1 black-oil tables from an OPM/ECLIPSE deck
with:

```bash
python3 validation/scripts/extract_eclipse_black_oil.py \
  /path/to/opm-data/spe1/SPE1CASE1.DATA --validate-spe1-case1
```

The extractor emits source-hash, PVTW, PVDG, ragged PVTO, DENSITY, SWOF, SGOF,
Cartesian grid/property arrays, ROCK, EQUIL/RSVD, completion/well-control, and
TSTEP schedule data as JSON in both source FIELD units and explicit SI units.

Generate and verify the 300-cell SI hydrostatic EQUIL/RSVD state with:

```bash
python3 validation/scripts/generate_spe1_initial_state.py \
  /path/to/opm-data/spe1/SPE1CASE1.DATA --validate
```

Generation of executable schedule and multi-completion objects remains a
separate importer step.

Run the coupled SPE1 acceptance workflow with, for example:

```bash
python3 validation/scripts/run_spe1_phase_transforming_acceptance.py \
  validation/results/spe1_case1/current --official-schedule
```

The runner automatically performs a closed-boundary, source-free stage-0
equilibration with the production Q2/EG variables and full mixture gravity. It
checks reference-component and solid-mass conservation, all local/global
physics gates, the complete accepted-step history, and deviations from the
official layer-centered EQUIL/RSVD/SWOF map before restarting the official
schedule at reported time zero. The official run receives fresh cumulative
well quantities and is rejected automatically if its complete time-history
audit fails.
