#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFESTS = sorted((ROOT / "packages" / "manifests").glob("*.json"))
ALLOWED_STATUS = {"stable", "proven", "experimental", "rejected", "planned"}
ALLOWED_CLASS = {
    "runtime", "diagnostics", "integration", "repair", "conditional_driver",
    "optional_ui", "experimental_policy"
}

assert MANIFESTS, "no package manifests found"

for path in MANIFESTS:
    data = json.loads(path.read_text())
    assert data["schema_version"] == 1
    assert data["suite"]
    assert data["architecture"]
    assert isinstance(data.get("sets"), dict) and data["sets"]
    assert isinstance(data.get("bundle_profiles"), dict)

    for name, package_set in data["sets"].items():
        status = package_set.get("status")
        klass = package_set.get("class")
        packages = package_set.get("packages")

        assert status in ALLOWED_STATUS, f"{path}:{name}: invalid status {status}"
        assert klass in ALLOWED_CLASS, f"{path}:{name}: invalid class {klass}"
        assert isinstance(packages, list) and packages, f"{path}:{name}: empty packages"
        assert len(packages) == len(set(packages)), f"{path}:{name}: duplicate package"

        if package_set.get("auto_install"):
            assert status in {"stable", "proven"}, (
                f"{path}:{name}: auto_install cannot be {status}"
            )
            assert klass not in {"repair", "conditional_driver", "experimental_policy"}, (
                f"{path}:{name}: non-default class cannot auto-install"
            )

        if klass == "repair":
            assert package_set.get("auto_install") is False, (
                f"{path}:{name}: repair sets must be explicit"
            )
            assert status in {"stable", "proven"}, (
                f"{path}:{name}: repair set must use validated packages"
            )

    for profile, set_names in data["bundle_profiles"].items():
        assert set_names, f"{path}:{profile}: empty bundle profile"
        for name in set_names:
            assert name in data["sets"], f"{path}:{profile}: unknown set {name}"

    sets = data["sets"]
    if "wifi_b43_tools" in sets:
        b43 = sets["wifi_b43_tools"]
        assert b43.get("auto_install") is False
        assert b43.get("class") == "conditional_driver"
        assert "firmware-b43-installer" in b43["packages"]

    if "wifi_broadcom_sta" in sets:
        sta = sets["wifi_broadcom_sta"]
        assert sta.get("auto_install") is False
        assert sta.get("class") == "conditional_driver"
        assert any("@KERNEL@" in p for p in sta["packages"]), (
            "Broadcom STA bundle must carry matching kernel headers"
        )

    if "apple_fan_daemons" in sets:
        fan = sets["apple_fan_daemons"]
        assert fan.get("auto_install") is False
        assert fan.get("status") == "experimental"

print(f"validated {len(MANIFESTS)} package manifest(s)")
