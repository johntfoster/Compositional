# SPE acceptance attempt records

This directory holds provenance-captured acceptance run artifacts.  The
authoritative status and coordination point for SPE1 Case 1 acceptance is
`agent_workflows/runbooks/spe1_acceptance_status.md` — read it before
interpreting any directory here.

Layout:

- `spe1_case1/one_day_coupled_acceptance_20260820/` — the sole current SPE1
  runtime evidence: a provenance-locked, four-rank SuperLU one-day coupled
  acceptance run with `status: pass`.
- `spe2/` — separate SPE2 work; not SPE1 evidence.

The SPE1 acceptance directory contains `command.txt`, `provenance.json`,
`result.csv`, `solver.log`, and `verification_summary.json`.  Preacceptance
diagnostic outputs are deliberately excluded from this runtime tree; their
historical status is recorded in `validation/reports/spe1_case1_evidence.yml`.
