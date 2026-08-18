#!/usr/bin/env python3
"""Check Q2 mechanics and P1+P0 EG pressure/tau convergence."""

from __future__ import annotations

import csv
import math
import subprocess
import tempfile
from pathlib import Path
from typing import Callable


ROOT = Path(__file__).resolve().parents[2]
APP_DIR = ROOT / "moose_app"
APP = APP_DIR / "multicomponent_reactive_flow-opt"
TEST_DIR = APP_DIR / "test" / "tests" / "eg_hierarchy"


OverrideFactory = Callable[[int], list[str]]


PRESSURE_CASES = [
    {
        "name": "pressure_1d",
        "deck": "eg_pressure_mms_1d.i",
        "meshes": [8, 16, 32, 64],
        "overrides": lambda n: [f"mesh_nx:={n}"],
        "l2": "p_material_l2",
        "grad": "p_gradient_l2",
        "min_l2_rate": 1.85,
        "min_grad_rate": 0.95,
    },
    {
        "name": "pressure_2d",
        "deck": "eg_pressure_mms_2d.i",
        "meshes": [4, 8, 16],
        "overrides": lambda n: [f"mesh_nx:={n}", f"mesh_ny:={n}"],
        "l2": "p_material_l2",
        "grad": "p_gradient_l2",
        "min_l2_rate": 1.85,
        "min_grad_rate": 0.95,
    },
    {
        "name": "pressure_3d",
        "deck": "eg_pressure_mms_3d.i",
        "meshes": [2, 3, 4],
        "overrides": lambda n: [f"mesh_nx:={n}", f"mesh_ny:={n}", f"mesh_nz:={n}"],
        "l2": "p_material_l2",
        "grad": "p_gradient_l2",
        "min_l2_rate": 1.85,
        "min_grad_rate": 0.95,
    },
]


TAU_CASES = [
    {
        "name": "tau_1d",
        "deck": "eg_tau_fluxless_mms_1d.i",
        "meshes": [8, 16, 32, 64],
        "overrides": lambda n: [f"mesh_nx:={n}"],
        "l2": "tau_material_l2",
        "grad": "tau_gradient_l2",
        "min_l2_rate": 1.95,
        "min_grad_rate": 0.95,
    },
    {
        "name": "tau_2d",
        "deck": "eg_tau_fluxless_mms_2d.i",
        "meshes": [4, 8, 16],
        "overrides": lambda n: [f"mesh_nx:={n}", f"mesh_ny:={n}"],
        "l2": "tau_material_l2",
        "grad": "tau_gradient_l2",
        "min_l2_rate": 1.90,
        "min_grad_rate": 0.95,
    },
    {
        "name": "tau_3d",
        "deck": "eg_tau_fluxless_mms_3d.i",
        "meshes": [2, 3, 4],
        "overrides": lambda n: [f"mesh_nx:={n}", f"mesh_ny:={n}", f"mesh_nz:={n}"],
        "l2": "tau_material_l2",
        "grad": "tau_gradient_l2",
        "min_l2_rate": 1.85,
        "min_grad_rate": 0.90,
    },
]


MECHANICS_CASES = [
    {
        "name": "mechanics_1d",
        "deck": "q2_mechanics_mms_1d.i",
        "meshes": [4, 8, 16, 32],
        "overrides": lambda n: [f"mesh_nx:={n}"],
        "l2_components": ["ux_l2"],
        "h1_components": ["ux_h1_semi"],
        "min_l2_rate": 2.95,
        "min_h1_rate": 1.95,
    },
    {
        "name": "mechanics_2d",
        "deck": "q2_mechanics_mms_2d.i",
        "meshes": [2, 4, 8, 16],
        "overrides": lambda n: [f"mesh_nx:={n}", f"mesh_ny:={n}"],
        "l2_components": ["ux_l2", "uy_l2"],
        "h1_components": ["ux_h1_semi", "uy_h1_semi"],
        "min_l2_rate": 2.95,
        "min_h1_rate": 1.95,
    },
    {
        "name": "mechanics_3d",
        "deck": "q2_mechanics_mms_3d.i",
        "meshes": [2, 3, 4],
        "overrides": lambda n: [f"mesh_nx:={n}", f"mesh_ny:={n}", f"mesh_nz:={n}"],
        "l2_components": ["ux_l2", "uy_l2", "uz_l2"],
        "h1_components": ["ux_h1_semi", "uy_h1_semi", "uz_h1_semi"],
        "min_l2_rate": 2.90,
        "min_h1_rate": 1.95,
    },
]


def run_case(deck: str, overrides: list[str], output_base: Path) -> dict[str, float]:
  command = [
      str(APP),
      "-i",
      str(TEST_DIR / deck),
      *overrides,
      f"Outputs/file_base={output_base}",
  ]
  subprocess.run(command, cwd=APP_DIR, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
  with Path(str(output_base) + ".csv").open(newline="") as handle:
    rows = list(csv.DictReader(handle))
  if not rows:
    raise RuntimeError(f"{deck} produced no CSV rows")
  return {key: float(value) for key, value in rows[-1].items()}


def convergence_rate(coarse_error: float, fine_error: float, coarse_n: int, fine_n: int) -> float:
  if fine_error <= 0.0:
    return math.inf
  return math.log(coarse_error / fine_error) / math.log(fine_n / coarse_n)


def rates(rows: list[dict[str, float]], meshes: list[int], key: str) -> list[float]:
  return [
      convergence_rate(rows[i][key], rows[i + 1][key], meshes[i], meshes[i + 1])
      for i in range(len(rows) - 1)
  ]


def require_min_rate(label: str, observed: list[float], minimum: float) -> None:
  if min(observed) < minimum:
    raise SystemExit(f"{label} rates too low: {observed}; expected at least {minimum}")


def check_pressure(output_dir: Path) -> None:
  for case in PRESSURE_CASES:
    rows = [
        run_case(case["deck"], case["overrides"](n), output_dir / f"{case['name']}_{n}")
        for n in case["meshes"]
    ]
    l2_rates = rates(rows, case["meshes"], case["l2"])
    grad_rates = rates(rows, case["meshes"], case["grad"])
    require_min_rate(f"{case['name']} pressure L2", l2_rates, case["min_l2_rate"])
    require_min_rate(f"{case['name']} pressure gradient", grad_rates, case["min_grad_rate"])
    print(
        f"{case['name']}: {case['l2']}={rows[-1][case['l2']]:.6e}, "
        f"{case['grad']}={rows[-1][case['grad']]:.6e}, "
        f"l2_rates={l2_rates}, grad_rates={grad_rates}")


def check_tau(output_dir: Path) -> None:
  for case in TAU_CASES:
    rows = [
        run_case(case["deck"], case["overrides"](n), output_dir / f"{case['name']}_{n}")
        for n in case["meshes"]
    ]
    l2_rates = rates(rows, case["meshes"], case["l2"])
    grad_rates = rates(rows, case["meshes"], case["grad"])
    require_min_rate(f"{case['name']} tau L2", l2_rates, case["min_l2_rate"])
    require_min_rate(f"{case['name']} tau gradient", grad_rates, case["min_grad_rate"])
    final = rows[-1]
    if final["tau_enrichment_l2"] > 1.0e-10:
      raise SystemExit(f"{case['name']} anchored tau enrichment too large: {final['tau_enrichment_l2']}")
    if abs(final["tau_enrichment_average"]) > 1.0e-10:
      raise SystemExit(
          f"{case['name']} anchored tau enrichment average drifted: "
          f"{final['tau_enrichment_average']}")
    print(
        f"{case['name']}: {case['l2']}={rows[-1][case['l2']]:.6e}, "
        f"{case['grad']}={rows[-1][case['grad']]:.6e}, "
        f"l2_rates={l2_rates}, grad_rates={grad_rates}")


def check_mechanics(output_dir: Path) -> None:
  for case in MECHANICS_CASES:
    rows = [
        run_case(case["deck"], case["overrides"](n), output_dir / f"{case['name']}_{n}")
        for n in case["meshes"]
    ]
    l2_rates_by_component = {}
    for component in case["l2_components"]:
      component_rates = rates(rows, case["meshes"], component)
      require_min_rate(f"{case['name']} {component}", component_rates, case["min_l2_rate"])
      l2_rates_by_component[component] = component_rates
    h1_rates_by_component = {}
    for component in case["h1_components"]:
      component_rates = rates(rows, case["meshes"], component)
      require_min_rate(f"{case['name']} {component}", component_rates, case["min_h1_rate"])
      h1_rates_by_component[component] = component_rates
    final_l2 = {name: rows[-1][name] for name in case["l2_components"]}
    final_h1 = {name: rows[-1][name] for name in case["h1_components"]}
    print(
        f"{case['name']}: l2={final_l2}, h1={final_h1}, "
        f"l2_rates={l2_rates_by_component}, h1_rates={h1_rates_by_component}")


def check_tau_null_mode(output_dir: Path) -> None:
  deck = "eg_tau_fluxless_free_mms_1d.i"
  anchored_zero = run_case(deck,
                           ["mesh_nx:=8", "eg_tau_anchor:=1", "tau_initial_shift:=0.0"],
                           output_dir / "tau_null_anchor_zero")
  anchored_shift = run_case(deck,
                            ["mesh_nx:=8", "eg_tau_anchor:=1", "tau_initial_shift:=0.25"],
                            output_dir / "tau_null_anchor_shift")
  unanchored_zero = run_case(deck,
                             ["mesh_nx:=8", "eg_tau_anchor:=0", "tau_initial_shift:=0.0"],
                             output_dir / "tau_null_free_zero")
  unanchored_shift = run_case(deck,
                              ["mesh_nx:=8", "eg_tau_anchor:=0", "tau_initial_shift:=0.25"],
                              output_dir / "tau_null_free_shift")

  if anchored_zero["tau_enrichment_l2"] > 1.0e-10:
    raise SystemExit("anchored tau null-mode check left nonzero enrichment")
  if anchored_shift["tau_enrichment_l2"] > 1.0e-10:
    raise SystemExit("anchored shifted tau null-mode check left nonzero enrichment")
  if abs(anchored_zero["tau_material_l2"] - anchored_shift["tau_material_l2"]) > 1.0e-12:
    raise SystemExit("anchored tau total error changed under a pure null-mode initial shift")
  if unanchored_zero["tau_enrichment_l2"] < 1.0e-2 and unanchored_shift["tau_enrichment_l2"] < 1.0e-2:
    raise SystemExit("unanchored tau solve did not expose the enrichment null representative")
  if abs(unanchored_zero["tau_material_l2"] - unanchored_shift["tau_material_l2"]) > 1.0e-12:
    raise SystemExit("unanchored tau total field changed under a pure null-mode initial shift")

  print(
      "tau_null_mode: "
      f"anchored_enrichment=({anchored_zero['tau_enrichment_l2']:.6e}, "
      f"{anchored_shift['tau_enrichment_l2']:.6e}), "
      f"unanchored_enrichment=({unanchored_zero['tau_enrichment_l2']:.6e}, "
      f"{unanchored_shift['tau_enrichment_l2']:.6e})")


def main() -> int:
  if not APP.exists():
    raise SystemExit(f"missing optimized executable: {APP}")

  with tempfile.TemporaryDirectory(prefix="q2_eg_convergence_") as tmp:
    output_dir = Path(tmp)
    check_pressure(output_dir)
    check_tau(output_dir)
    check_tau_null_mode(output_dir)
    check_mechanics(output_dir)

  return 0


if __name__ == "__main__":
  raise SystemExit(main())
