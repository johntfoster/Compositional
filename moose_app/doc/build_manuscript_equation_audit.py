#!/usr/bin/env python3
"""Build the current-manuscript equation coverage audit.

The script follows the ``main.tex`` input graph, inventories only ``eq:``
labels, and joins those labels to the repository's structured implementation
and verification maps.  Classification rules are deliberately kept here so
that a regenerated audit records both the result and its basis.
"""

from __future__ import annotations

import hashlib
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

import yaml


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "moose_app/doc/manuscript_equation_coverage_audit.yml"

MAP_FILES = [
    "implementation_paper/equation_to_moose_map.yml",
    "moose_app/doc/theory_traceability.yml",
    "moose_app/doc/manuscript_operator_inventory.yml",
    "validation/validation_matrix.yml",
    "validation/mms_inventory.yml",
]

RUNTIME_LABELS = {
    "eq:component_spatial_mass",
    "eq:averaged_component_spatial_mass",
    "eq:averaged_global_component_balance",
    "eq:component_charge_balance",
    "eq:mixture_charge_balance_with_sources",
    "eq:mixture_charge_balance",
    "eq:el_momentum_uniform",
    "eq:el_mom_f_dynamic_capillary_general",
    "eq:el_mom_f_simplified",
    "eq:el_mom_f_dynamic_capillary",
    "eq:neutral_conversion_free_fluid_momentum_balance",
    "eq:gauss_law",
    "eq:MC_skeleton_phase_mass_balance",
    "eq:MC_energy_balance",
    "eq:MC_solid_phase_momentum_biot",
    "eq:MC_overall_momentum_nonlinear_biot",
    "eq:solid_reference_fluid_component_balance",
    "eq:solid_reference_solid_component_balance",
    "eq:solid_reference_overall_momentum",
    "eq:reservoir_simulation_overall_momentum_summary",
    "eq:reservoir_simulation_fluid_component_summary",
    "eq:reservoir_simulation_velocity_flux_summary",
    "eq:reservoir_simulation_reference_flux_summary",
    "eq:reservoir_simulation_capillary_summary",
}

CONSTITUTIVE_LABELS = {
    "eq:phase_pressure_storage",
    "eq:fluid_volume_fraction_el_relation",
    "eq:fluid_pressure_primitive_potential_relation",
    "eq:fluid_pressure_difference_primitive_potential",
    "eq:wetting_nonwetting_capillary_pressure_recovery",
    "eq:saturation_weighted_pressure_sum",
    "eq:saturation_weighted_primitive_potential_sum",
    "eq:equivalent_pore_pressure_capillary_relation",
    "eq:el_eta_constraint",
    "eq:Pi_componentwise",
    "eq:pi_difference_system",
    "eq:el_conversion_component",
    "eq:onsager_affinity_constitutive_relation",
    "eq:onsager_reaction_rate_variational",
    "eq:onsager_dispersion_mobility_balance",
    "eq:onsager_diffusion_mobility_balance",
    "eq:MC_dynamic_capillary_onsager_relation",
    "eq:MC_dynamic_capillary_force_rate_relation",
    "eq:MC_dynamic_capillary_resistance_admissibility",
    "eq:MC_fluid_composition_projection",
    "eq:MC_solid_composition_projection",
    "eq:MC_neutral_component_euler_identity",
    "eq:MC_transfer_work_component_difference",
    "eq:MC_generalized_transfer_potential_difference",
    "eq:MC_generalized_transfer_phase_offset",
    "eq:MC_transfer_work_full_recovery",
    "eq:MC_transfer_work_reference_normalization",
    "eq:MC_admissible_conversion_component",
    "eq:MC_phase_reference_transfer_work_recovery",
    "eq:MC_helmholtz_source_projection",
    "eq:MC_affinity_projection",
    "eq:MC_generalized_conversion_affinity_relation",
    "eq:MC_temperature_weighted_reaction_power",
    "eq:MC_dynamic_capillary_dissipation",
    "eq:MC_two_phase_dynamic_capillary_pressure",
    "eq:MC_capillary_history_admissibility",
    "eq:MC_reaction_energy_allocation",
    "eq:MC_reaction_energy_allocation_mixture",
    "eq:MC_reaction_energy_allocation_subsystems",
    "eq:MC_onsager_reaction_rate",
    "eq:MC_reaction_energy_coupled_admissibility",
    "eq:MC_onsager_dispersion_stationarity",
    "eq:MC_onsager_diffusion_stationarity",
    "eq:MC_dispersion_closure",
    "eq:MC_diffusion_closure",
    "eq:MC_relative_transport_closures",
    "eq:MC_onsager_reaction_transport_dissipation",
    "eq:MC_generic_plastic_flow_rules",
    "eq:MC_generic_plastic_deformation_flow_rule",
    "eq:MC_generic_plastic_distension_flow_rule",
    "eq:MC_generic_plastic_deformation_mobility_nonnegative",
    "eq:MC_generic_plastic_distension_mobility_nonnegative",
    "eq:MC_interaction_energy_conservation",
    "eq:MC_mechanical_interaction_admissibility",
    "eq:MC_pairwise_interaction_force",
    "eq:MC_interaction_power_pairing",
    "eq:MC_interphase_exchange_law",
    "eq:MC_fluid_skeleton_interaction_force",
    "eq:MC_aggregate_solid_interaction_force",
    "eq:MC_fluid_skeleton_drag_tensor",
    "eq:MC_drag_heating_equal_partition",
    "eq:MC_fluid_interaction_energy_supply",
    "eq:MC_solid_interaction_energy_supply",
    "eq:MC_fluid_solid_heat_exchange_law",
    "eq:MC_heat_flux_law",
    "eq:MC_phase_equivalent_pressure",
    "eq:fluid_phase_interaction_law",
    "eq:relative_flux_linear_system",
    "eq:modified_relative_flux_permeability",
    "eq:generalized_fluid_darcy_mass_flux",
    "eq:standard_darcy_mass_flux_limit",
    "eq:reference_relative_mass_flux",
    "eq:pulled_back_modified_permeability",
}

EQUIVALENT_LABELS = {
    "eq:averaged_global_component_balance": "eq:averaged_component_spatial_mass",
    "eq:el_momentum_uniform": "eq:el_mom_f_simplified",
    "eq:el_mom_f_dynamic_capillary_general": "eq:el_mom_f_dynamic_capillary",
    "eq:neutral_conversion_free_fluid_momentum_balance": "eq:el_mom_f_simplified",
    "eq:gauss_law": "eq:MC_electrostatic_power_identity",
    "eq:MC_solid_phase_momentum_biot": "eq:MC_overall_momentum_nonlinear_biot",
    "eq:reservoir_simulation_overall_momentum_summary": "eq:MC_overall_momentum_nonlinear_biot",
    "eq:reservoir_simulation_fluid_component_summary": "eq:solid_reference_fluid_component_balance",
    "eq:reservoir_simulation_velocity_flux_summary": "eq:generalized_fluid_darcy_mass_flux",
    "eq:reservoir_simulation_reference_flux_summary": "eq:reference_relative_mass_flux",
    "eq:reservoir_simulation_capillary_summary": "eq:el_mom_f_dynamic_capillary",
}

DERIVED_RUNTIME_CONSTRAINTS = {
    "eq:component_charge_balance": "follows from charged component mass balance",
    "eq:mixture_charge_balance_with_sources": "sum of charged component mass balances",
    "eq:mixture_charge_balance": "sum of charged component mass balances with mechanism charge conservation",
    "eq:MC_skeleton_phase_mass_balance": "sum of the phase's component balances",
}

DIRECT_TEST_MAPPINGS = {
    "eq:phase_pressure_storage": [
        "moose_app/test/tests/theory_composition_projection/theory_composition_projection_1d.i",
        "moose_app/test/tests/theory_composition_projection/theory_composition_projection_newton_1d.i",
    ],
    "eq:MC_fluid_composition_projection": [
        "moose_app/test/tests/theory_composition_projection/theory_composition_projection_1d.i",
        "moose_app/test/tests/theory_composition_projection/theory_composition_projection_newton_1d.i",
    ],
    "eq:MC_solid_composition_projection": [
        "moose_app/test/tests/theory_composition_projection/theory_composition_projection_1d.i"
    ],
}

DERIVATION_TOKENS = (
    "variation",
    "chain_rule",
    "substitution",
    "collected",
    "power_split",
    "product_rule",
    "differential_cancellation",
    "path_identity",
    "rate_reduction",
    "rollup_expanded",
    "verification",
)

CONSTITUTIVE_TOKENS = (
    "closure",
    "free_energy",
    "stress_definition",
    "pressure_definition",
    "entropy_definition",
    "potential_difference",
    "flow_rule",
    "mobility",
    "interaction_force",
    "heat_exchange_law",
    "heat_flux_law",
    "biot_coefficient",
    "biot_split",
    "legendre_transform",
    "electric_enthalpy",
    "admissibility",
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def included_tex(root: Path) -> list[Path]:
    ordered: list[Path] = []

    def visit(path: Path) -> None:
        path = path.resolve()
        if path in ordered:
            return
        ordered.append(path)
        text = path.read_text()
        for match in re.finditer(r"\\(?:input|include)\{([^}]+)\}", text):
            child = path.parent / match.group(1)
            if not child.suffix:
                child = child.with_suffix(".tex")
            if child.exists():
                visit(child)

    visit(root / "main.tex")
    return ordered


def equation_labels(paths: list[Path]) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for path in paths:
        relative = path.relative_to(ROOT).as_posix()
        section = ""
        subsection = ""
        for line_number, line in enumerate(path.read_text().splitlines(), 1):
            heading = re.search(r"\\section\*?\{([^}]*)\}", line)
            if heading:
                section = heading.group(1)
                subsection = ""
            heading = re.search(r"\\subsection\*?\{([^}]*)\}", line)
            if heading:
                subsection = heading.group(1)
            for label in re.findall(r"\\label\{(eq:[^}]+)\}", line):
                records.append(
                    {
                        "label": label,
                        "source": relative,
                        "line": line_number,
                        "section": section or None,
                        "subsection": subsection or None,
                    }
                )
    return records


def classification(record: dict[str, Any]) -> tuple[str, str]:
    label = record["label"]
    source = record["source"]
    tail = label.removeprefix("eq:")

    if "fracture" in tail or "crack" in tail:
        return "excluded_fracture", "fracture label"
    if source == "sections/correspondence_to_other_theories.tex":
        return "comparison_reduction", "correspondence section"
    if source == "sections/appendix_component_potential_derivation.tex":
        return "derivation_only", "component-potential derivation appendix"
    if label in RUNTIME_LABELS:
        return "runtime_operator", "explicit governing balance or evolution equation"
    if label in CONSTITUTIVE_LABELS:
        return "constitutive_algebraic_relation", "explicit constitutive or algebraic solve relation"
    if label in {
        "eq:interphase_force_global_balance",
        "eq:phase_electric_enthalpy_pullback",
        "eq:equivalent_pore_pressure_definition",
        "eq:charge_gauss_compatibility",
        "eq:charge_gauss_eulerian_compatibility",
        "eq:relative_mass_flux_definition",
        "eq:solid_reference_relative_flux",
    }:
        return "definition_kinematic_identity", "definition, compatibility condition, or exact pull-back identity"
    if label in {
        "eq:MC_fluid_free_energy_rate",
        "eq:MC_solid_free_energy_rate",
        "eq:MC_phase_rate_free_energy_transport_identity",
    }:
        return "derivation_only", "free-energy rate expansion used to derive restrictions"
    if any(token in tail for token in DERIVATION_TOKENS):
        return "derivation_only", "intermediate variation, chain rule, collection, or check"
    if tail.startswith(("vp_", "delta", "onsager_thermodynamic_rate", "reaction_transport_dissipation")):
        return "derivation_only", "variational intermediate"
    if tail in {
        "bd128_mod2",
        "bd128_mod",
        "kinetic_energy_variation_before_time_integration",
        "component_thermodynamic_rate_reduction",
        "collected_full",
        "hamilton_dispersion_force_balance",
        "hamilton_diffusion_force_balance",
        "MC_fluid_phase_following_free_energy_chain_rule",
    }:
        return "derivation_only", "derivation intermediate"
    if tail.startswith("MC_single_component_") or tail.startswith("MC_scalar_"):
        return "comparison_reduction", "named specialization or limiting reduction"
    if tail in {"MC_single_phase_energy_limit", "MC_montanaro_electric_enthalpy_limit"}:
        return "comparison_reduction", "named limiting reduction"
    if source == "sections/technical_setting.tex":
        return "definition_kinematic_identity", "technical definition, transformation rule, or boundary-data identity"
    if any(token in tail for token in CONSTITUTIVE_TOKENS):
        return "constitutive_algebraic_relation", "constitutive, closure, or admissibility relation"
    if tail.endswith(("_balance", "_momentum")):
        return "runtime_operator", "balance equation"
    if tail.startswith("MC_crystallization_"):
        return "constitutive_algebraic_relation", "crystallization specialization closure"
    return "definition_kinematic_identity", "definition, constraint, transformation, or exact identity"


def strings(value: Any) -> list[str]:
    if value is None:
        return []
    if isinstance(value, str):
        return [value]
    if isinstance(value, list):
        answer: list[str] = []
        for item in value:
            answer.extend(strings(item))
        return answer
    if isinstance(value, dict):
        answer = []
        for item in value.values():
            answer.extend(strings(item))
        return answer
    return []


def add_mapping(
    mapping: dict[str, dict[str, set[str]]],
    labels: list[str],
    objects: list[str],
    tests: list[str],
    evidence: str,
) -> None:
    for label in labels:
        if not isinstance(label, str) or not label.startswith("eq:"):
            continue
        mapping[label]["objects"].update(objects)
        mapping[label]["tests"].update(tests)
        mapping[label]["evidence"].add(evidence)


def structured_mappings() -> dict[str, dict[str, set[str]]]:
    mapping: dict[str, dict[str, set[str]]] = defaultdict(
        lambda: {"objects": set(), "tests": set(), "evidence": set()}
    )

    equation_map = yaml.safe_load((ROOT / MAP_FILES[0]).read_text())
    for item in equation_map.get("maps", []):
        labels = item.get("source", {}).get("theory_manuscript", {}).get("labels", [])
        plan = item.get("moose_plan", {})
        objects = []
        for key in ("kernels", "materials", "userobjects", "boundary_conditions", "actions", "dgkernels"):
            objects.extend(strings(plan.get(key)))
        add_mapping(mapping, labels, objects, strings(item.get("tests")), MAP_FILES[0])

    traceability = yaml.safe_load((ROOT / MAP_FILES[1]).read_text())

    def visit_trace(value: Any) -> None:
        if isinstance(value, dict):
            labels = strings(value.get("manuscript_basis"))
            if labels:
                local_objects = []
                local_tests = strings(value.get("test")) + strings(value.get("tests"))
                if "name" in value and any(key in value for key in ("files", "notes", "status")):
                    local_objects.extend(strings(value.get("name")))
                local_objects.extend(strings(value.get("object")))
                local_objects.extend(strings(value.get("objects")))
                for item in value.get("implemented_objects", []) if isinstance(value.get("implemented_objects"), list) else []:
                    if isinstance(item, dict):
                        local_objects.extend(strings(item.get("name")))
                        local_tests.extend(strings(item.get("test")) + strings(item.get("tests")))
                add_mapping(mapping, labels, local_objects, local_tests, MAP_FILES[1])
            for child in value.values():
                visit_trace(child)
        elif isinstance(value, list):
            for child in value:
                visit_trace(child)

    visit_trace(traceability)

    inventory = yaml.safe_load((ROOT / MAP_FILES[2]).read_text())
    for _, block in inventory.items():
        if not isinstance(block, dict):
            continue
        labels = strings(block.get("basis")) + strings(block.get("manuscript_basis"))
        if labels:
            objects: list[str] = []
            tests: list[str] = []

            def collect(value: Any) -> None:
                if isinstance(value, dict):
                    objects.extend(strings(value.get("object")))
                    objects.extend(strings(value.get("objects")))
                    tests.extend(strings(value.get("test")))
                    tests.extend(strings(value.get("tests")))
                    for child in value.values():
                        collect(child)
                elif isinstance(value, list):
                    for child in value:
                        collect(child)

            collect(block)
            add_mapping(mapping, labels, objects, tests, MAP_FILES[2])

    validation = yaml.safe_load((ROOT / MAP_FILES[3]).read_text())
    for item in validation.get("entries", []):
        labels = strings(item.get("manuscript_reduction"))
        objects = strings(item.get("moose_objects_required"))
        tests = strings(item.get("input_deck"))
        add_mapping(mapping, labels, objects, tests, MAP_FILES[3])

    mms = yaml.safe_load((ROOT / MAP_FILES[4]).read_text())
    for item in mms.get("cases", []):
        labels = strings(item.get("governing_equations"))
        tests = []
        for dimension in item.get("dimensions", []):
            if isinstance(dimension, dict):
                tests.extend(strings(dimension.get("input_deck")))
        add_mapping(mapping, labels, [], tests, MAP_FILES[4])
    for label, tests in DIRECT_TEST_MAPPINGS.items():
        add_mapping(mapping, [label], [], tests, "durable_test_path_review")
    return mapping


def clean_object(value: str) -> str:
    return re.split(r"\s+(?:for|retained|with|is|when)\s+", value, maxsplit=1)[0].strip()


def build() -> dict[str, Any]:
    paths = included_tex(ROOT)
    records = equation_labels(paths)
    mapping = structured_mappings()
    labels_seen = [record["label"] for record in records]
    duplicates = sorted(label for label, count in Counter(labels_seen).items() if count > 1)

    equations = []
    for record in records:
        category, reason = classification(record)
        mapped = mapping.get(record["label"], {"objects": set(), "tests": set(), "evidence": set()})
        equivalent_to = EQUIVALENT_LABELS.get(record["label"])
        if equivalent_to:
            equivalent = mapping.get(equivalent_to, {"objects": set(), "tests": set(), "evidence": set()})
            mapped = {
                "objects": set(mapped["objects"]) | set(equivalent["objects"]),
                "tests": set(mapped["tests"]) | set(equivalent["tests"]),
                "evidence": set(mapped["evidence"]) | set(equivalent["evidence"]) | {"reviewed_equation_equivalence"},
            }
        objects = sorted({clean_object(value) for value in mapped["objects"] if clean_object(value)})
        tests = sorted(set(mapped["tests"]))
        if category == "excluded_fracture":
            disposition = "excluded_by_scope"
        elif record["label"] in DERIVED_RUNTIME_CONSTRAINTS:
            disposition = "derived_from_conserved_component_equations"
        elif equivalent_to and (objects or tests):
            disposition = "implemented_via_equivalent_equation"
        elif objects and tests:
            disposition = "implemented_and_test_mapped"
        elif objects:
            disposition = "implemented_object_mapped"
        elif tests:
            disposition = "verification_mapped_without_object"
        elif category == "runtime_operator":
            disposition = "runtime_coverage_gap"
        elif category == "constitutive_algebraic_relation":
            disposition = "constitutive_coverage_gap"
        else:
            disposition = "no_independent_runtime_object_required"
        equations.append(
            {
                **record,
                "classification": category,
                "classification_basis": reason,
                "disposition": disposition,
                "equivalent_to": equivalent_to,
                "derived_constraint_basis": DERIVED_RUNTIME_CONSTRAINTS.get(record["label"]),
                "mapped_objects": objects,
                "mapped_tests": tests,
                "mapping_sources": sorted(mapped["evidence"]),
            }
        )

    class_counts = Counter(item["classification"] for item in equations)
    disposition_counts = Counter(item["disposition"] for item in equations)
    gaps = [
        {
            "label": item["label"],
            "source": item["source"],
            "line": item["line"],
            "classification": item["classification"],
            "gap": item["disposition"],
        }
        for item in equations
        if item["disposition"] in {"runtime_coverage_gap", "constitutive_coverage_gap"}
    ]
    included = [path.relative_to(ROOT).as_posix() for path in paths]
    source_hashes = {relative: sha256(ROOT / relative) for relative in included}
    composite = hashlib.sha256(
        b"".join((ROOT / relative).read_bytes() for relative in included)
    ).hexdigest()
    nonincluded = sorted(
        path.relative_to(ROOT).as_posix()
        for path in (ROOT / "sections").glob("*.tex")
        if path.resolve() not in paths
    )
    return {
        "schema_version": 1,
        "scope": {
            "canonical_root": "main.tex",
            "included_tex_files": included,
            "nonincluded_section_files": nonincluded,
            "equation_label_prefix": "eq:",
            "equation_count": len(equations),
            "duplicate_equation_labels": duplicates,
            "fracture_policy": "excluded; no fracture-labeled equation is present in the current include graph",
            "classification_categories": [
                "runtime_operator",
                "constitutive_algebraic_relation",
                "definition_kinematic_identity",
                "derivation_only",
                "comparison_reduction",
                "excluded_fracture",
            ],
        },
        "manuscript_checkpoint": {
            "composite_sha256": composite,
            "source_sha256": source_hashes,
        },
        "mapping_inputs": MAP_FILES,
        "summary": {
            "classification_counts": dict(sorted(class_counts.items())),
            "disposition_counts": dict(sorted(disposition_counts.items())),
            "coverage_gap_count": len(gaps),
            "interpretation": (
                "A coverage gap means that the current structured maps do not associate the equation with an object "
                "or test. It is a documentation/implementation-review flag, not by itself proof that source code is absent."
            ),
        },
        "coverage_gaps": gaps,
        "equations": equations,
    }


if __name__ == "__main__":
    OUTPUT.write_text(
        "# Generated by moose_app/doc/build_manuscript_equation_audit.py; do not hand edit.\n"
        + yaml.safe_dump(build(), sort_keys=False, width=120)
    )
