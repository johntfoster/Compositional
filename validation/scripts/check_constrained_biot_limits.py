#!/usr/bin/env python3
"""Check production Eq. (32) Biot small-strain limits across dimensions."""

from __future__ import annotations

import argparse
import csv
import math
import subprocess
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
APP_DIR = ROOT / "moose_app"
APP = APP_DIR / "multicomponent_reactive_flow-opt"
TEST_DIR = APP_DIR / "test" / "tests" / "nonlinear_biot_coefficient"

DIMENSIONS = (1, 2, 3)
K_OVER_KS_RATIOS = (0.0, 0.25, 0.4, 0.75, 1.0)
STRAIN_AMPLITUDES = (1.0e-2, 1.0e-3, 1.0e-4, 1.0e-6)
CURVATURE = 0.12
ZERO_TOL = 1.0e-9
ENDPOINT_TOL = 1.0e-6
MIN_LIMIT_RATE = 0.999


def run_case(dimension: int, ratio: float, amplitude: float, output_dir: Path) -> dict[str, float]:
    deck = TEST_DIR / f"constrained_biot_small_strain_{dimension}d.i"
    # Reuse one isolated working directory for the four sequential amplitudes
    # in a dimension/ratio series.  The parsed expressions are identical, so
    # this safely reuses their JIT objects without the cross-process race that
    # motivated serialized execution.
    run_dir = output_dir / f"d{dimension}_r{ratio:g}"
    run_dir.mkdir(exist_ok=True)
    output_base = run_dir / f"result_a{amplitude:g}"
    command = [
        str(APP),
        "-i",
        str(deck),
        f"drained_to_grain_bulk_ratio:={ratio:.17g}",
        f"strain_amp:={amplitude:.17g}",
        f"finite_deformation_curvature:={CURVATURE:.17g}",
        f"Outputs/file_base={output_base}",
    ]
    completed = subprocess.run(
        command,
        cwd=run_dir,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    if completed.returncode:
        raise RuntimeError(
            f"{deck.name} failed for K/K_s={ratio:g}, amplitude={amplitude:g}:\n"
            f"{completed.stdout}"
        )
    with Path(str(output_base) + ".csv").open(newline="") as handle:
        rows = list(csv.DictReader(handle))
    if not rows:
        raise RuntimeError(f"{deck.name} produced no CSV rows")
    result = {key: float(value) for key, value in rows[-1].items()}
    result.update(dimension=float(dimension), ratio=ratio, amplitude=amplitude)
    return result


def require_near_zero(row: dict[str, float], key: str) -> None:
    if abs(row[key]) > ZERO_TOL:
        raise SystemExit(
            f"{key}={row[key]:.6e} exceeds {ZERO_TOL:.1e} for "
            f"dimension={int(row['dimension'])}, K/K_s={row['ratio']:g}, "
            f"amplitude={row['amplitude']:g}"
        )


def limit_rate(coarse_error: float, fine_error: float, coarse_amplitude: float,
               fine_amplitude: float) -> float:
    if fine_error == 0.0:
        return math.inf
    return math.log(coarse_error / fine_error) / math.log(coarse_amplitude / fine_amplitude)


def check_series(rows: list[dict[str, float]]) -> None:
    dimension = int(rows[0]["dimension"])
    ratio = rows[0]["ratio"]
    target = 1.0 - ratio

    for row in rows:
        for key in (
            "biot_l2",
            "biot_fd_l2",
            "constraint_l2",
            "density_l2",
            "intrinsic_density_specific_volume_inverse_consistency_l2",
            "reference_accumulation_consistency_l2",
            "storage_identity_l2",
            "undrained_storage_l2",
        ):
            require_near_zero(row, key)
        if not row["biot_min"] <= row["biot_average"] <= row["biot_max"]:
            raise SystemExit(
                f"Biot extrema do not contain the average for dimension={dimension}, "
                f"K/K_s={ratio:g}, amplitude={row['amplitude']:g}"
            )
        if 0.0 < ratio < 1.0 and not 0.0 < row["biot_average"] < 1.0:
            raise SystemExit(
                f"Intermediate Biot coefficient is out of bounds for dimension={dimension}, "
                f"K/K_s={ratio:g}, amplitude={row['amplitude']:g}: "
                f"B={row['biot_average']:.16g}"
            )

    errors = [abs(row["biot_average"] - target) for row in rows]
    rates = [
        limit_rate(errors[index], errors[index + 1], rows[index]["amplitude"],
                   rows[index + 1]["amplitude"])
        for index in range(len(rows) - 1)
    ]
    if min(rates) < MIN_LIMIT_RATE:
        raise SystemExit(
            f"B -> 1-K/K_s rate is too low for dimension={dimension}, K/K_s={ratio:g}: "
            f"errors={errors}, rates={rates}"
        )
    if errors[-1] > ENDPOINT_TOL:
        raise SystemExit(
            f"Small-strain Biot limit missed for dimension={dimension}, K/K_s={ratio:g}: "
            f"B={rows[-1]['biot_average']:.16g}, target={target:.16g}"
        )

    # The supported undrained response is dp/d(epsilon_v) = -B/M^{-1}.
    # Its deck-level residual must approach the classical small-strain value.
    undrained_errors = [abs(row["undrained_response_small_strain_l2"]) for row in rows]
    if undrained_errors[-1] > 1.0e-4:
        raise SystemExit(
            f"Undrained small-strain limit missed for dimension={dimension}, K/K_s={ratio:g}: "
            f"errors={undrained_errors}"
        )

    print(
        f"dimension={dimension}, K/K_s={ratio:g}: "
        f"B={rows[-1]['biot_average']:.9g}, target={target:.9g}, "
        f"rates={[round(rate, 6) for rate in rates]}, "
        f"undrained_error={undrained_errors[-1]:.3e}"
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Check production Eq. (32) Biot small-strain limits. By default all "
            "three dimensions are checked; --dimension restricts the run without "
            "changing any ratios, amplitudes, or assertions."
        )
    )
    parser.add_argument(
        "--dimension",
        type=int,
        choices=DIMENSIONS,
        help="check only the selected spatial dimension (1, 2, or 3)",
    )
    parser.add_argument(
        "--ratio",
        type=float,
        choices=K_OVER_KS_RATIOS,
        help="check only the selected K/K_s ratio",
    )
    return parser.parse_args()


def main() -> int:
    arguments = parse_args()
    if not APP.is_file():
        raise SystemExit(f"Missing optimized application executable: {APP}")

    dimensions = (arguments.dimension,) if arguments.dimension is not None else DIMENSIONS
    ratios = (arguments.ratio,) if arguments.ratio is not None else K_OVER_KS_RATIOS

    with tempfile.TemporaryDirectory(prefix="constrained_biot_limits_") as temporary:
        output_dir = Path(temporary)
        cases = [
            (dimension, ratio, amplitude, output_dir)
            for dimension in dimensions
            for ratio in ratios
            for amplitude in STRAIN_AMPLITUDES
        ]
        # Parsed AD materials may JIT-compile the same generated source name.  Running
        # independent MOOSE processes concurrently races those temporary files, so
        # serialize the cases; this is a correctness check, not a throughput test.
        with ThreadPoolExecutor(max_workers=1) as executor:
            results = list(executor.map(lambda arguments: run_case(*arguments), cases))

    for dimension in dimensions:
        for ratio in ratios:
            series = sorted(
                (
                    row
                    for row in results
                    if int(row["dimension"]) == dimension and row["ratio"] == ratio
                ),
                key=lambda row: row["amplitude"],
                reverse=True,
            )
            check_series(series)

    print(
        f"PASS production constrained Eq. (32): B -> 1-K/K_s in "
        f"{'/'.join(f'{dimension}D' for dimension in dimensions)}, "
        "including Terzaghi B->1, equal-modulus B->0, intermediate bounds, "
        "storage identity, and the supported undrained limit"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
