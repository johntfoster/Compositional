#!/usr/bin/env python3
"""Quantitatively check the coupled 1D Q2/EG poromechanics MMS."""

from __future__ import annotations

import csv
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
APP_DIR = ROOT / "moose_app"
APP = APP_DIR / "multicomponent_reactive_flow-opt"
DECK = APP_DIR / "test" / "tests" / "eg_hierarchy" / "coupled_q2_eg_poro_mms_1d.i"

LIMITS = {
    "ux_l2": 1.0e-10,
    "ux_h1_semi": 1.0e-10,
    "p_material_l2": 1.0e-10,
    "p_gradient_l2": 1.0e-10,
    "p_enrichment_l2": 1.0e-10,
    "summed_reference_component_storage_l2": 1.0e-10,
}


def main() -> int:
    if not APP.exists():
        raise SystemExit(f"missing optimized executable: {APP}")

    with tempfile.TemporaryDirectory(prefix="coupled_q2_eg_poro_mms_1d_") as tmp:
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
        raise SystemExit("coupled MMS produced no CSV rows")
    final = {name: float(value) for name, value in rows[-1].items()}
    failures = [
        f"{name}={final[name]:.6e} > {limit:.1e}"
        for name, limit in LIMITS.items()
        if final[name] > limit
    ]
    if failures:
        raise SystemExit("coupled Q2/EG poromechanics MMS failed: " + "; ".join(failures))

    print(
        "coupled_q2_eg_poro_mms_1d: "
        + ", ".join(f"{name}={final[name]:.6e}" for name in LIMITS)
        + ", tolerance=1.0e-10"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
