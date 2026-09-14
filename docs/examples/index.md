# Examples

| Example | Physical model | Evidence | Status |
|---|---|---|---|
| [SPE1 Case 1](spe1-case1.md) | Four-phase finite-deformation black-oil flow with phase transfer | Provenance-locked one-day run | One-day coupled acceptance passed; official long-horizon comparison pending |

## Example contract

Each future example should provide the following sections.

1. Physical problem, assumptions, and declared inactive physics.
2. Governing equations and constitutive specialization.
3. Theory-to-MOOSE map: variables, residual objects, materials, BCs, and checks.
4. Deck assembly map, exact command, and agent-ready reproduction prompts.
5. Quantitative gates, figures, source-data provenance, and the precise scope
   of comparison to an external reference.

The detailed validation-report contract is maintained in
`validation/reports/report_inventory.yml`.
