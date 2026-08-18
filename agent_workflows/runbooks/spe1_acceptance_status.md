# SPE1 Case 1 acceptance — status and attempt record

Authoritative, durable status for SPE1 Case 1 acceptance under the
rate-independent `DRSDT = 0` equilibrium phase-appearance closure for the
finite-deformation, solid-reference CG/EG mixture theory.

This runbook is the coordination point for every SPE1 acceptance attempt.
It records what has been tried, where the attempt records and source live,
the current state, and what remains.  Check it before starting any SPE1
run, before interpreting an old result, and when answering "where do we
stand on SPE1?".

## Current state

**The reduced `DRSDT` acceptance does NOT pass under the current uncommitted
deck and binary.**  The inner Newton solve stalls at a residual floor near
`4.481544e-07` and grinds all 60 nonlinear iterations to `DIVERGED_MAX_IT`
at the first time step.  Relaxing the nonlinear absolute tolerance to
`1e-6` makes the inner solve converge but then violates the
`gas_global_balance` gate (`+1325` kg/s).  No reduced acceptance run has
passed since the 2026-08-17 deck rework.

**The two legacy temporary "PASS" artifact sets are stale.** They ran on the
pre-rewrite transient deck (`gas_phase_transformation_rate = MONOMIAL
SECOND`) and do not cover the current reworked deck (LAGRANGE FIRST rate
field, simplex-bounded saturation reconstruction, identity-transform
closure saturation, `phase_active_band = 1e-10`, dissolved-gas component
flux, frozen active-set lagged Picard DRSDT closure).  They must not be
used as evidence for the current deck.

| Run | Date | Deck sha | Exe sha | Input tree | Verifier | Result |
|---|---|---|---|---|---|---|
| Reduced acceptance (base) | 2026-08-18 11:42 | `cc28dabf…` | `44c7f7…` | `c469402c…` | `dc243854…` | interrupted ("running", 110 DIVERGED lines) |
| Reduced acceptance `_fixed` | 2026-08-18 12:00 | `cc28dabf…` | `44c7f7…` | `c469402c…` | `3ad04102…` | FAIL — `gas_global_balance=1325`, `tau_evolution_residual_l2=2.38e-7`, spurious gas (max Sg 0.237, R_s 226.2) |
| Reduced acceptance `_fixed2` | 2026-08-18 12:23 | `cc28dabf…` | `44c7f7…` | `c469402c…` | `0947d9f8…` | FAIL — solver timeout, stall floor `4.481544e-07`, step 1 only |
| `drsdt_gate_artifacts` (legacy temporary artifact) | 2026-08-17 (pre-rewrite) | `cc28dabf…` | `44c7f7…` | `31c090…` | `fb3d86…` | PASS (stale; Sg ≈ 4.9e-11, gas never appeared) |
| `drsdt_gate_artifacts_v2` (legacy temporary artifact) | 2026-08-17 10:22 (pre-rewrite) | `cc28dabf…` | `44c7f7…` | `31c090…` | `dc243854…` | PASS (stale; with saturated override, no nl_abs_tol) |
| Authoritative verifier artifacts | 2026-08-13 01:25 | (old deck) | — | — | `25123376…` | FAIL — solver_timeout |

Full executable sha: `44c7f7bed89dc015…`; full deck sha:
`cc28dabfcf482695…`; current working verifier sha:
`0947d9f89f0a8494…`.

## What has been tried

Chronological summary of the acceptance work.  Deep detail is preserved in
the attempt-record directories and session checkpoints listed under
"Where the attempt records are".

1. **Complementarity zero-pivot fix (checkpoints 002–005).**  The gas
   complementarity branch selector was changed from a min-split to a
   physical active-set branch in
   `moose_app/src/materials/ADBlackOilBenchmarkPVTMaterial.C`.  This fixed
   the zero pivot and regenerated gold CSVs.  Still uncommitted.

2. **Saturated solution-gas override for wells (checkpoint 021).**  The
   injector well material partition now honors a saturated
   solution-gas-oil-ratio override via
   `saturated_solution_gas_oil_ratio_name`
   (`moose_app/src/materials/ADBlackOilPeacemanWellMaterial.C`).  This was
   exonerated as a failure cause for the gas-balance mismatch.

3. **`nl_abs_tol` experiment (checkpoint 022 → reverted in checkpoint
   023).**  Setting `Executioner/nl_abs_tol = 1e-6` made the inner solve
   converge but violated the gas global balance.  The override was removed
   from the verifier's `--drsdt-closure` block on 2026-08-18; the gate
   design relies on the deck-nominal strict tolerance `1e-8`.

4. **Deck rework (2026-08-17 11:32, uncommitted).**  The transient deck now
   uses a LAGRANGE FIRST gas phase-transformation-rate field, simplex-bounded
   water/gas saturation reconstruction with an identity-transform closure
   saturation, `phase_active_band = 1e-10`, `deactivate_on_nonpositive_mass`,
   dissolved-gas component flux, and a frozen active-set lagged Picard DRSDT
   closure.  This is the current state under test; it introduced the residual
   floor described above.

5. **Reduced DRSDT acceptance runs (2026-08-18).**  Three runs, all on the
   current deck; all fail as tabulated above.

## Where the attempt records are

All provenance-captured reduced DRSDT acceptance attempts (deck sha, exe
sha, input-tree sha, moose patch-series sha, resolved include closure,
verifier sha, exact command):

- `validation/results/spe1_q2_eg_reduced_drsdt_acceptance/` — interrupted
  run (status "running" in summary; 110 DIVERGED lines; no final row).
- `validation/results/spe1_q2_eg_reduced_drsdt_acceptance_fixed/` — FAIL,
  gas-balance/temperature/saturation signature.
- `validation/results/spe1_q2_eg_reduced_drsdt_acceptance_fixed2/` — FAIL,
  solver timeout, `4.481544e-07` floor.

Each directory contains `command.txt`, `provenance.json`, `result.csv`,
`solver.log`, and `verification_summary.json`.

Older diagnostic history (199 directories, ~2.9 GB, 2026-08-05 through
2026-08-17; replay, probe, bisect, continuation, checkpoint runs; do not
delete without review):

- `validation/results/spe1_case1/` — the pre-rework diagnostic archive.
- `validation/results/spe1_case1/drsdt_reduced_acceptance_20260817/` —
  FAIL record for the 2026-08-17 reduced run (deck `cc28dabf`, input tree
  `1948215f9e37`, `nl_max_its=60`, no `nl_abs_tol` override).
- `validation/results/spe2/` — separate SPE2 work; not SPE1 evidence.

Legacy temporary/stale artifacts were not retained in the repository:

- `drsdt_gate_artifacts/`, `drsdt_gate_artifacts_v2/` — the two
  **stale pre-deck-rewrite PASS references**.  Keep only as historical
  evidence of the MONOMIAL SECOND era; not valid for the current deck.
- `spe1_drsdt_verifier_authoritative_20260813/` — authoritative
  verifier artifacts from 2026-08-13 (also a solver timeout).
- `spe1_bisect/`, `spe1_fullmesh_curlib/`, `spe1_smalldt_curlib/`, and
  `spe1_one_day_rerun_20260807_174850/` — referenced by
  `validation/reports/spe1_case1.md` for pre-rework diagnostics.
- Five stale acceptance-lock markers
  (`multicomponent_reactive_flow_spe_acceptance.lock.stale-*`,
  `.stopped_invalid_dt675_20260810_210057`,
  `.unlocked_20260810_061200`).  No live lock exists; edits/builds are
  permitted.  The acceptance runner renames a stale marker to a recoverable
  file on its next start, so removal is safe.

## Where the source, templates, and inputs are

- Harness / verifier:
  `validation/scripts/check_spe1_q2_eg_phase_appearance.py` — reduced and
  full acceptance runner, gate limits (~lines 25–45), timeouts (~55–58),
  DRSDT gate `gas_appearance_equilibrium_residual_l2` (~318–342),
  active-wells overrides (~149–158), input-tree hashing (~202–220),
  provenance capture (~221–235), DRSDT command block (~431–470).
  Current command block (in order): `Kernels/inactive=gas_phase_transformation_closure`,
  `Executioner/line_search=bt`, `fixed_point_algorithm=picard`,
  `fixed_point_max_its=3`, `disable_fixed_point_residual_norm_check=true`,
  `custom_pp=gas_active_set_mismatch_integral`, `direct_pp_value=true`,
  `custom_abs_tol=1e-6`,
  `Materials/injector/saturated_solution_gas_oil_ratio_name=benchmark_black_oil_saturated_solution_gas_oil_ratio`,
  `Executioner/nl_max_its=60`, plus mesh/well/block overlays.  No
  `nl_abs_tol` override (strict deck-nominal `1e-8`).
- Decks (uncommitted): `moose_app/examples/spe1_case1_q2_eg_phase_transforming.i`
  (top-level; deck sha `cc28dabf…`), `moose_app/examples/spe1_case1_q2_eg_transient.i`
  (transient/solver state; LAGRANGE FIRST rate field ~69–90, DRSDT
  active-set params `[spe1_pvt]` ~363–392, `gas_global_balance` ~1754,
  storage/source postprocessors ~1712–1758).
- Include inputs (uncommitted): `moose_app/input/includes/materials/spe1_case1_black_oil_pvt.i`
  (`phase_active_band = 1e-10`), `solid_phase_mass_volume.i`,
  `moose_app/input/includes/mesh/spe1_case1_3d_q2_tet10.i`.
- Materials (uncommitted): `moose_app/src/materials/ADBlackOilBenchmarkPVTMaterial.C`
  (branch selector ~1120–1330, storage rate ~1350–1510, `phase_active_band`
  ~203–205, 385, 971–983), `ADBlackOilPeacemanWellMaterial.C`
  (`saturated_solution_gas_oil_ratio_name` partition ~435–470),
  `ADEGReconstructedScalarMaterial.C`.
- Harness test spec: `moose_app/test/tests/black_oil_benchmark_pvt/tests`
  — DRSDT group (`spe1_drsdt_zero_coupled_partition_{1d,eg_1d,eg_recovery_1d}`,
  Jacobian tests), `spe1_case1_q2_eg_phase_appearance` (`--mpi-ranks 8`,
  `max_time 900`), `_nonequilibrium_reduced`, `_nonequilibrium_active_wells`,
  and the FV diagnostic tests (`spe1_case1_transient_fv`, `monthly_fv`,
  `fifth_report_opm`) which have no production-acceptance role.
- Report standard: `validation/reports/README.md` and
  `validation/reports/report_inventory.yml` (v2 required headings;
  `validation/scripts/validate_validation_yaml.py` enforces the contract).
- Traceability (keep aligned when decisions become durable):
  `moose_app/doc/theory_traceability.yml`, `validation/validation_matrix.yml`,
  `implementation_paper/equation_to_moose_map.yml`.

## How to reproduce a reduced DRSDT acceptance run

```sh
agent_environment/skills/setup-moose-conda/scripts/moose_conda_env.sh run -- \
  python validation/scripts/check_spe1_q2_eg_phase_appearance.py \
  --reduced --active-wells --drsdt-closure \
  --artifacts-dir <fresh-or-empty-dir>
```

The checker refuses a non-empty artifacts directory.  Reduced timeout is
600 s; full timeout is 7200 s.  Reproduction must use the recorded
`command.txt` (one shell command, exact overrides) inside the recorded MOOSE
Conda environment.

## What is left to do

1. **Resolve the `4.481544e-07` residual floor (blocking).**  Decide among:
   (a) fix the floor in the current deck (prime suspects: LAGRANGE FIRST
   rate field, identity-transform closure-saturation coupling, or
   `phase_active_band = 1e-10`); (b) revert or stabilize the deck rework;
   or (c) re-examine the gate set with the author's approval. Do not weaken
   tolerances to force the gas balance to pass.
2. **Reduced acceptance passes** on the current deck+binary.
3. **Full 86,400 s acceptance** (`--mpi-ranks 8`) under the DRSDT closure.
4. **Harness suite** — `moose_app/test/tests/black_oil_benchmark_pvt`
   `run_tests` group passes (DRSDT partition, Jacobian, nonequilibrium
   reduced/active-wells, plus unchanged unrelated tests).
5. **Official numerical trajectory** — accepted steps through every saved
   OPM time over the ten-year schedule, then matched black-oil observables
   (field GOR, pressures/BHPs, rates, cumulative volumes) starting at day
   31, reported as physical results, not as a tuning gate.
6. **Thermal specialization scope item** — explicit isothermal black-oil
   scope or a documented thermal data set and implementation
   (see `validation/reports/spe1_case1.md` "Remaining work before SPE1
   completion" item 4).

Until items 1–2 resolve, do not count any reduced or full acceptance run as
passing, and do not cite the legacy `drsdt_gate_artifacts*` sets as current evidence.
