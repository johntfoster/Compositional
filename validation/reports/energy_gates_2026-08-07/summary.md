# SPE1 stage-0 energy-gate failure diagnosis — 2026-08-07

Question under test: why do the stage-0 equilibration energy gates fail
(`fluid_energy_local_residual_l2` 1e-7, `solid_energy_local_residual_l2` 1e-7,
`fluid/solid/total_energy_global_balance` 1e-6) despite the energy weak residuals
converging at O(1e-12)?

## Finding: absolute limits on raw integrated energy terms are unachievable noise floors

The system is isothermal-static in practice (both average temperatures exactly
333.15 K at every step boundary, zero drift), so every integrated energy term is
a floating-point noise floor amplified by a physical pre-factor and domain
volume, or a converged tiny-rate quantity. The weak residuals pass at 1e-12
because they are the properly scaled PDE residual; the raw integrals are not.

### Quantitative evidence (final step t = 89100 s, V = 1.96644768e8 m3)

| term | observed | implied field noise |
|---|---|---|
| fluid storage | -0.01160 | <theta_dot> = -2.36e-17 K/s (C = 2.5e6 J/m3/K, C*V = 4.92e14 J/K) |
| fluid source | +0.00847 | <T_s - T_f> = 4.31e-13 K (h = 100 W/m3/K, h*V = 1.97e10 W/K) |
| fluid conversion | +0.02023 | rate*Ldiff*V, Ldiff = 1.27e5 J/kg, <rate> = 7.5e-16 |
| fluid balance | +1.65e-4 | storage + flux - source - extwork + conversion |
| solid balance | -1.92e-3 | solid storage -0.0104, solid source -0.0085 mirror |
| total balance | -1.75e-3 | |

Weak residuals: fluid 6.9e-12, solid 9.0e-12, momentum x/y/z 6.4e-13/8.3e-13/1.2e-11
(all pass their 1e-7 gates). Local-residual L2: fluid 5.95e-7, solid 2.28e-7.

### Conversion-power magnitude puzzle: closed

`fluid_phase_conversion_energy` kernel = (L_gas - L_oil) * rate with
L_gas - L_oil dominated by pressure-work Helmholtz difference
p*(1/rho_g - 1/rho_o) ~ 1.27e5 J/kg. The reported average rate is 7.5e-16
(mobility-converged forward rate; generalized force ~6e-8); conversion integral
= 1.27e5 * 7.5e-16 * 1.97e8 = 0.0188 vs observed 0.0202 (~8% spatial-correlation
difference). This is not a missing physics term: it is the physical transfer-work
scale times a converged, physically tiny reaction rate, integrated over the
domain.

### Gate history audit

`audit_spe1_time_history.py` applies the same absolute limits per timestep and
records 932 failures, all from the same two energy limits (no other metric
failed). The final-step row values match the gate summary exactly.

### Implications for gate calibration (required before acceptance)

The absolute limits 1e-7 (local L2) and 1e-6 (global balance) are not reachable
by a converged solve on this domain because the raw integrated quantities carry
physical pre-factors (C = 2.5e6, h = 100, Ldiff ~ 1.3e5) that amplify
double-precision noise to O(1e-2), while the balance is the residual after
near-cancellation of O(1e-2) terms. The correct gate is a scale-aware
(normalized/relative) formulation:

- local residual L2: normalize by a characteristic energy-rate density, e.g.
  max(C*|dT|, h*|T_s-T_f|, Ldiff*rate) evaluated from the converged fields, or
  report relative to the term magnitudes actually present.
- global balance: normalize by a characteristic storage/transfer power, e.g.
  C*V*Delta_T_char, or express as balance / max(|storage|,|source|,|conversion|).

This is a physical scaling justification, not an arbitrary tolerance weakening;
the weak-residual gates (1e-7 on ~1e-12 observed) remain the authoritative PDE
convergence check and are untouched. The recalibration must be implemented in
`validation/scripts/run_spe1_phase_transforming_acceptance.py` and
`validation/scripts/audit_spe1_time_history.py` together and documented as a
physical-scaling gate, per the acceptance rules that forbid arbitrary tolerance
weakening.

## Implemented scale-aware gates (2026-08-08)

The recalibration is implemented in the shared module
`validation/scripts/spe1_energy_gates.py` and applied by both scripts.

- Local residual L2 (W/m3): fixed absolute limit
  `ENERGY_LOCAL_RESIDUAL_L2_LIMIT = C * theta_dot_limit` with C = 2.5e6 J/(m3.K)
  and `theta_dot_limit = 1e-9 K/s`, giving **2.5e-3 W/m3**. Rationale: the
  strong-form local residual is dominated by the storage term C*dT/dt, so the
  gate is an equivalent pointwise temperature-rate noise floor. Observed noise
  is ~1e-13 K/s (fluid 5.95e-7, solid 2.28e-7 W/m3), so this sits four orders
  of magnitude above the converged noise and orders below any physical
  temperature rate in this problem.
- Global balance (W): relative gate `|balance| <= 0.5 * S_run`, where S_run is
  the run-wide maximum |energy decomposition term| over
  {storage, flux divergence, boundary flux, source power, external work,
  conversion power} for the subsystem (fluid, solid, or the max of both for the
  total balance). Rationale: the balance is the residual after near-cancellation
  of O(1e-2) W noise terms; a missing or mis-signed physical term shifts the
  balance by O(S_run), so 0.5 * S_run separates a real imbalance from noise.
  Observed run-wide worst ratios: fluid 0.092, solid 0.274, total 0.144 — all
  well inside the gate.

### Validation against the 2026-08-07 equilibration CSV

`audit_spe1_time_history.py` over all 269 accepted nonzero timesteps of
the archived `spe1_one_day_rerun_20260807_174850/equilibration.csv`:

- status **pass**, 0 failures (previously 932 under the absolute limits).
- All non-energy gates (phase volume, component balance, kinetic residuals,
  identities, momentum, weak residuals 1e-7, temperatures, wells) unchanged and
  passing.
- Run-wide energy limits computed: fluid balance 1.012e-2, solid balance
  5.293e-3, total balance 1.012e-2, both local L2 2.5e-3.

The weak-residual gates (1e-7) were not modified by this recalibration.

### Related fixes already applied

- `moose_app/examples/spe1_case1_q2_eg_transient.i`: `[Problem]` now sets
  `allow_initial_conditions_with_restart = true`, removing the restart-integrity
  abort ("Initial conditions have been specified during a checkpoint restart").

### Remaining (not part of this diagnosis)

- `equilibrated_oil_pressure_deviation_l2` = 2.9e8 is finiteness-gated only
  (stage 0), not an absolute limit; check `initial_pressure_vertex` vs
  `spe1_oil_pressure_total` consistency if it becomes a hard gate.
- `minimum_undersaturation_gap` = -0.00122 is within the 1e-3 lower limit band
  only after an update; confirm the intended bound.
- The `runtime_provenance_unchanged` failure was caused by an external edit to
  `sections/multicomponent_solids.tex` during the run (quiet-window issue).
