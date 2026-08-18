# Project charter

## Mission

Turn a real MacBookPro6,2 Ubuntu recovery and graphics-engineering effort into a reusable, evidence-based toolkit that can help other owners install, diagnose, repair and operate modern Ubuntu reliably on similar 2010 MacBook Pro hardware.

The repository is not intended to become a loose collection of shell snippets. The target is a structured compatibility package with documented assumptions, diagnostics, rollback paths and progressively automated remediation.

## Final goal

Provide a package that can, as safely and automatically as the platform allows:

1. detect supported MacBook Pro hardware and graphics topology;
2. inspect OpenCore/EFI, kernel, Xorg/Wayland, DRM, gmux, `vga_switcheroo`, Mesa and `switcheroo-control` state;
3. identify known failure modes;
4. recommend or apply the correct remediation path;
5. create recovery checkpoints before boot-critical changes;
6. configure a stable graphical baseline;
7. make Intel the normal low-power desktop/rendering path;
8. keep the NVIDIA GPU available for explicit or GUI-driven on-demand rendering;
9. manage the discrete GPU's power state automatically where Linux and the hardware permit it;
10. integrate naturally with GNOME, ideally including “Launch using Dedicated Graphics Card” semantics;
11. verify the resulting configuration after reboot;
12. package the stable solution for repeatable installation on other compatible machines.

## Desired end-state

The long-term user experience should approximate macOS hybrid graphics behavior while remaining transparent and Linux-native:

```text
Normal desktop / browser / office workload
                |
                v
        Intel i915 / Crocus
                |
                +---- internal display / GNOME

GPU-heavy application
                |
                v
       NVIDIA PRIME offload
                |
                +---- render workload only

Idle discrete GPU
                |
                v
        runtime power saving
```

The implementation must not pretend the machine has capabilities that Linux or the firmware do not actually provide. Where native GNOME/switcheroo behavior cannot express the desired policy, a small explicit manager may be built instead.

## Engineering principles

### Evidence before modification

Every persistent change should be justified by a reproducible diagnostic result.

### One risky variable at a time

Do not combine independent boot-critical experiments in a single reboot.

### Rollback is part of the feature

A change is not considered ready until its failure and recovery path are documented and, where possible, automated.

### Proven failures stay documented

Rejected approaches are preserved so future contributors do not repeat unsafe or unproductive experiments.

### Stable and experimental paths stay separate

- `scripts/` contains conservative supported tooling.
- `scripts/experimental/` contains model-specific or research-grade actions.
- Experimental behavior must never silently become part of the quickstart.

### No unsupported legacy-driver shortcuts

The project will not rely on NVIDIA 340 or GPU overclocking to mask architectural problems.

## Repository maintenance policy

As development progresses, the repository should be updated in parallel with the investigation.

For each meaningful step, update the relevant combination of:

- `docs/investigation-timeline.md`
- `docs/findings.md`
- `docs/failed-experiments.md`
- `docs/reference-checkpoint.md`
- `docs/resume-point.md`
- `docs/roadmap.md`
- diagnostic scripts
- remediation / rollback scripts
- packaging or application code

A result discovered only in a conversation and not transferred into the repository is considered incomplete project work.

## Planned product layers

### Layer 1 — diagnostics

Read-only hardware and software inventory with redacted, shareable reports.

### Layer 2 — compatibility assessment

Rules that classify the machine into known-good, known-risk or unsupported configurations.

### Layer 3 — remediation

Safe scripts for X11/Wayland state, duplicate panel handling, OpenCore validation, GPU routing and other proven fixes.

### Layer 4 — stable hybrid graphics

Persistent Intel-primary display/rendering with NVIDIA PRIME available on demand.

### Layer 5 — power policy

Automatic dGPU suspend/resume where driver and Xorg ownership make it feasible.

### Layer 6 — user-facing control

GNOME integration or a GTK4/libadwaita manager for GPU status and dedicated-GPU launching if native desktop integration is insufficient.

### Layer 7 — installer/package

A reproducible installer or Debian package that detects compatibility, creates backups, applies the stable configuration and performs a post-install validation.

## Definition of success

The project reaches its primary goal when a compatible MacBook Pro can go from a clean modern Ubuntu installation to a documented stable configuration using the toolkit, with:

- no recurring graphics freezes in the supported desktop path;
- a correct single internal display layout;
- Intel hardware acceleration for normal use;
- NVIDIA hardware acceleration available on demand;
- no unsupported proprietary legacy driver dependency;
- predictable reboot, suspend and resume behavior;
- recoverable configuration changes;
- a shareable diagnostic report when something differs from the reference machine.
