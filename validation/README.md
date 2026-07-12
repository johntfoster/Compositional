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
