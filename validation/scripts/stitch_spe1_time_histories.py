#!/usr/bin/env python3
"""Join restart-segment SPE1 CSV histories into one accepted-state history."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path


def read_history(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    with path.open(newline="", encoding="utf-8") as stream:
        reader = csv.DictReader(stream)
        if reader.fieldnames is None:
            raise RuntimeError(f"CSV has no header: {path}")
        rows = list(reader)
    if not rows:
        raise RuntimeError(f"CSV has no rows: {path}")
    return reader.fieldnames, rows


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    parser.add_argument("histories", nargs="+", type=Path)
    args = parser.parse_args()

    fieldnames: list[str] | None = None
    combined: list[dict[str, str]] = []
    for path in args.histories:
        current_fields, rows = read_history(path)
        if fieldnames is None:
            fieldnames = current_fields
        elif current_fields != fieldnames:
            raise SystemExit(f"CSV header differs: {path}")
        start = 0
        if combined:
            previous_time = float(combined[-1]["time"])
            first_time = float(rows[0]["time"])
            if abs(first_time - previous_time) <= 1.0e-8:
                start = 1
            elif first_time < previous_time:
                raise SystemExit(f"nonmonotone restart history: {path}")
        combined.extend(rows[start:])

    for previous, current in zip(combined, combined[1:]):
        if float(current["time"]) <= float(previous["time"]):
            raise SystemExit("stitched history is not strictly increasing")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(combined)
    print(f"stitched {len(combined)} rows")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
