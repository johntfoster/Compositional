#!/usr/bin/env python3
"""Extract the pinned SPE1 OPM report-step vectors into a portable CSV file."""

from __future__ import annotations

import argparse
import csv
import os
from pathlib import Path
import subprocess


VECTORS = (
    "TIME",
    "FOPR",
    "FGOR",
    "BPR:1,1,1",
    "BPR:10,10,3",
    "BGSAT:10,10,3",
    "WBHP:INJ",
    "WBHP:PROD",
    "WGIR:INJ",
    "WOPR:PROD",
    "WGPR:PROD",
    "WOPT:PROD",
    "WGPT:PROD",
)

HEADERS = (
    "time_days",
    "field_oil_rate_stb_per_day",
    "field_gor_mscf_per_stb",
    "injector_cell_pressure_psia",
    "producer_cell_pressure_psia",
    "producer_cell_gas_saturation",
    "injector_bhp_psia",
    "producer_bhp_psia",
    "injector_gas_rate_mscf_per_day",
    "producer_oil_rate_stb_per_day",
    "producer_gas_rate_mscf_per_day",
    "produced_oil_volume_stb",
    "produced_gas_volume_mscf",
)


def parse_rows(text: str) -> list[list[float]]:
    rows: list[list[float]] = []
    for line in text.splitlines():
        fields = line.split()
        if len(fields) != len(VECTORS):
            continue
        try:
            rows.append([float(value) for value in fields])
        except ValueError:
            continue
    if len(rows) != 120:
        raise ValueError(f"expected 120 SPE1 report rows, found {len(rows)}")
    if rows[-1][0] != 3650.0:
        raise ValueError(f"expected final SPE1 report day 3650, found {rows[-1][0]}")
    return rows


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--summary-executable", required=True, type=Path)
    parser.add_argument("--smspec", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument(
        "--library-path",
        help="Optional runtime library directory prepended to LD_LIBRARY_PATH.",
    )
    args = parser.parse_args()

    env = os.environ.copy()
    if args.library_path:
        prior = env.get("LD_LIBRARY_PATH", "")
        env["LD_LIBRARY_PATH"] = (
            args.library_path if not prior else f"{args.library_path}:{prior}"
        )
    command = [
        str(args.summary_executable),
        "-r",
        str(args.smspec),
        *VECTORS,
    ]
    completed = subprocess.run(
        command,
        check=True,
        capture_output=True,
        text=True,
        env=env,
    )
    rows = parse_rows(completed.stdout)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream)
        writer.writerow(HEADERS)
        writer.writerows(rows)
    print(f"wrote {len(rows)} SPE1 report rows to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
