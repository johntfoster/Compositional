#!/usr/bin/env python3
"""Audit the local SPE1 DRSDT=0 dissolved-gas history from report fields.

SPE1 Case 1 permits pressure-driven exsolution, while the dissolved gas-oil
ratio R_s must not exceed its initial value or recover after it has decreased.
The audit compares each element-sampled R_s value over the accepted trajectory.
"""

from __future__ import annotations

import argparse
import csv
import glob
import json
import math
import re
from pathlib import Path


FIELD_INDEX_PATTERN = re.compile(r"_(\d+)\.csv$")


def field_index(path: Path) -> int:
    match = FIELD_INDEX_PATTERN.search(path.name)
    if not match:
        raise ValueError(f"Cannot determine the timestep index from {path}")
    return int(match.group(1))


def read_result_times(path: Path) -> list[float]:
    with path.open(newline="", encoding="utf-8") as stream:
        rows = list(csv.DictReader(stream))
    if not rows:
        raise ValueError(f"Result CSV is empty: {path}")
    return [float(row["time"]) for row in rows]


def read_element_values(path: Path) -> dict[int, float] | None:
    with path.open(newline="", encoding="utf-8") as stream:
        rows = list(csv.DictReader(stream))
    required = {"id", "sample_solution_gas_oil_ratio"}
    if not rows:
        return None
    missing = required - set(rows[0])
    if missing:
        raise ValueError(f"{path} omits required columns: {', '.join(sorted(missing))}")
    values = {int(row["id"]): float(row["sample_solution_gas_oil_ratio"]) for row in rows}
    if len(values) != len(rows):
        raise ValueError(f"{path} has duplicate element identifiers")
    if not all(math.isfinite(value) for value in values.values()):
        raise ValueError(f"{path} has a non-finite sampled solution gas-oil ratio")
    return values


def write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    temporary.replace(path)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--result-csv", required=True, type=Path)
    parser.add_argument("--field-glob", required=True)
    parser.add_argument("--initial-rs", required=True, type=float)
    parser.add_argument("--absolute-tolerance", default=1.0e-8, type=float)
    parser.add_argument("--max-reported-failures", default=100, type=int)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    if args.initial_rs < 0.0:
        parser.error("--initial-rs must be nonnegative")
    if args.absolute_tolerance < 0.0:
        parser.error("--absolute-tolerance must be nonnegative")
    if args.max_reported_failures < 1:
        parser.error("--max-reported-failures must be positive")

    all_field_paths = [Path(path) for path in glob.glob(args.field_glob)]
    all_field_paths.sort(key=field_index)
    if not all_field_paths:
        raise SystemExit(f"No physical-element field files match {args.field_glob}")
    times = read_result_times(args.result_csv)
    empty_paths: list[Path] = []
    field_paths: list[Path] = []
    field_values: list[dict[int, float]] = []
    for field_path in all_field_paths:
        values = read_element_values(field_path)
        if values is None:
            empty_paths.append(field_path)
        else:
            field_paths.append(field_path)
            field_values.append(values)
    if empty_paths and (
        len(empty_paths) != 1 or field_index(empty_paths[0]) != 0
    ):
        raise SystemExit(
            "Only the initial physical-element field snapshot may be empty; got "
            + ", ".join(str(path) for path in empty_paths)
        )
    if len(times) == len(field_paths):
        field_times = times
    elif len(times) == len(field_paths) + 1 and times[0] == 0.0 and empty_paths:
        field_times = times[1:]
    else:
        raise SystemExit(
            "Result CSV and physical-element field counts differ: "
            f"{len(times)} times versus {len(field_paths)} populated field files"
        )

    failures: list[dict[str, float | int | str]] = []
    failure_count = 0
    previous: dict[int, float] | None = None
    maximum_value = -math.inf
    maximum_value_time = math.nan
    maximum_value_element = -1
    maximum_excess = -math.inf
    maximum_increase = -math.inf
    maximum_increase_time = math.nan
    maximum_increase_element = -1
    element_count = 0
    for time_value, field_path, current in zip(field_times, field_paths, field_values):
        if previous is not None and set(current) != set(previous):
            raise SystemExit(f"Element identifiers change between field snapshots at {field_path}")
        element_count = len(current)
        for element_id, value in current.items():
            excess = value - args.initial_rs
            if value > maximum_value:
                maximum_value = value
                maximum_value_time = time_value
                maximum_value_element = element_id
            if excess > maximum_excess:
                maximum_excess = excess
            if excess > args.absolute_tolerance:
                failure_count += 1
                if len(failures) < args.max_reported_failures:
                    failures.append(
                        {
                            "kind": "initial_cap_exceeded",
                            "time_seconds": time_value,
                            "element_id": element_id,
                            "observed_rs": value,
                            "initial_rs": args.initial_rs,
                            "excess": excess,
                        }
                    )
            if previous is not None:
                increase = value - previous[element_id]
                if increase > maximum_increase:
                    maximum_increase = increase
                    maximum_increase_time = time_value
                    maximum_increase_element = element_id
                if increase > args.absolute_tolerance:
                    failure_count += 1
                    if len(failures) < args.max_reported_failures:
                        failures.append(
                            {
                                "kind": "redissolution_history_increase",
                                "time_seconds": time_value,
                                "element_id": element_id,
                                "previous_rs": previous[element_id],
                                "observed_rs": value,
                                "increase": increase,
                            }
                        )
        previous = current

    document = {
        "audit": "SPE1 DRSDT=0 elementwise dissolved-gas history",
        "status": "pass" if failure_count == 0 else "fail",
        "result_csv": str(args.result_csv),
        "field_glob": args.field_glob,
        "accepted_snapshots": len(field_paths),
        "element_count": element_count,
        "initial_solution_gas_oil_ratio": args.initial_rs,
        "absolute_tolerance": args.absolute_tolerance,
        "maximum_solution_gas_oil_ratio": maximum_value,
        "maximum_solution_gas_oil_ratio_time_seconds": maximum_value_time,
        "maximum_solution_gas_oil_ratio_element_id": maximum_value_element,
        "maximum_initial_cap_excess": maximum_excess,
        "maximum_stepwise_increase": maximum_increase if len(field_paths) > 1 else 0.0,
        "maximum_stepwise_increase_time_seconds": (
            maximum_increase_time if len(field_paths) > 1 else math.nan
        ),
        "maximum_stepwise_increase_element_id": (
            maximum_increase_element if len(field_paths) > 1 else -1
        ),
        "failure_count": failure_count,
        "reported_failure_count": len(failures),
        "reported_failure_limit": args.max_reported_failures,
        "failures": failures,
    }
    write_json(args.output, document)
    print(
        f"{document['status']}: {len(field_paths)} snapshots, {element_count} elements, "
        f"{failure_count} DRSDT=0 history violations"
    )
    return 0 if failure_count == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
