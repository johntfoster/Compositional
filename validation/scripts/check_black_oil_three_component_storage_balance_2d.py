#!/usr/bin/env python3
"""Quantitatively check the 2D black-oil Q2/EG storage reduction."""

from __future__ import annotations

import csv
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
APP_DIR = ROOT / "moose_app"
APP = APP_DIR / "multicomponent_reactive_flow-opt"
DECK = (
    APP_DIR
    / "test"
    / "tests"
    / "black_oil_pvt"
    / "black_oil_three_component_storage_balance_2d.i"
)

LIMITS = {
    "pressure_l2": 1.0e-10,
    "pressure_enrichment_l2": 1.0e-10,
    "water_saturation_l2": 1.0e-10,
    "gas_saturation_l2": 1.0e-10,
    "solid_reference_jacobian_l2": 1.0e-10,
    "water_component_storage_rate_l2": 1.0e-10,
    "oil_component_storage_rate_l2": 1.0e-10,
    "gas_component_storage_rate_l2": 1.0e-10,
}


def main() -> int:
    if not APP.exists():
        raise SystemExit(f"missing optimized executable: {APP}")

    with tempfile.TemporaryDirectory(prefix="black_oil_storage_balance_2d_") as tmp:
        output_base = Path(tmp) / "result"
        command = [str(APP), "-i", str(DECK), f"Outputs/file_base={output_base}"]
        subprocess.run(
            command,
            cwd=APP_DIR,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        with Path(str(output_base) + ".csv").open(newline="") as handle:
            rows = list(csv.DictReader(handle))

    if not rows:
        raise SystemExit("2D black-oil storage reduction produced no CSV rows")
    final = {name: float(value) for name, value in rows[-1].items()}
    missing = [name for name in LIMITS if name not in final]
    if missing:
        raise SystemExit("2D black-oil storage reduction omitted norms: " + ", ".join(missing))
    failures = [
        f"{name}={final[name]:.6e} > {limit:.1e}"
        for name, limit in LIMITS.items()
        if final[name] > limit
    ]
    if failures:
        raise SystemExit("2D black-oil Q2/EG storage reduction failed: " + "; ".join(failures))

    print(
        "black_oil_three_component_storage_balance_2d: "
        + ", ".join(f"{name}={final[name]:.6e}" for name in LIMITS)
        + ", tolerance=1.0e-10"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
