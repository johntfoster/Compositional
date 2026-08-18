#!/usr/bin/env python3
"""Quantitatively check the 2D Q2/EG reaction/source MMS."""

from __future__ import annotations

import csv
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
APP_DIR = ROOT / "moose_app"
APP = APP_DIR / "multicomponent_reactive_flow-opt"
DECK = APP_DIR / "test" / "tests" / "reaction_tau" / "drained_reaction_source_mms_2d.i"

TOLERANCE = 1.0e-10
ERROR_COLUMNS = (
    "ux_l2",
    "uy_l2",
    "p_total_l2",
    "p_total_gradient_l2",
    "p_enrichment_l2",
    "summed_reference_component_storage_l2",
    "summed_reference_component_storage_rate_l2",
    "summed_reference_component_source_l2",
    "summed_reference_component_flux_x_l2",
    "summed_reference_component_flux_y_l2",
)
EXPECTED_INTEGRALS = {
    "summed_reference_component_storage_rate_integral": 0.0125,
    "net_outward_reference_component_flux": -0.009375,
    "summed_reference_component_source_integral": 0.003125,
}


def main() -> int:
    if not APP.exists():
        raise SystemExit(f"missing optimized executable: {APP}")

    with tempfile.TemporaryDirectory(prefix="drained_reaction_source_mms_2d_") as tmp:
        output_base = Path(tmp) / "result"
        subprocess.run(
            [str(APP), "-i", str(DECK), f"Outputs/file_base={output_base}"],
            cwd=APP_DIR,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        with Path(str(output_base) + ".csv").open(newline="") as handle:
            rows = list(csv.DictReader(handle))

    if not rows:
        raise SystemExit("2D reaction/source MMS produced no CSV rows")
    final = {name: float(value) for name, value in rows[-1].items()}
    required = ERROR_COLUMNS + tuple(EXPECTED_INTEGRALS) + (
        "summed_reference_component_global_balance",
    )
    missing = [name for name in required if name not in final]
    if missing:
        raise SystemExit("2D reaction/source MMS omitted: " + ", ".join(missing))

    failures = [
        f"{name}={abs(final[name]):.6e} > {TOLERANCE:.1e}"
        for name in ERROR_COLUMNS
        if abs(final[name]) > TOLERANCE
    ]
    balance = abs(final["summed_reference_component_global_balance"])
    if balance > TOLERANCE:
        failures.append(f"global_balance={balance:.6e} > {TOLERANCE:.1e}")
    for name, expected in EXPECTED_INTEGRALS.items():
        error = abs(final[name] - expected)
        if error > TOLERANCE:
            failures.append(f"{name}_error={error:.6e} > {TOLERANCE:.1e}")
    if failures:
        raise SystemExit("2D Q2/EG reaction/source MMS failed: " + "; ".join(failures))

    maximum_error = max(abs(final[name]) for name in ERROR_COLUMNS)
    print(
        "drained_reaction_source_mms_2d: "
        f"maximum_error={maximum_error:.6e}, global_balance={balance:.6e}, "
        f"storage_rate=0.0125, net_outward_flux=-0.009375, source=0.003125, "
        f"tolerance={TOLERANCE:.1e}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
