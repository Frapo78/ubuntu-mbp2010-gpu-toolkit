# Agent operating protocol

This repository is designed to be usable by both humans and autonomous/semi-autonomous troubleshooting agents.

## Mission

Reduce time-to-diagnosis and time-to-safe-fix for Ubuntu installations on MacBook Pro 2010 hardware, beginning with the fully investigated **MacBookPro6,2** reference machine.

The goal is not to maximize the number of tweaks applied. The goal is to reach a **known, evidence-backed, recoverable state** as quickly as possible.

## Read order for agents

Before proposing persistent changes, read in this order:

1. `docs/quick-triage.md`
2. `knowledge/cases.json`
3. `docs/status-model.md`
4. `docs/safety.md`
5. the matching detailed document in `docs/`
6. `docs/failed-experiments.md`

For graphics work also read:

- `docs/architecture.md`
- `docs/findings.md`
- `docs/resume-point.md`

## First action on an unknown machine

Do not guess from the user's description alone. Collect a report first:

```bash
chmod +x scripts/collect-diagnostics.sh
./scripts/collect-diagnostics.sh
```

Then classify the machine and symptom using `knowledge/cases.json`.

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

## Safety contract

Before any boot-critical, gmux, EFI/NVRAM, display-manager, Xorg or kernel-command-line change:

1. identify the exact current state;
2. save the original file/value;
3. create a rollback action before the change;
4. change one independent variable only;
5. do not combine unrelated changes in one reboot;
6. define what success and failure will look like;
7. postcheck after reboot before continuing.

Never change gmux while graphical/DRM/audio clients still hold the affected device files unless the specific experiment explicitly accounts for those holders.

## Hard prohibitions for the reference platform

Do not recommend these as fixes for MacBookPro6,2 on modern Ubuntu:

- NVIDIA 340;
- permanent `nomodeset`;
- Nouveau clock increases/overclocking;
- retrying `gpu-power-prefs` writes as if they were a solved path;
- Wayland multi-GPU as the stable baseline;
- blind replacement of the complete OpenCore/OCLP EFI tree.

The reasons are documented in `docs/failed-experiments.md`.

## Diagnostic discipline

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

## Expected agent output

A good agent response should state:

- **classification** — which known case matches;
- **evidence** — exact signals that support it;
- **risk** — low / medium / high;
- **next action** — preferably one action or one script;
- **rollback** — for persistent changes;
- **postcheck** — what must be verified next;
- **repository update** — if a new finding changes the knowledge base.

## Repository maintenance rule

A troubleshooting session is not complete when the machine works. It is complete when reusable knowledge has also been captured.

When new evidence is produced, update the appropriate combination of:

- `knowledge/cases.json`
- `docs/findings.md`
- `docs/failed-experiments.md`
- `docs/investigation-timeline.md`
- `docs/reference-checkpoint.md`
- `docs/roadmap.md`
- stable or experimental scripts

Never erase failed approaches merely because a later approach works; preserving rejected paths prevents repeated damage and wasted time.
