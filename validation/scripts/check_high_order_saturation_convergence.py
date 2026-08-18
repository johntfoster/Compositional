#!/usr/bin/env python3
"""Compare P1+P0 and P2+P0 enriched-Galerkin saturation convergence."""

from __future__ import annotations

import argparse
import csv
import json
import math
import subprocess
import tempfile
from pathlib import Path

import matplotlib.pyplot as plt


ROOT = Path(__file__).resolve().parents[2]
APP_DIR = ROOT / "moose_app"
APP = APP_DIR / "multicomponent_reactive_flow-opt"
DECK = APP_DIR / "test/tests/saturation_entropy_viscosity/saturation_basis_mms_1d.i"


def run(order: str, n: int, output: Path) -> dict[str, float]:
  command = [
      str(APP),
      "-i",
      str(DECK),
      f"mesh_nx:={n}",
      f"saturation_order:={order}",
      f"Outputs/file_base={output}",
  ]
  subprocess.run(command, cwd=APP_DIR, check=True, stdout=subprocess.PIPE,
                 stderr=subprocess.STDOUT)
  with Path(str(output) + ".csv").open(newline="") as handle:
    rows = list(csv.DictReader(handle))
  if not rows:
    raise RuntimeError(f"no CSV rows for {order}, nx={n}")
  return {key: float(value) for key, value in rows[-1].items()}


def rates(rows: list[dict[str, float]], meshes: list[int], key: str) -> list[float]:
  return [
      math.log(rows[i][key] / rows[i + 1][key]) /
      math.log(meshes[i + 1] / meshes[i])
      for i in range(len(rows) - 1)
  ]


def require(label: str, condition: bool, detail: object) -> None:
  if not condition:
    raise SystemExit(f"{label} failed: {detail}")


def main() -> int:
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument("--output-json", type=Path)
  parser.add_argument("--output-figure", type=Path)
  args = parser.parse_args()
  if not APP.exists():
    raise SystemExit(f"missing optimized executable: {APP}")

  cases = {
      "FIRST": {"meshes": [8, 16, 32, 64], "min_l2": 1.85, "min_grad": 0.95},
      "SECOND": {"meshes": [4, 8, 16, 32], "min_l2": 2.75, "min_grad": 1.80},
  }
  results: dict[str, list[dict[str, float]]] = {}
  convergence_rates: dict[str, dict[str, list[float]]] = {}
  with tempfile.TemporaryDirectory(prefix="saturation_order_") as tmp:
    output_dir = Path(tmp)
    for order, case in cases.items():
      meshes = case["meshes"]
      rows = [run(order, n, output_dir / f"{order.lower()}_{n}") for n in meshes]
      l2_rates = rates(rows, meshes, "saturation_l2")
      grad_rates = rates(rows, meshes, "saturation_gradient_l2")
      require(f"{order} L2 order", min(l2_rates) >= case["min_l2"], l2_rates)
      require(f"{order} gradient order", min(grad_rates) >= case["min_grad"], grad_rates)
      results[order] = rows
      convergence_rates[order] = {"l2": l2_rates, "gradient_l2": grad_rates}
      print(
          f"{order}: final_l2={rows[-1]['saturation_l2']:.6e}, "
          f"final_grad={rows[-1]['saturation_gradient_l2']:.6e}, "
          f"l2_rates={l2_rates}, grad_rates={grad_rates}")

  p1_at_32 = results["FIRST"][2]["saturation_l2"]
  p2_at_32 = results["SECOND"][-1]["saturation_l2"]
  require("P2+P0 accuracy advantage at nx=32", p2_at_32 < 0.1 * p1_at_32,
          {"P1+P0": p1_at_32, "P2+P0": p2_at_32})
  print(f"nx=32 P2/P1 L2 ratio={p2_at_32 / p1_at_32:.6e}")

  document = {
      "status": "pass",
      "deck": str(DECK.relative_to(ROOT)),
      "cases": {
          order: {
              "meshes": cases[order]["meshes"],
              "rows": rows,
              "rates": convergence_rates[order],
          }
          for order, rows in results.items()
      },
      "p2_to_p1_l2_ratio_at_nx_32": p2_at_32 / p1_at_32,
  }
  if args.output_json:
    args.output_json.parent.mkdir(parents=True, exist_ok=True)
    args.output_json.write_text(
        json.dumps(document, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
  if args.output_figure:
    args.output_figure.parent.mkdir(parents=True, exist_ok=True)
    plt.style.use("seaborn-v0_8-whitegrid")
    fig, axes = plt.subplots(1, 2, figsize=(10.5, 4.2))
    for order, rows in results.items():
      meshes = cases[order]["meshes"]
      axes[0].loglog(meshes, [row["saturation_l2"] for row in rows], marker="o", label=order)
      axes[1].loglog(
          meshes,
          [row["saturation_gradient_l2"] for row in rows],
          marker="o",
          label=order,
      )
    axes[0].set(xlabel="elements", ylabel="saturation L2 error", title="Value convergence")
    axes[1].set(
        xlabel="elements",
        ylabel="saturation-gradient L2 error",
        title="Gradient convergence",
    )
    for axis in axes:
      axis.legend(title="CG backbone order")
    fig.tight_layout()
    fig.savefig(args.output_figure, bbox_inches="tight")
    fig.savefig(args.output_figure.with_suffix(".png"), dpi=180, bbox_inches="tight")
    plt.close(fig)
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
