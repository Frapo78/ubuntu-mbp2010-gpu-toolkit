# Agent operating protocol

This repository is designed to be usable by both humans and autonomous/semi-autonomous troubleshooting agents.

## Mission

Reduce time-to-diagnosis and time-to-safe-fix for Ubuntu installations on MacBook Pro 2010 hardware, beginning with the fully investigated **MacBookPro6,2** reference machine.

The goal is not to maximize the number of tweaks applied. The goal is to reach a **known, evidence-backed, recoverable state** as quickly as possible.

## Read order for agents

Before proposing persistent changes, read in this order:

1. `docs/quick-triage.md`
2. `knowledge/cases.json`
3. `knowledge/integration-cases.json` when the symptom involves input, Wi-Fi, Bluetooth, audio, camera, power, thermal or storage integration
4. `docs/status-model.md`
5. `docs/safety.md`
6. the matching detailed document in `docs/`
7. `docs/failed-experiments.md`

For graphics work also read:

- `docs/architecture.md`
- `docs/findings.md`
- `docs/resume-point.md`

For whole-Mac integration or offline work also read:

- `docs/hardware-integration.md`
- `docs/offline-rescue.md`
- `packages/README.md`
- `packages/manifests/noble-amd64.json`

## First action on an unknown machine

Do not guess from the user's description alone.

For graphics/boot/system issues collect:

```bash
chmod +x scripts/collect-diagnostics.sh
./scripts/collect-diagnostics.sh
```

For MacBook integration issues collect:

```bash
chmod +x scripts/integration-probe.sh
./scripts/integration-probe.sh
```

Then classify the machine and symptom using the relevant knowledge JSON.

## Offline-first rule when networking is broken

If the affected Mac has no working Internet connection, do not make the user restore networking merely to obtain diagnostic tools.

If an offline toolkit bundle is available:

1. verify it with `scripts/offline/verify-bundle.sh`;
2. run `scripts/offline/install-bundle.sh <bundle> --dry-run`;
3. install only stable auto-install sets by default;
4. treat Wi-Fi/Bluetooth driver sets as conditional and experimental until hardware evidence selects them;
5. require explicit `--set ... --allow-experimental` for reviewed conditional-driver installation;
6. never install both Broadcom driver paths just because both are available in the bundle.

A package being present in a USB rescue bundle is **not evidence that the package is the correct fix**.

## Evidence hierarchy

Prefer, in order:

1. direct evidence from the current machine;
2. a result marked `proven` in this repository for the same model/topology;
3. official kernel, Ubuntu, Mesa, GNOME, OpenCore or upstream project documentation;
4. a clearly labelled inference;
5. an experiment only when the safer layers cannot answer the question.

Do not silently promote inference or a one-machine observation into a general fix.

## Status vocabulary

Every recommendation must map to one of the statuses defined in `docs/status-model.md`:

- `stable`
- `proven`
- `experimental`
- `rejected`
- `planned`

If the status is unknown, treat the action as `experimental`.

Package manifests use a separate `class` field (`runtime`, `diagnostics`, `conditional_driver`, etc.) so that package purpose is never confused with maturity.

## Safety contract

Before any boot-critical, gmux, EFI/NVRAM, display-manager, Xorg, kernel-command-line, driver-package or hardware-policy change:

1. identify the exact current state;
2. save the original file/value;
3. create a rollback action before the change;
4. change one independent variable only;
5. do not combine unrelated changes in one reboot;
6. define what success and failure will look like;
7. postcheck after reboot before continuing.

Never change gmux while graphical/DRM/audio clients still hold the affected device files unless the specific experiment explicitly accounts for those holders.

For conditional driver changes also capture:

- PCI/USB hardware identity;
- current driver/modules;
- `/etc/modprobe.d` state;
- kernel version;
- rfkill/network state where applicable.

## Hard prohibitions for the reference platform

Do not recommend these as fixes for MacBookPro6,2 on modern Ubuntu:

- NVIDIA 340;
- permanent `nomodeset`;
- Nouveau clock increases/overclocking;
- retrying `gpu-power-prefs` writes as if they were a solved path;
- Wayland multi-GPU as the stable baseline;
- blind replacement of the complete OpenCore/OCLP EFI tree;
- blind installation of both Broadcom STA and b43 Wi-Fi paths;
- automatic installation of `pommed`, `mbpfan` or `macfanctld` without model-specific evidence;
- enabling multiple fan-control daemons.

The reasons are documented in `docs/failed-experiments.md` and `docs/hardware-integration.md`.

## Diagnostic discipline — graphics

When a user reports a freeze, black screen, duplicate display, slow browser, GPU error or boot regression:

- establish whether the failure begins **before or after the graphical session starts**;
- distinguish X11 from Wayland;
- distinguish kernel/DRM errors from application/ANGLE/Mesa errors;
- identify which GPU owns `boot_vga`;
- inspect `vga_switcheroo`;
- inspect `switcherooctl list`;
- inspect Xorg providers/outputs;
- check which processes hold `/dev/dri/card*`, render nodes and NVIDIA HDA devices;
- correlate timestamps instead of assuming two nearby symptoms share one cause.

## Diagnostic discipline — whole-Mac integration

For trackpad, keys/backlight, Wi-Fi, Bluetooth, audio, camera, battery, sensors/fans or optical drive:

- determine whether the hardware exists before installing userspace tools;
- distinguish kernel driver absence from userspace configuration;
- distinguish a missing device from an rfkill/policy block;
- collect exact PCI/USB IDs before selecting firmware/driver packages;
- do not assume one Broadcom device uses the same path as another;
- inspect sysfs LED/backlight endpoints before adding a brightness/hotkey daemon;
- separate physical input failures from libinput/GNOME behavior;
- diagnose temperature/sensor behavior before changing fan policy.

## Expected agent output

A good agent response should state:

- **classification** — which known case matches;
- **evidence** — exact signals that support it;
- **risk** — low / medium / high;
- **next action** — preferably one action or one script;
- **offline availability** — whether required tools/packages exist in the rescue manifest;
- **rollback** — for persistent changes;
- **postcheck** — what must be verified next;
- **repository update** — if a new finding changes the knowledge base.

## Repository maintenance rule

A troubleshooting session is not complete when the machine works. It is complete when reusable knowledge has also been captured.

When new evidence is produced, update the appropriate combination of:

- `knowledge/cases.json`
- `knowledge/integration-cases.json`
- `knowledge/evidence.json`
- `packages/manifests/*.json` when package requirements change
- `docs/findings.md`
- `docs/hardware-integration.md`
- `docs/failed-experiments.md`
- `docs/investigation-timeline.md`
- `docs/reference-checkpoint.md`
- `docs/roadmap.md`
- stable or experimental scripts

Never erase failed approaches merely because a later approach works; preserving rejected paths prevents repeated damage and wasted time.
