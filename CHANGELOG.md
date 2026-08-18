# Changelog

This project is pre-release. Entries track repository/toolkit maturity rather than Ubuntu package versions.

## Unreleased

### Added

- whole-Mac integration scope beyond graphics: trackpad, keyboard/function keys, keyboard/display backlight, Wi-Fi, Bluetooth, audio, camera, battery/power, Apple SMC/fans, storage and optical drive;
- `scripts/integration-probe.sh` read-only integration report;
- `knowledge/integration-cases.json` machine-readable non-GPU troubleshooting cases;
- `docs/hardware-integration.md` subsystem guidance and package/driver boundaries;
- versioned Ubuntu 24.04 amd64 package manifest under `packages/manifests/`;
- offline USB rescue architecture and documentation;
- `scripts/offline/prepare-bundle.sh` online bundle builder;
- `scripts/offline/verify-bundle.sh` checksum/metadata verification;
- `scripts/offline/install-bundle.sh` temporary local-APT installer with conditional-driver gates;
- package-manifest CI validation;
- P0 offline-bundle validation issue;
- P0 reference non-GPU hardware inventory issue;
- P1 whole-Mac integration issue.

### Safety / architecture decisions

- raw `.deb` binaries are not committed to Git; generated USB bundles carry exact packages, dependency closure, metadata and SHA-256 sums;
- packages are separated by purpose (`runtime`, `diagnostics`, `conditional_driver`, etc.) and maturity (`stable`, `proven`, `experimental`, `rejected`, `planned`);
- conditional Broadcom/Bluetooth driver packages may be present in a full bundle without being automatically installed;
- experimental conditional drivers require explicit selection and `--allow-experimental`;
- Broadcom STA offline installation requires matching kernel headers;
- b43 offline repair is not considered complete unless a usable firmware payload has been captured separately; the project does not treat `firmware-b43-installer` alone as network-independent;
- `pommed`, `mbpfan` and `macfanctld` remain experimental policy tools, never default automatic integration packages.

### Planned

- persistent boot-safe Intel-primary + NVIDIA PRIME configuration;
- checkpoint/rollback action framework;
- validation of generated `minimal`, `rescue` and `full` USB bundles on an offline reference machine;
- inventory and validation of the reference Mac's exact non-GPU PCI/USB hardware IDs and driver paths;
- NVIDIA runtime power-management validation;
- GNOME/switcheroo-control dedicated-GPU UX;
- unified human/agent CLI;
- versioned GitHub Release rescue artifacts after the bundle format is stable;
- expansion to additional verified hardware profiles.

## 0.1.0-alpha — 2026-08-19

### Added

- complete MacBookPro6,2 investigation timeline;
- reference OpenCore 1.0.7 notes and checkpoint;
- evidence-backed findings and rejected experiments;
- human quick-triage and decision tree;
- agent operating protocol (`AGENTS.md`);
- machine-readable `knowledge/cases.json`;
- machine-readable evidence ledger;
- `MacBookPro6,2` hardware profile;
- support/maturity/source policies;
- privacy-aware diagnostic collector;
- non-destructive quick-triage classifier;
- conservative known-good stabilization/checkpoint script;
- successful reference experimental scripts for gmux/Intel-primary/NVIDIA PRIME;
- structured diagnostic GitHub issue form;
- repository validation tests and GitHub Actions workflow;
- P0/P1/P2 engineering backlog issues;
- human/agent handoff format;
- package architecture and final project charter.

### Established conclusions

- X11 is the current stable desktop baseline for the reference machine;
- Intel i915/Crocus acceleration works;
- Apple gmux switching works;
- Intel-primary Xorg works;
- NVIDIA PRIME offload works from Intel-primary;
- Wayland dual-GPU is rejected as the current stable path;
- NVIDIA 340, permanent `nomodeset`, Nouveau overclocking and blind `gpu-power-prefs` retries are rejected strategies;
- the next priority is persistent pre-GDM Intel display routing + Intel-primary Xorg with rollback.
