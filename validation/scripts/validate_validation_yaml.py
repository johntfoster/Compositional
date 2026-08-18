#!/usr/bin/env python3
"""Validate repository YAML files used for code traceability and validation."""

from pathlib import Path
import re
import sys

import yaml


ROOT = Path(__file__).resolve().parents[2]
YAML_FILES = [
    "moose_app/doc/theory_traceability.yml",
    "implementation_paper/equation_to_moose_map.yml",
    "validation/validation_matrix.yml",
    "validation/mms_inventory.yml",
    "validation/spe_benchmark_inventory.yml",
    "validation/reports/report_inventory.yml",
    "validation/code_only_acceptance_audit.yml",
    "validation/reference_data/spe2_candidate_gates.yml",
    "moose_app/input/fragment_catalog.yml",
    "moose_app/input/verified_block_registry.yml",
]


def validate_spe_report_inventory(document: dict) -> str | None:
    """Require one existing, uniquely indexed report per SPE problem family."""
    benchmark_path = ROOT / "validation/spe_benchmark_inventory.yml"
    with benchmark_path.open("r", encoding="utf-8") as stream:
        benchmark_document = yaml.safe_load(stream)
    expected_ids = {
        problem.get("id") for problem in benchmark_document.get("problem_families", [])
    }
    if None in expected_ids or not expected_ids:
        return "validation/spe_benchmark_inventory.yml: problem family missing id"

    reports = document.get("reports")
    if not isinstance(reports, list) or not reports:
        return "validation/reports/report_inventory.yml: reports must be a nonempty list"
    report_ids = [report.get("benchmark_id") for report in reports]
    if len(report_ids) != len(set(report_ids)):
        return "validation/reports/report_inventory.yml: duplicate benchmark_id"
    if set(report_ids) != expected_ids:
        missing = sorted(expected_ids - set(report_ids))
        extra = sorted(set(report_ids) - expected_ids)
        return (
            "validation/reports/report_inventory.yml: report coverage mismatch; "
            f"missing={missing}, extra={extra}"
        )
    contract = document.get("report_contract")
    if not isinstance(contract, dict) or contract.get("version") != 2:
        return "validation/reports/report_inventory.yml: report_contract version must be 2"
    required_headings = contract.get("required_headings")
    if not isinstance(required_headings, list) or not required_headings:
        return "validation/reports/report_inventory.yml: missing required report headings"
    if len(required_headings) != len(set(required_headings)):
        return "validation/reports/report_inventory.yml: duplicate required report heading"
    evidence_states = set(contract.get("evidence_states", []))
    if evidence_states != {"run_evidence", "candidate_evidence", "none", "deferred"}:
        return "validation/reports/report_inventory.yml: invalid evidence-state contract"
    status_markers = contract.get("status_markers_by_evidence")
    if not isinstance(status_markers, dict) or set(status_markers) != evidence_states:
        return "validation/reports/report_inventory.yml: invalid evidence marker contract"
    for report in reports:
        relative_path = report.get("path")
        if not isinstance(relative_path, str) or not relative_path:
            return (
                "validation/reports/report_inventory.yml: report "
                f"{report.get('benchmark_id')} is missing path"
            )
        if not (ROOT / relative_path).is_file():
            return f"validation/reports/report_inventory.yml: missing report {relative_path}"
        if not report.get("status"):
            return (
                "validation/reports/report_inventory.yml: report "
                f"{report.get('benchmark_id')} is missing status"
            )
        evidence_state = report.get("evidence_state")
        if evidence_state not in evidence_states:
            return (
                "validation/reports/report_inventory.yml: report "
                f"{report.get('benchmark_id')} has invalid evidence_state {evidence_state!r}"
            )
        horizon_status = report.get("official_horizon_status")
        if horizon_status not in {"pass", "pending", "failed", "deferred"}:
            return (
                "validation/reports/report_inventory.yml: report "
                f"{report.get('benchmark_id')} has invalid official_horizon_status"
            )
        if evidence_state == "deferred" and horizon_status != "deferred":
            return (
                "validation/reports/report_inventory.yml: deferred report "
                f"{report.get('benchmark_id')} must defer its official horizon"
            )
        report_path = ROOT / relative_path
        report_text = report_path.read_text(encoding="utf-8")
        section_matches = list(re.finditer(r"^## ([^\n]+)$", report_text, re.MULTILINE))
        sections = {match.group(1): match for match in section_matches}
        missing_headings = [heading for heading in required_headings if heading not in sections]
        if missing_headings:
            return f"{relative_path}: missing required sections {missing_headings}"
        section_bodies = {}
        for heading in required_headings:
            match = sections[heading]
            later_offsets = [item.start() for item in section_matches if item.start() > match.start()]
            end = min(later_offsets) if later_offsets else len(report_text)
            body = report_text[match.end():end].strip()
            section_bodies[heading] = body
            if len(body) < 20:
                return f"{relative_path}: section {heading!r} lacks benchmark-specific content"

        expected_markers = status_markers[evidence_state]
        marker_sections = {
            "deck_status": "Deck provenance and CG/EG spaces",
            "command_status": "Reproduction commands and artifacts",
            "source_data_status": "Plots and source-data provenance",
        }
        for marker, section in marker_sections.items():
            expected = f"`{marker}: {expected_markers[marker]}`"
            if expected not in section_bodies[section]:
                return f"{relative_path}: {section} must contain {expected}"
        expected_horizon = f"`official_horizon_status: {horizon_status}`"
        if expected_horizon not in section_bodies["Official reference comparison"]:
            return (
                f"{relative_path}: Official reference comparison must contain "
                f"{expected_horizon}"
            )

        image_targets = re.findall(r"!\[[^\]]*\]\(([^)]+)\)", report_text)
        if evidence_state != "run_evidence" and image_targets:
            return (
                f"{relative_path}: {evidence_state} report may not link generated plot artifacts"
            )

        status = str(report.get("status", "")).lower()
        accepted = status.startswith("pass") or status.startswith("verified")
        if accepted:
            if not image_targets:
                return f"{relative_path}: accepted report contains no plot links"
            for target in image_targets:
                target_path = target.split("#", 1)[0]
                if "://" in target_path:
                    continue
                if not (report_path.parent / target_path).resolve().is_file():
                    return f"{relative_path}: missing linked plot {target}"

            reproducibility_terms = ("command", "solver log", "artifact")
            missing_terms = [term for term in reproducibility_terms if term not in report_text.lower()]
            if missing_terms:
                return (
                    f"{relative_path}: accepted report missing reproducibility evidence "
                    f"{missing_terms}"
                )
    return None


def validate_mms_inventory(document: dict) -> str | None:
    """Return an error for an internally contradictory MMS inventory."""
    cases = document.get("cases")
    if not isinstance(cases, list) or not cases:
        return "validation/mms_inventory.yml: cases must be a nonempty list"

    acceptance_gaps = []
    for case in cases:
        case_id = case.get("id", "<missing id>")
        acceptance_gap = case.get("acceptance_gap")
        if not isinstance(acceptance_gap, bool):
            return (
                "validation/mms_inventory.yml: "
                f"case {case_id} acceptance_gap must be true or false"
            )
        acceptance_gaps.append(acceptance_gap)
        if not acceptance_gap:
            for dimension in case.get("dimensions", []):
                status = str(dimension.get("status", "")).lower()
                if "gap_open" in status or "gaps_open" in status:
                    return (
                        "validation/mms_inventory.yml: closed case "
                        f"{case_id} has open-gap dimension status "
                        f"{dimension.get('dimension', '<missing dimension>')}: {status}"
                    )

    expected_status = "partial" if any(acceptance_gaps) else "verified"
    actual_status = document.get("global_acceptance_status")
    if actual_status != expected_status:
        return (
            "validation/mms_inventory.yml: global_acceptance_status must be "
            f"{expected_status!r} when acceptance_gap values are "
            f"{'open' if any(acceptance_gaps) else 'all false'}; got {actual_status!r}"
        )

    blockers = document.get("global_acceptance_blockers")
    if not isinstance(blockers, list):
        return "validation/mms_inventory.yml: global_acceptance_blockers must be a list"
    if any(acceptance_gaps) and not blockers:
        return (
            "validation/mms_inventory.yml: partial MMS acceptance requires at least "
            "one global_acceptance_blocker"
        )
    if not any(acceptance_gaps) and blockers:
        return (
            "validation/mms_inventory.yml: a verified MMS inventory cannot retain "
            "global_acceptance_blockers"
        )
    return None


def main() -> int:
    for relative in YAML_FILES:
        path = ROOT / relative
        with path.open("r", encoding="utf-8") as stream:
            document = yaml.safe_load(stream)
        if not isinstance(document, dict):
            print(f"{relative}: expected a YAML mapping at top level", file=sys.stderr)
            return 1
        if "schema_version" not in document:
            print(f"{relative}: missing schema_version", file=sys.stderr)
            return 1
        if relative == "validation/mms_inventory.yml":
            error = validate_mms_inventory(document)
            if error:
                print(error, file=sys.stderr)
                return 1
        if relative == "validation/reports/report_inventory.yml":
            error = validate_spe_report_inventory(document)
            if error:
                print(error, file=sys.stderr)
                return 1
        if relative == "validation/reference_data/spe2_candidate_gates.yml":
            if document.get("claim_level") != "candidate_only":
                print(f"{relative}: claim_level must remain candidate_only", file=sys.stderr)
                return 1
            if document.get("production_claim_allowed") is not False:
                print(f"{relative}: production claims must remain disabled", file=sys.stderr)
                return 1
            required_blocks = document.get("required_candidate_blocks", [])
            if len(required_blocks) != 11 or len(required_blocks) != len(set(required_blocks)):
                print(f"{relative}: expected eleven unique SPE2 candidate blocks", file=sys.stderr)
                return 1
        if relative == "moose_app/input/fragment_catalog.yml":
            include_root = ROOT / document.get("include_root", "")
            fragment_ids = set()
            for fragment in document.get("fragments", []):
                fragment_id = fragment.get("id", "")
                if not fragment_id:
                    print(f"{relative}: fragment missing id", file=sys.stderr)
                    return 1
                if fragment_id in fragment_ids:
                    print(f"{relative}: duplicate fragment id {fragment_id}", file=sys.stderr)
                    return 1
                fragment_ids.add(fragment_id)
                fragment_path = include_root / fragment.get("path", "")
                if not fragment_path.exists():
                    print(f"{relative}: missing fragment {fragment_path}", file=sys.stderr)
                    return 1
                provides = " ".join(fragment.get("provides", []))
                if fragment.get("dimension") == 3 and "HEX27" in provides:
                    print(
                        f"{relative}: 3D HEX27 fragment {fragment_id} is unsupported for "
                        "coupled Q2+EG in this build",
                        file=sys.stderr,
                    )
                    return 1
            mechanics_rules = document.get("rules", {}).get("coupled_solid_mechanics", {})
            required_meshes = mechanics_rules.get("required_mesh_elements", {})
            if "TET10" not in str(required_meshes.get(3, "")):
                print(f"{relative}: dimension 3 must require TET10 for this build", file=sys.stderr)
                return 1
            unsupported = mechanics_rules.get("unsupported_local_dof_combinations", [])
            if not any(
                item.get("dimension") == 3
                and item.get("mesh_element") == "HEX27"
                and "reject" in item.get("policy", "")
                for item in unsupported
            ):
                print(
                    f"{relative}: missing reject policy for 3D HEX27 coupled Q2+EG",
                    file=sys.stderr,
                )
                return 1
        print(f"OK {relative}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
