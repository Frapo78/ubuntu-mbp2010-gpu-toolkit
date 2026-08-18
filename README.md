# Ubuntu MacBook Pro 2010 Compatibility & GPU Toolkit

A reproducible troubleshooting, recovery and compatibility toolkit for running modern Ubuntu on the **MacBook Pro 15-inch Mid 2010 (`MacBookPro6,2`)**, with a primary focus on its unusual muxed dual-GPU architecture:

- Intel Ironlake / Arrandale integrated graphics (`i915`, Mesa Crocus)
- NVIDIA GeForce GT 330M / GT216M (`nouveau`)
- Apple `gmux`
- `vga_switcheroo`
- `switcheroo-control`
- OpenCore as boot manager

The project grew from a real Ubuntu 24.04 troubleshooting session and is being converted into a structured package that can help **humans and troubleshooting agents** diagnose, recover, fix and eventually automate similar installations.

> **Status: early alpha / active engineering.** Diagnostics and several core findings are already useful. The final automatic hybrid-GPU configuration is not yet declared stable.

## What this project is trying to become

The end goal is a package that can safely move a compatible installation through:

```text
DETECT -> DIAGNOSE -> CLASSIFY -> CHECKPOINT -> FIX -> REBOOT -> POSTCHECK
```

and ultimately provide a Linux experience close to macOS hybrid graphics:

1. **Intel by default** for desktop, browser and normal workloads.
2. **NVIDIA on demand** for workloads that benefit from the discrete GPU.
3. GNOME-friendly dedicated-GPU launching or a small explicit GUI if native semantics are insufficient.
4. Automatic dGPU power saving where Linux and the hardware actually support it.
5. Recovery checkpoints and rollback as first-class features.
6. No unsupported legacy-driver hacks.

See [`docs/project-charter.md`](docs/project-charter.md) and [`docs/package-architecture.md`](docs/package-architecture.md).

---

# Start here

## I am a human with a problem

If Ubuntu is usable, start with the non-destructive classifier:

```bash
chmod +x scripts/quick-triage.sh
./scripts/quick-triage.sh
```

Then collect a fuller report:

```bash
chmod +x scripts/collect-diagnostics.sh
./scripts/collect-diagnostics.sh
```

Read:

1. [`docs/quick-triage.md`](docs/quick-triage.md)
2. [`docs/decision-tree.md`](docs/decision-tree.md)
3. [`docs/runbook.md`](docs/runbook.md)

If the problem is still unknown, open a **Diagnostic / compatibility problem** issue. The issue form asks for the evidence maintainers need instead of forcing a long question-and-answer cycle.

## I am an AI/troubleshooting agent

Read [`AGENTS.md`](AGENTS.md) first.

Then use:

- [`profiles/MacBookPro6,2.json`](profiles/MacBookPro6,2.json) — machine-readable hardware/reference profile
- [`knowledge/cases.json`](knowledge/cases.json) — symptom/evidence/diagnosis/action knowledge base
- [`knowledge/evidence.json`](knowledge/evidence.json) — ledger of reproduced conclusions
- [`docs/status-model.md`](docs/status-model.md) — stable/proven/experimental/rejected/planned semantics

Agents should **classify before modifying**, prefer machine evidence over assumptions, and update reusable repository knowledge when a troubleshooting cycle produces a new finding.

---

# Current proven baseline

Reference machine:

- `MacBookPro6,2`
- Ubuntu 24.04.4 LTS
- X11 session
- Linux 7.0 Ubuntu kernel
- OpenCore 1.0.7
- Intel `i915` + Crocus
- NVIDIA `nouveau`
- classic `apple_gmux`
- `switcheroo-control` 2.6

See the exact scope in [`docs/support-matrix.md`](docs/support-matrix.md).

## Proven working

- Both GPUs load under X11.
- Intel Mesa/Crocus direct hardware acceleration works.
- `vga_switcheroo` and Apple gmux are functional.
- The physical internal display can be routed to Intel.
- Xorg can run Intel as the primary GPU.
- NVIDIA PRIME render offload works while Intel is primary.
- OpenCore 1.0.7 boots Ubuntu successfully after a staged/validated upgrade.

The most important result is that the desired rendering architecture — **Intel primary + NVIDIA on demand** — has already been demonstrated. The remaining engineering work is persistence, boot ordering, GNOME policy and dGPU power management.

## Known problematic paths

- GNOME Wayland + this dual-GPU topology can hard-freeze the reference machine.
- Nouveau on the GT 330M can emit `DATA_ERROR [INVALID_VALUE]`, notably with Chromium.
- Nouveau video-decode firmware `nva5_fuc084*` is missing in the tested standard setup.
- NVIDIA-primary Xorg can expose the same internal panel twice and create a false `2880x900` desktop.
- `switcheroo-control` follows the firmware `boot_vga` state and currently calls NVIDIA the default GPU.
- Runtime creation of Apple's `gpu-power-prefs` EFI variable is rejected with `EINVAL` on the reference machine.

See [`docs/findings.md`](docs/findings.md) and [`docs/failed-experiments.md`](docs/failed-experiments.md).

---

# Hard safety rules

Do **not** treat these as fixes for the reference Mac on modern Ubuntu:

- NVIDIA 340
- permanent `nomodeset`
- Nouveau clock increases/overclocking
- blind retry loops for `gpu-power-prefs`
- Wayland multi-GPU as the stable baseline
- blind replacement of the complete existing OpenCore/OCLP EFI tree

Do not change gmux while graphical/DRM/audio clients still hold the affected devices unless a reviewed experiment explicitly handles those holders.

Read [`docs/safety.md`](docs/safety.md) before experimental work.

---

# Repository map

## Human and agent entrypoints

- [`AGENTS.md`](AGENTS.md) — mandatory protocol for troubleshooting agents
- [`docs/quick-triage.md`](docs/quick-triage.md) — symptom-first diagnosis
- [`docs/decision-tree.md`](docs/decision-tree.md) — minimal-risk diagnostic branching
- [`docs/runbook.md`](docs/runbook.md) — full diagnose/fix/postcheck workflow
- [`docs/reporting.md`](docs/reporting.md) — evidence capture and public-log redaction

## Architecture and evidence

- [`docs/architecture.md`](docs/architecture.md) — graphics stack and topology
- [`docs/findings.md`](docs/findings.md) — evidence-backed conclusions
- [`docs/investigation-timeline.md`](docs/investigation-timeline.md) — complete engineering chronology
- [`knowledge/evidence.json`](knowledge/evidence.json) — machine-readable evidence ledger
- [`docs/reference-checkpoint.md`](docs/reference-checkpoint.md) — last known-good reference state

## Compatibility and support

- [`docs/support-matrix.md`](docs/support-matrix.md) — what hardware/software is actually covered
- [`profiles/MacBookPro6,2.json`](profiles/MacBookPro6,2.json) — reference hardware profile
- [`docs/system-baseline.md`](docs/system-baseline.md) — non-GPU Ubuntu findings from the reference machine

## Safety and rejected paths

- [`docs/status-model.md`](docs/status-model.md) — maturity definitions
- [`docs/safety.md`](docs/safety.md) — safety rules
- [`SECURITY.md`](SECURITY.md) — recovery expectations
- [`docs/failed-experiments.md`](docs/failed-experiments.md) — tested/researched approaches that should not be repeated
- [`docs/opencore.md`](docs/opencore.md) — staged OpenCore update methodology

## Development direction

- [`docs/project-charter.md`](docs/project-charter.md) — mission and final goal
- [`docs/package-architecture.md`](docs/package-architecture.md) — target toolkit/CLI/action architecture
- [`docs/roadmap.md`](docs/roadmap.md) — implementation phases
- [`docs/resume-point.md`](docs/resume-point.md) — exact next engineering step

## Scripts

Stable/conservative:

- `scripts/quick-triage.sh`
- `scripts/collect-diagnostics.sh`
- `scripts/stabilize-known-good.sh`

Research-grade / explicit review required:

- `scripts/experimental/test-gmux-migd-mbp62.sh`
- `scripts/experimental/test-intel-primary-nvidia-offload-mbp62.sh`

---

# How fixes graduate

The repository uses a strict maturity sequence:

```text
planned -> experimental -> proven -> stable
```

Any path can become `rejected` when evidence shows it is unsafe, unsupported or unproductive.

A fix is not `stable` simply because it worked once. Persistence, rollback, reboot behaviour and postchecks must also be demonstrated.

---

# Current next goal

Do **not** revisit the already rejected EFI route.

The next engineering target is a **reversible, early-boot Intel display-routing + Intel-primary Xorg configuration** that:

- runs before GDM/Xorg clients acquire both GPUs;
- routes the internal panel to Intel safely;
- starts the desktop on Intel i915/Crocus;
- keeps NVIDIA/Nouveau available for explicit PRIME rendering;
- avoids the duplicate LVDS layout;
- can be rolled back automatically;
- is followed by a full postcheck.

After that is proven, the project can tackle NVIDIA runtime suspend/resume and final GNOME/GUI automation.

---

# Contributing

Use the structured diagnostic issue form and attach a redacted report. See [`CONTRIBUTING.md`](CONTRIBUTING.md).

When contributing a fix, include its maturity status, supported hardware profile, preconditions, touched state, rollback and postcheck.

## License

MIT. Hardware and software names belong to their respective owners.
