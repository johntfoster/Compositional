# SPE benchmark report standard

Every problem family in `validation/spe_benchmark_inventory.yml` must have a
corresponding report before that benchmark may be called verified. A green
test alone is insufficient. Each report must use the exact version-2 headings
recorded in `report_inventory.yml` and contain:

1. provenance and the exact reference deck/data revision;
2. active and deliberately inactive manuscript physics;
3. input-deck composition, mesh, variables, CG/EG bases, closures, controls,
   solver, timestep, and units;
4. exact reproducibility commands and durable raw artifacts;
5. quantitative conservation, admissibility, thermodynamic, and control gates
   with values and tolerances;
6. spatial/time/order convergence, robustness, and performance evidence;
7. plots of the primary solution and all important verification diagnostics,
   with source-data provenance;
8. like-for-like comparison plots and error metrics against the pinned
   reference solution over the required benchmark horizon; and
9. an explicit verdict and list of anything still preventing acceptance.

Use `report_template.md.template`. `report_inventory.yml` is the authoritative
completion checklist. A report remains `in_progress` if it lacks a required
spatial/time/order study or if its comparison covers only an initialization
slice rather than the official reporting horizon.

`validation/scripts/validate_validation_yaml.py` requires one report per
inventory entry and enforces the section contract for pending, deferred, and
verified reports. The inventory records whether a report has run evidence,
candidate-only evidence, no evidence, or deferred scope. Only `run_evidence`
reports may link generated local plots, and every such link must resolve. SPE6
remains indexed with a deferred verdict while fracture physics is outside the
current scope.

The validator also requires `deck_status`, `command_status`,
`official_horizon_status`, and `source_data_status` markers whose values are
determined by the inventory evidence state. These markers describe evidence
availability; they do not substitute for the section's benchmark-specific
provenance and results.
