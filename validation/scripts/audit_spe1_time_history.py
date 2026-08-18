#!/usr/bin/env python3
"""Apply SPE1 pointwise and run-wide physical acceptance gates."""

from __future__ import annotations

import argparse
import csv
import json
import math
from pathlib import Path

from spe1_energy_gates import ENERGY_GATE_METRICS, energy_gate_limits


ABSOLUTE_LIMITS = {
    "phase_volume_constraint_l2": 1.0e-8,
    "matrix_component_balance_l2": 1.0e-6,
    "matrix_component_storage_rate_integral": 1.0e-8,
    "water_global_balance": 1.0e-6,
    "oil_global_balance": 1.0e-6,
    "gas_global_balance": 1.0e-6,
    "phase_transform_kinetic_residual_l2": 1.0e-7,
    "tau_evolution_residual_l2": 1.0e-7,
    "phase_transform_affinity_identity_l2": 1.0e-12,
    "phase_transform_generalized_force_identity_l2": 1.0e-12,
    "phase_transform_power_identity_l2": 1.0e-12,
    "matrix_momentum_x_scaled_weak_residual_linf": 1.0e-7,
    "matrix_momentum_y_scaled_weak_residual_linf": 1.0e-7,
    "matrix_momentum_z_scaled_weak_residual_linf": 1.0e-7,
    "fluid_energy_scaled_weak_residual_linf": 1.0e-7,
    "solid_energy_scaled_weak_residual_linf": 1.0e-7,
}
LOWER_LIMITS = {
    "minimum_gas_saturation": -1.0e-12,
    "minimum_phase_transform_dissipation": -1.0e-12,
    "minimum_solid_reference_jacobian": 1.0e-8,
}
UPPER_LIMITS = {"maximum_gas_saturation": 1.0 + 1.0e-12}
THERMODYNAMIC_DIAGNOSTICS = (
    "average_tau",
    "average_reconstructed_tau",
    "average_phase_transform_dissolved_mu",
    "average_phase_transform_free_mu",
    "average_phase_transform_affinity",
    "average_phase_transform_generalized_force",
    "average_gas_phase_transformation_rate",
)
ENERGY_DECOMPOSITION_DIAGNOSTICS = (
    "fluid_energy_storage_rate_integral",
    "solid_energy_storage_rate_integral",
    "fluid_energy_flux_divergence_integral",
    "solid_energy_flux_divergence_integral",
    "fluid_energy_boundary_flux",
    "solid_energy_boundary_flux",
    "fluid_energy_source_power_integral",
    "solid_energy_source_power_integral",
    "fluid_energy_external_work_power_integral",
    "solid_energy_external_work_power_integral",
    "fluid_energy_conversion_power_integral",
    "solid_energy_conversion_power_integral",
)
TEMPERATURE_FIELDS = ("average_fluid_temperature", "average_solid_temperature")
INITIAL_TEMPERATURE = 333.15
TEMPERATURE_TOLERANCE = 1.0e-8
INJECTOR_TARGET_RATE = 32.774128
PRODUCER_TARGET_OIL_RATE = 0.03680261456666667
WELL_RATE_RELATIVE_TOLERANCE = 1.0e-4
WELL_RATE_ABSOLUTE_TOLERANCE = 1.0e-8
BHP_CONTROL_ABSOLUTE_TOLERANCE = 1.0
INJECTOR_MAXIMUM_BHP = 62149342.24061635
PRODUCER_MINIMUM_BHP = 6894757.293168
ACTIVE_WELL_GAS_APPEARANCE_LOWER_LIMIT = 1.0e-3


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv", type=Path, help="Verifier result.csv")
    parser.add_argument("--output", type=Path, required=True, help="Output JSON")
    parser.add_argument("--active-wells", action="store_true")
    args = parser.parse_args()

    with args.csv.open(newline="", encoding="utf-8") as stream:
        rows = [
            {name: float(value) for name, value in row.items()}
            for row in csv.DictReader(stream)
            if float(row["time"]) > 0.0
        ]
    if not rows:
        raise SystemExit("CSV contains no accepted nonzero timestep")

    required = set(ABSOLUTE_LIMITS) | set(LOWER_LIMITS) | set(UPPER_LIMITS)
    required.update(THERMODYNAMIC_DIAGNOSTICS)
    required.update(ENERGY_DECOMPOSITION_DIAGNOSTICS)
    required.update(TEMPERATURE_FIELDS)
    required.update(ENERGY_GATE_METRICS)
    if args.active_wells:
        required.update(
            ("injected_gas_surface_rate", "producer_oil_surface_rate", "injector_bhp", "producer_bhp")
        )
    missing = sorted(required - rows[0].keys())
    if missing:
        raise SystemExit("CSV omits required columns: " + ", ".join(missing))

    # Run-wide scale-aware energy gates: the local residual L2 limit is an
    # equivalent pointwise temperature-rate noise floor (C * 1e-9 K/s), and
    # each global-balance limit is a fixed relative fraction of the largest
    # energy-decomposition term magnitude present anywhere in the run.
    energy_limits = energy_gate_limits(rows)

    failures: list[dict[str, float | str]] = []
    for row in rows:
        time_value = row["time"]
        for name in sorted(required):
            if not math.isfinite(row[name]):
                failures.append({"time": time_value, "metric": name, "reason": "not_finite"})
        for name, limit in ABSOLUTE_LIMITS.items():
            if math.isfinite(row[name]) and abs(row[name]) > limit:
                failures.append(
                    {"time": time_value, "metric": name, "observed": abs(row[name]), "limit": limit}
                )
        for name, limit in energy_limits.items():
            if math.isfinite(row[name]) and abs(row[name]) > limit:
                failures.append(
                    {"time": time_value, "metric": name, "observed": abs(row[name]),
                     "limit": limit}
                )
        for name, limit in LOWER_LIMITS.items():
            if math.isfinite(row[name]) and row[name] < limit:
                failures.append(
                    {"time": time_value, "metric": name, "observed": row[name], "lower_limit": limit}
                )
        for name, limit in UPPER_LIMITS.items():
            if math.isfinite(row[name]) and row[name] > limit:
                failures.append(
                    {"time": time_value, "metric": name, "observed": row[name], "upper_limit": limit}
                )
        for name in TEMPERATURE_FIELDS:
            error = abs(row[name] - INITIAL_TEMPERATURE)
            if math.isfinite(error) and error > TEMPERATURE_TOLERANCE:
                failures.append(
                    {"time": time_value, "metric": name, "observed_error": error,
                     "limit": TEMPERATURE_TOLERANCE}
                )
        if args.active_wells:
            control_data = (
                ("injected_gas_surface_rate", INJECTOR_TARGET_RATE),
                ("producer_oil_surface_rate", PRODUCER_TARGET_OIL_RATE),
            )
            injector_on_bhp = (
                row["injector_bhp"]
                >= INJECTOR_MAXIMUM_BHP - BHP_CONTROL_ABSOLUTE_TOLERANCE
            )
            producer_on_bhp = (
                row["producer_bhp"]
                <= PRODUCER_MINIMUM_BHP + BHP_CONTROL_ABSOLUTE_TOLERANCE
            )
            for (name, target), on_bhp in zip(
                control_data, (injector_on_bhp, producer_on_bhp)
            ):
                absolute_error = abs(row[name] - target)
                relative_error = absolute_error / target
                if (
                    not on_bhp
                    and absolute_error > WELL_RATE_ABSOLUTE_TOLERANCE
                    and relative_error > WELL_RATE_RELATIVE_TOLERANCE
                ):
                    failures.append(
                        {"time": time_value, "metric": name,
                         "relative_error": relative_error,
                         "limit": WELL_RATE_RELATIVE_TOLERANCE}
                    )
            if row["injector_bhp"] > INJECTOR_MAXIMUM_BHP + BHP_CONTROL_ABSOLUTE_TOLERANCE:
                failures.append(
                    {"time": time_value, "metric": "injector_bhp", "observed": row["injector_bhp"],
                     "upper_limit": INJECTOR_MAXIMUM_BHP}
                )
            if row["producer_bhp"] < PRODUCER_MINIMUM_BHP - BHP_CONTROL_ABSOLUTE_TOLERANCE:
                failures.append(
                    {"time": time_value, "metric": "producer_bhp", "observed": row["producer_bhp"],
                     "lower_limit": PRODUCER_MINIMUM_BHP}
                )

    maximum_gas_saturation = max(row["maximum_gas_saturation"] for row in rows)
    if args.active_wells and maximum_gas_saturation <= ACTIVE_WELL_GAS_APPEARANCE_LOWER_LIMIT:
        failures.append(
            {
                "metric": "maximum_gas_saturation",
                "observed": maximum_gas_saturation,
                "lower_limit": ACTIVE_WELL_GAS_APPEARANCE_LOWER_LIMIT,
            }
        )

    extrema = {
        name: {
            "maximum_absolute": max(abs(row[name]) for row in rows),
            "time_of_maximum_absolute": max(rows, key=lambda row: abs(row[name]))["time"],
        }
        for name in sorted(set(ABSOLUTE_LIMITS) | set(ENERGY_GATE_METRICS))
    }
    diagnostic_ranges = {
        name: {
            "minimum": min(row[name] for row in rows),
            "maximum": max(row[name] for row in rows),
        }
        for name in THERMODYNAMIC_DIAGNOSTICS
    }
    energy_decomposition_ranges = {
        name: {
            "minimum": min(row[name] for row in rows),
            "maximum": max(row[name] for row in rows),
        }
        for name in ENERGY_DECOMPOSITION_DIAGNOSTICS
    }
    document = {
        "status": "pass" if not failures else "fail",
        "accepted_nonzero_timesteps": len(rows),
        "first_time_seconds": rows[0]["time"],
        "last_time_seconds": rows[-1]["time"],
        "limits": {
            "absolute": ABSOLUTE_LIMITS,
            "energy_scale_aware": energy_limits,
            "lower": LOWER_LIMITS,
            "upper": UPPER_LIMITS,
            "temperature_tolerance": TEMPERATURE_TOLERANCE,
        },
        "thermodynamic_diagnostic_ranges": diagnostic_ranges,
        "energy_decomposition_ranges": energy_decomposition_ranges,
        "extrema": extrema,
        "failure_count": len(failures),
        "failures": failures,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.output.with_suffix(args.output.suffix + ".tmp")
    temporary.write_text(json.dumps(document, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    temporary.replace(args.output)
    print(f"{document['status']}: {len(rows)} accepted timesteps, {len(failures)} failures")
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
