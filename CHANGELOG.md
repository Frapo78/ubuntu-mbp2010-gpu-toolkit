# Changelog

This project is pre-release. Entries track repository/toolkit maturity rather than Ubuntu package versions.

## Unreleased

### Planned

- persistent boot-safe Intel-primary + NVIDIA PRIME configuration;
- checkpoint/rollback action framework;
- NVIDIA runtime power-management validation;
- GNOME/switcheroo-control dedicated-GPU UX;
- unified human/agent CLI;
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
