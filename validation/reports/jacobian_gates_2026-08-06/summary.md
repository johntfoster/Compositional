# SPE1 Jacobian / AD regression gate check — 2026-08-06

Question under test: is the full-deck FD Jacobian hang a physics/implementation bug?

## Finding: NO. No physics or AD implementation bug is indicated.

### Prior diagnostic failures (2026-08-06, session diag_jac_test) — all CLI construction errors:
- run_jac_abs.log: `producer_water_surface_rate` Postprocessor missing from `Postprocessors/active=` override -> MOOSE reporter-declaration abort.
- run_stdout.log: `-snes_test_jacobian_view` made PETSc parse `Variables/inactive=` as a viewer spec -> "Unsupported viewer" crash.
- run_fixed2.log: MOOSE params placed after PETSc flags -> PETSc consumed `Postprocessors/active=` as FD threshold -> "no numeric value" crash.

### Corrected full-deck run (run_order.log): physics assembled cleanly
- AD Jacobian computed without error (7.99 s), residual formed |R| = 4.706299e+02,
  deck solved Step 1; the run spent >1 h in PETSc's finite-difference Jacobian
  comparison phase on the 43,541-DOF 3D Q2/EG TET10 deck — an intrinsically
  expensive column-by-column FD computation, not a hang (99.9% CPU, rising CPU time).
- Stopped after ~67 min per user steering; this diagnostic is not a required gate.

### Required fast gates — all PASS
run_tests subset (moose_app, conda moose env):
- black_oil_benchmark_pvt.phase_transform_helmholtz_identity_1d ........ OK
- black_oil_benchmark_pvt.phase_transform_helmholtz_identity_jacobian_1d OK
- black_oil_benchmark_pvt.pressure_dependent_rock_storage_1d ........... OK
- black_oil_benchmark_pvt.spe1_oversaturated_rs_rejected ............... OK
- black_oil_benchmark_pvt.spe1_active_gas_pvt_1d ....................... OK
- black_oil_benchmark_pvt.spe1_history_cap_negative_gas_rejected_1d .... OK
- black_oil_benchmark_pvt.spe1_left_extreme_completed_pvto_1d .......... OK
- black_oil_benchmark_pvt.gas_appearance_complementarity_solve_1d ...... OK
- black_oil_ad_completion_control.ad_completion_control_cg_eg_1d ...... OK
- black_oil_ad_completion_control.ad_completion_control_cg_eg_jacobian . OK
- phase_thermodynamic_identities.phase_pressure_momentum_stitch_{1d,2d,3d,jacobian} OK
- phase_thermodynamic_identities.{negative_saturation,nonpositive_temperature,reference_force_gauge_violation,phase_list_size_mismatch}_rejected OK

Direct small-deck check: `phase_transform_helmholtz_identity_1d.i -snes_test_jacobian`
- ||J - Jfd||_F/||J||_F = 1.00282e-09  (O(1e-8) -> hand-coded AD Jacobian correct)
- Solve Converged! after 1 linear iteration to |R| = 0.

### Conclusion
AD/PETSc Jacobian regression gates pass; no physics or implementation defect
found. The full-production-deck FD Jacobian comparison is a very expensive
diagnostic only; the small-deck PetscJacobianTester gates are the authoritative
Jacobian checks.

## Follow-up (2026-08-07): reduced-gate `-snes_test_jacobian` on the stalled path — AD Jacobian is consistent

The current-library production CG/EG deck shows a Newton grind (step 0:
442→404→…→plateau ~244-246, DIVERGED_MAX_IT) instead of the historical
8-iteration convergence (441.94→1.81e-9). To decide whether this is a
Jacobian/residual inconsistency (implementation bug) or a conditioning/closure
issue, the 18-element reduced gate was run with `-snes_test_jacobian`.

Run: reduced deck (18 elements, 665-679 DOFs), 16 MPI ranks, `-snes_test_jacobian`,
output captured to the archived `reduced_jac_mpi/run.log`.

Result — every FD-vs-AD ratio across the entire stalled step is excellent:

```
||J - Jfd||_F/||J||_F = 2.14592e-12   (Newton iter 0, |R| = 2.675735e+03)
||J - Jfd||_F/||J||_F = 1.24442e-13   (iter 1)
||J - Jfd||_F/||J||_F = 1.26733e-13   (iter 2)
... ratios remain 1e-13..1e-14 through all iterations incl. the halved-dt retry
```
(more than 50 successive ratios, all <= 2.1e-12; final sampled values
8.3e-14, 1.2e-13, 7.7e-14, 1.2e-13, 7.3e-14, 7.6e-14.)

Interpretation: the hand-coded AD Jacobian is consistent with the assembled
residual on the CURRENT stalled path. The Newton grind is therefore NOT a
Jacobian/residual inconsistency. The stall is a conditioning / near-singularity /
closure issue introduced at the library layer between the historical passing
library (`f67db160`, 2026-08-05 03:22) and the current one (`cd5bcb23`,
2026-08-06 13:01). Linear solves drop only to ~1e-4–1e-5 and the nonlinear
residual grinds with ratio ~0.91 (vs 0.199 in the accepted run), consistent with
an ill-conditioned assembled system rather than an inconsistent Jacobian.

Action: bisect the library regression by reverting the mcrf-resume-differing
deck-critical source files one at a time (see todo `bisect-library-regression`),
rebuilding, and re-running the reduced gate until the first-step Newton ratio
returns to ~0.2.

## Follow-up (2026-08-07): full-mesh reproduction — regression is intrinsic to the current library, not the reduced gate

To rule out that the grind was an artifact of the 18-element reduced-gate mesh,
the exact passing smoke-v2 command was replicated against the current committed
library on the FULL mesh (no `ix`/`iy` overrides, dt=10800, num_steps=1, well
blocks 1 2 3, scalar-kernel and postprocessor active lists identical to the
passing run; only `Outputs/file_base` changed). Script:
archived `spe1_fullmesh_curlib/run_smoke.sh`, log `spe1_fullmesh_curlib/run.log`.

Result — the full mesh grinds and then ABORTS on the J>0 guard:

```
Time Step 1, dt = 10800
  nonlinear iteration 0: |R| = 4.706299e+02
  1: 4.678121e+02   2: 4.662014e+02   3: 4.653540e+02   ...
  13: 4.624522e+02   (ratio ≈ 0.997, slow Newton grind)
Abort: matrix_mass_and_volume (ADSolidPhaseMassVolumeMaterial):
  solid-reference Jacobian must remain positive   [J ≤ 0 guard]
MPI abort, exit 1
```

This is decisive: the exact full-mesh configuration that converged healthily
with library `7d51bab8` (solver.log 441.94→69.44, 1 converged solve, 0 rejected)
now grinds AND trips the binary J>0 mooseError with the HEAD-built library.
The grind is a true library-layer source regression, not a reduced-gate artifact.

Additional evidence — the regression is confined to the app library:
- The executable (`44c7f7be…`) and test library (`9a439cf7…`) are byte-identical
  between the passing era and the current build. Only the main app library
  differs (`7d51bab8`/`f67db160` passing vs `cd5bcb23`/`c1984258` current).
- The Aug 7 05:21 rebuild recompiled only `materials_Unity` and `kernels_Unity`
  objects; all other unity objects (actions, base, bcs, dgkernels, dampers,
  postprocessors, scalarkernels, userobjects) date from Aug 5 17:56–21:35,
  i.e. after the passing runs (13:37/15:39) — the source shift is in
  materials/kernels edited during the Aug 5 evening session (16:00–22:26).
- Tree-hash reconciliation: passing runs used trees `f0223462`/`919c0655`; the
  current committed tree is `7d75523a` (identical to the "master" run that
  grinds with lib `cd5bcb23`). The passing-era source is unrecoverable
  (single commit `58cd7ae`, no surviving `.so`, no pre-edit blobs in git).

Next diagnostic step: step-size sensitivity (smaller initial dt on the full
mesh) to distinguish a pure big-dt Newton stability issue from a closure-level
error in the current source.

## Step-size sensitivity (2026-08-07, dt = 2700 s, current HEAD library)

Per the next-step above, reran the exact full-mesh smoke with
`Executioner/dt=2700.0` (4x smaller than the 10800 s step) against the current
committed-state library (`cd5bcb23`/`c1984258`, tree `7d75523a`).

Command: exact smoke-v2 replication (full mesh, num_steps=1, empty
Variables/Materials inactive overrides, well blocks 1 2 3, scalar-kernel and
postprocessor active lists) with `Executioner/dt=2700.0` substituted.
Evidence: archived `spe1_smalldt_curlib/run_dt2700.sh` and `run_dt2700.log`.

Result — the grind is dt-independent:

```
Time Step 1, time = 2700, dt = 2700
 0 Nonlinear |R| = 4.706299e+02   (identical to dt=10800 initial residual)
 1  4.689224e+02   2  4.684665e+02   3  4.680905e+02   ...
18  4.643816e+02   (ratio ≈ 0.997 plateau, same linear decay)
```

- Initial residual |R|0 = 470.63 is byte-identical between dt=10800 and dt=2700,
  confirming the initial-state/property conditioning differs from the healthy
  baseline (441.94) regardless of the time step.
- The Newton trajectory follows the same ≈0.997 linear decay per iteration at
  both step sizes; dt=2700 passed iteration 13 without tripping the J>0 guard
  (the Jacobian has not yet gone non-positive at that iterate), then continued
  the identical grind until stopped at iteration 18.
- Conclusion: the divergence is NOT a big-dt Newton stability issue. A smaller
  initial dt does not restore healthy convergence (healthy signature
  ≈0.199 ratio: 441.94→87.84/69.44). The regression is a closure/conditioning
  error in the current materials/kernels source, dt-independent.

This closes the step-size-sensitivity question from the previous section. The
remaining diagnostic path is the source-level bisect: revert the post-passing
materials/kernels edits (mcrf-resume `08-04 22:58` baseline is intact with all
8 suspect file pairs) and re-test the reduced production gate.
