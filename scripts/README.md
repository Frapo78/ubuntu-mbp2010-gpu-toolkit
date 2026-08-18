# Scripts

This directory is divided by maturity, not convenience.

## Stable / conservative scripts

### `quick-triage.sh`

Read-only current-state classifier. It detects high-confidence signatures such as Wayland dual-GPU risk, duplicate LVDS outputs, current-boot Nouveau `INVALID_VALUE`, firmware `boot_vga` mismatch and unexpected `gpu-power-prefs` presence.

It does not apply fixes.

### `collect-diagnostics.sh`

Read-only diagnostic collector designed for public issue reports. It intentionally avoids IP/MAC data, serial numbers and full EFI-variable dumps, and redacts root UUID/PARTUUID values.

### `stabilize-known-good.sh`

Reference-machine conservative cleanup/checkpoint script. It removes only known residue from the project's one-shot experiments, verifies the expected EFI-variable state, snapshots key config/EFI state and can disable the duplicate LVDS output for the current X11 session.

Review it before using on a non-reference machine.

## `experimental/`

Contains research-grade actions that have produced useful reference results but are **not** part of automatic quickstart.

Experimental scripts may touch gmux/display configuration and must be treated as model-specific until support is explicitly widened.

## Rules for new scripts

### Diagnostic script

Should be:

- read-only;
- repeatable;
- privacy-aware;
- useful without prior chat context;
- explicit when a value requires sudo and was unavailable.

### Stable mutation script/action

Must define:

- supported hardware profiles;
- preconditions;
- risk;
- checkpoint;
- exact touched state;
- rollback;
- postcheck;
- already-satisfied behavior where possible.

### Experimental mutation

Must live under `experimental/`, fail closed on unexpected hardware/state and never be called automatically by stable tooling.

## Validation

All `.sh` files are parsed with `bash -n` in GitHub Actions. Passing syntax validation does **not** promote an experimental action to stable.
