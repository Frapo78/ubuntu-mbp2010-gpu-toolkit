#!/usr/bin/env python3
"""Repository consistency checks using only the Python standard library."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ALLOWED_STATUS = {"stable", "proven", "experimental", "rejected", "planned"}
ALLOWED_RISK = {"low", "medium", "high"}


def load_json(path: Path):
    with path.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def test_cases():
    path = ROOT / "knowledge" / "cases.json"
    data = load_json(path)
    assert data["schema_version"]
    cases = data["cases"]
    assert cases, "knowledge/cases.json must contain at least one case"

    ids = [case["id"] for case in cases]
    assert len(ids) == len(set(ids)), "case IDs must be unique"

    for case in cases:
        for required in ("id", "title", "status", "risk", "diagnosis", "docs"):
            assert required in case, f"{case.get('id')}: missing {required}"
        assert case["status"] in ALLOWED_STATUS, (
            f"{case['id']}: unsupported status {case['status']}"
        )
        assert case["risk"] in ALLOWED_RISK, (
            f"{case['id']}: invalid risk {case['risk']}"
        )
        for doc in case["docs"]:
            target = ROOT / doc
            assert target.exists(), f"{case['id']}: referenced path does not exist: {doc}"


def test_integration_cases():
    path = ROOT / "knowledge" / "integration-cases.json"
    data = load_json(path)
    assert data["schema_version"] == 1
    cases = data["cases"]
    assert cases, "integration-cases.json must contain cases"

    ids = [case["id"] for case in cases]
    assert len(ids) == len(set(ids)), "integration case IDs must be unique"

    for case in cases:
        for required in ("id", "title", "status", "risk", "symptoms", "evidence", "safe_direction"):
            assert required in case, f"{case.get('id')}: missing {required}"
        assert case["status"] in ALLOWED_STATUS
        assert case["risk"] in ALLOWED_RISK
        assert case["symptoms"]
        assert case["evidence"]
        assert case["safe_direction"]


def test_evidence():
    data = load_json(ROOT / "knowledge" / "evidence.json")
    evidence = data["evidence"]
    ids = [item["id"] for item in evidence]
    assert len(ids) == len(set(ids)), "evidence IDs must be unique"
    for item in evidence:
        assert item["claim"]
        assert item["source_artifact"]
        assert item["key_signals"]


def test_profiles():
    profiles = list((ROOT / "profiles").glob("*.json"))
    assert profiles, "at least one hardware profile is required"
    for path in profiles:
        data = load_json(path)
        assert data["model"] == path.stem, (
            f"profile filename {path.stem} must match model {data['model']}"
        )
        assert data["support_level"]
        assert data["graphics"]["integrated"]["pci_address"]
        assert data["graphics"]["discrete"]["pci_address"]
        assert data["graphics"]["mux"]["control"]


def test_required_docs():
    required = [
        "AGENTS.md",
        "README.md",
        "docs/quick-triage.md",
        "docs/decision-tree.md",
        "docs/runbook.md",
        "docs/safety.md",
        "docs/status-model.md",
        "docs/support-matrix.md",
        "docs/package-architecture.md",
        "docs/failed-experiments.md",
        "docs/hardware-integration.md",
        "docs/offline-rescue.md",
        "packages/README.md",
        "packages/manifests/noble-amd64.json",
        "scripts/integration-probe.sh",
        "scripts/offline/prepare-bundle.sh",
        "scripts/offline/verify-bundle.sh",
        "scripts/offline/install-bundle.sh",
    ]
    for item in required:
        assert (ROOT / item).exists(), f"required repository entrypoint missing: {item}"


def main():
    tests = [
        test_cases,
        test_integration_cases,
        test_evidence,
        test_profiles,
        test_required_docs,
    ]
    failures = []
    for test in tests:
        try:
            test()
            print(f"PASS {test.__name__}")
        except Exception as exc:  # simple zero-dependency test runner
            failures.append((test.__name__, exc))
            print(f"FAIL {test.__name__}: {exc}")

    if failures:
        raise SystemExit(1)

    print("Repository knowledge/profile checks passed.")


if __name__ == "__main__":
    main()
