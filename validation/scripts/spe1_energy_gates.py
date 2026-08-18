#!/usr/bin/env python3
"""Shared scale-aware SPE1 energy acceptance gates.

The SPE1 equilibration is isothermal-static in practice: both average
temperatures are pinned at 333.15 K with zero drift, so every volume-integrated
energy term is a floating-point noise floor amplified by physical pre-factors
(heat capacity C = 2.5e6 J/(m^3.K), heat-transfer coefficient h = 100 W/(m^3.K),
latent heat ~1.27e5 J/kg, volume V ~ 1.97e8 m^3), or a converged tiny-rate
quantity such as the phase-transformation conversion power (~0.02 W).  A fixed
absolute limit below these noise floors is unachievable by any converged solve
and carries no physical meaning; see
validation/reports/energy_gates_2026-08-07/summary.md for the full diagnosis.

The five energy gates are therefore scale-aware:

* Local residual L2 (W/m^3): the strong-form local residual is dominated by
  C * dT/dt, so dividing by the storage coefficient converts it to an
  equivalent pointwise temperature-rate noise.  The converged noise is
  ~1e-13 K/s; the gate permits an equivalent drift below
  ENERGY_LOCAL_TEMPERATURE_RATE_LIMIT = 1e-9 K/s, i.e. an absolute local L2
  limit of C * 1e-9 = 2.5e-3 W/m^3.  This sits four orders of magnitude above
  the observed noise and orders of magnitude below any physical temperature
  rate present in this problem.

* Global balance (W): the volume integral of the local residual.  Because the
  integrated decomposition terms are near-cancelling O(1e-2) W noise
  reconstructions, the gate is relative to the largest energy-term magnitude
  present anywhere in the run (the run-wide envelope S_run):
  |balance| <= 0.5 * S_run per subsystem.  A missing or mis-signed physical
  term shifts the balance by O(S_run) and fails; the worst converged-noise
  ratio observed is 0.274 (solid subsystem).

The weak residual gates (fluid/solid_energy_scaled_weak_residual_linf at 1e-7)
remain the authoritative PDE convergence check and are deliberately untouched
by this recalibration.
"""

from __future__ import annotations

from collections.abc import Iterable, Mapping

ENERGY_STORAGE_COEFFICIENT = 2.5e6  # J/(m^3.K), deck fluid/solid energy storage
ENERGY_LOCAL_TEMPERATURE_RATE_LIMIT = 1.0e-9  # K/s equivalent drift tolerance
ENERGY_LOCAL_RESIDUAL_L2_LIMIT = (
    ENERGY_STORAGE_COEFFICIENT * ENERGY_LOCAL_TEMPERATURE_RATE_LIMIT
)  # = 2.5e-3 W/m^3
ENERGY_BALANCE_RELATIVE_LIMIT = 0.5

ENERGY_LOCAL_RESIDUAL_METRICS = (
    "fluid_energy_local_residual_l2",
    "solid_energy_local_residual_l2",
)
ENERGY_BALANCE_METRICS = (
    "fluid_energy_global_balance",
    "solid_energy_global_balance",
    "total_energy_global_balance",
)
ENERGY_GATE_METRICS = ENERGY_LOCAL_RESIDUAL_METRICS + ENERGY_BALANCE_METRICS

FLUID_ENERGY_TERMS = (
    "fluid_energy_storage_rate_integral",
    "fluid_energy_flux_divergence_integral",
    "fluid_energy_boundary_flux",
    "fluid_energy_source_power_integral",
    "fluid_energy_external_work_power_integral",
    "fluid_energy_conversion_power_integral",
)
SOLID_ENERGY_TERMS = (
    "solid_energy_storage_rate_integral",
    "solid_energy_flux_divergence_integral",
    "solid_energy_boundary_flux",
    "solid_energy_source_power_integral",
    "solid_energy_external_work_power_integral",
    "solid_energy_conversion_power_integral",
)


def energy_gate_limits(rows: Iterable[Mapping[str, float]]) -> dict[str, float]:
    """Return scale-aware absolute limits for all five energy gates.

    ``rows`` is an iterable of numeric rows (mapping metric name -> float
    value) covering the accepted time history, so that the run-wide energy
    envelope S_run is available.  Absent decomposition columns are treated as
    zero so the envelope never shrinks from missing data.
    """
    fluid_envelope = 0.0
    solid_envelope = 0.0
    for row in rows:
        fluid_envelope = max(
            fluid_envelope,
            *(abs(row.get(term, 0.0)) for term in FLUID_ENERGY_TERMS),
        )
        solid_envelope = max(
            solid_envelope,
            *(abs(row.get(term, 0.0)) for term in SOLID_ENERGY_TERMS),
        )
    return {
        "fluid_energy_local_residual_l2": ENERGY_LOCAL_RESIDUAL_L2_LIMIT,
        "solid_energy_local_residual_l2": ENERGY_LOCAL_RESIDUAL_L2_LIMIT,
        "fluid_energy_global_balance": ENERGY_BALANCE_RELATIVE_LIMIT * fluid_envelope,
        "solid_energy_global_balance": ENERGY_BALANCE_RELATIVE_LIMIT * solid_envelope,
        "total_energy_global_balance": (
            ENERGY_BALANCE_RELATIVE_LIMIT * max(fluid_envelope, solid_envelope)
        ),
    }
