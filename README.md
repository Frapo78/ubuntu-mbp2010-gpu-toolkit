# Ubuntu MacBook Pro 2010 Compatibility, Recovery & Hybrid-GPU Toolkit

A reproducible troubleshooting, recovery and compatibility toolkit for running modern Ubuntu on the **MacBook Pro 15-inch Mid 2010 (`MacBookPro6,2`)**.

The project began with a difficult dual-GPU investigation and is being turned into a package that can help **humans and troubleshooting agents** diagnose, recover, fix and stabilize similar installations as quickly and safely as possible.

It now covers two connected goals:

1. **Hybrid graphics** — Intel i915/Crocus for normal desktop use, NVIDIA GT 330M/Nouveau on demand, Apple gmux, PRIME, `vga_switcheroo`, `switcheroo-control` and OpenCore.
2. **Whole-Mac Ubuntu integration** — trackpad, Apple keyboard/function keys, keyboard/display backlight, Broadcom Wi-Fi, Bluetooth, audio, camera, battery, SMC sensors/fans, storage and optical media.

> **Status: early alpha / active engineering.** The diagnostic framework, offline package architecture and several core findings are useful now. The final automatic hybrid-GPU configuration is not yet declared stable.

---

# Project goal

The target workflow is:

```text
DETECT
  ↓
DIAGNOSE
  ↓
CLASSIFY
  ↓
CHECKPOINT
  ↓
FIX
  ↓
REBOOT (only when needed)
  ↓
POSTCHECK
  ↓
PROMOTE EVIDENCE INTO THE REPOSITORY
```

The final user experience should be close to the good parts of macOS hardware integration while staying transparent and Linux-native:

- Intel as the normal low-power desktop/rendering path;
- NVIDIA available for explicit or GUI-driven on-demand rendering;
- automatic dGPU power saving where the kernel/hardware actually allow it;
- working MacBook input/backlight/connectivity/platform hardware;
- offline recovery from USB when Wi-Fi or the graphical stack is broken;
- checkpoints and rollback before risky changes;
- no unsupported legacy-driver shortcuts.

See [`docs/project-charter.md`](docs/project-charter.md) and [`docs/package-architecture.md`](docs/package-architecture.md).

---

# Start here

## Human — Ubuntu boots and the problem is unknown

Run the non-destructive triage:

```bash
chmod +x scripts/quick-triage.sh
./scripts/quick-triage.sh
```

Graphics/system diagnostics:

```bash
chmod +x scripts/collect-diagnostics.sh
./scripts/collect-diagnostics.sh
```

Whole-Mac integration diagnostics:

```bash
chmod +x scripts/integration-probe.sh
./scripts/integration-probe.sh
```

Then read:

1. [`docs/quick-triage.md`](docs/quick-triage.md)
2. [`docs/decision-tree.md`](docs/decision-tree.md)
3. [`docs/runbook.md`](docs/runbook.md)
4. [`knowledge/cases.json`](knowledge/cases.json)
5. [`knowledge/integration-cases.json`](knowledge/integration-cases.json)

## Human — the Mac has no working Internet connection

Use a USB rescue bundle prepared earlier on an Ubuntu 24.04 amd64 machine with network access.

On the online builder:

```bash
./scripts/offline/prepare-bundle.sh \
  --profile rescue \
  --output /media/$USER/USB/mbp-rescue
```

For a larger kit including conditional Wi-Fi driver packages:

```bash
./scripts/offline/prepare-bundle.sh \
  --profile full \
  --kernel "$(uname -r)" \
  --output /media/$USER/USB/mbp-rescue-full
```

On the offline Mac:

```bash
./scripts/offline/verify-bundle.sh /path/to/mbp-rescue
./scripts/offline/install-bundle.sh /path/to/mbp-rescue --dry-run
./scripts/offline/install-bundle.sh /path/to/mbp-rescue
```

The default installer applies only package sets explicitly marked safe for automatic installation.

**Conditional driver packages can be present on the USB without being installed.** Broadcom Wi-Fi or Bluetooth firmware packages require hardware classification and explicit selection.

See [`docs/offline-rescue.md`](docs/offline-rescue.md) and [`packages/README.md`](packages/README.md).

## AI / troubleshooting agent

Read [`AGENTS.md`](AGENTS.md) first.

Machine-readable sources:

- [`profiles/MacBookPro6,2.json`](profiles/MacBookPro6,2.json)
- [`knowledge/cases.json`](knowledge/cases.json)
- [`knowledge/integration-cases.json`](knowledge/integration-cases.json)
- [`knowledge/evidence.json`](knowledge/evidence.json)
- [`packages/manifests/noble-amd64.json`](packages/manifests/noble-amd64.json)
- [`docs/status-model.md`](docs/status-model.md)

Agents must **classify before modifying** and must not confuse “package available in the USB bundle” with “package is the correct fix for this hardware.”

---

# Offline package system

Binary `.deb` files are intentionally not committed to Git.

Instead the repository contains a versioned package manifest and scripts that generate a self-contained local APT repository for a USB drive.

Benefits:

- packages come from Ubuntu repositories at bundle-build time;
- exact versions and SHA-256 hashes are recorded;
- DKMS/header packages can target the correct kernel;
- Git does not contain hundreds of MB of stale binaries;
- generated USB bundles can later become GitHub Release artifacts once the format is stable.

Current Ubuntu reference manifest:

```text
packages/manifests/noble-amd64.json
```

Main package groups include:

### Stable runtime / diagnostics

Examples:

- `linux-firmware`
- `switcheroo-control`
- `bluez`
- `pciutils`, `usbutils`, `inxi`
- `rfkill`, `iw`, `wireless-tools`, `wireless-regdb`
- `libinput-tools`, `evtest`, `xinput`
- `mesa-utils`, `x11-xserver-utils`
- `lm-sensors`, `powertop`
- `smartmontools`
- `alsa-utils`, `v4l-utils`
- `brightnessctl`
- `acpi`, `upower`

### Conditional packages

Present in a full rescue bundle but **never blindly applied**:

- Broadcom STA: `broadcom-sta-dkms`, `dkms`, matching kernel headers;
- b43 tooling: `b43-fwcutter`, `firmware-b43-installer` package payload;
- `bluez-firmware` when controller/log evidence requires it.

### Optional integration/UI

- `blueman`
- `pavucontrol`
- optical/audio tools such as `asunder`, `lame`, `flac`, `k3b`

### Experimental Apple policy daemons

Available in Ubuntu but **not automatically installed by this project**:

- `pommed`
- `mbpfan`
- `macfanctld`

These can duplicate modern desktop/hardware policy or alter thermal behavior and therefore require model-specific evidence.

---

# Whole-Mac integration scope

## Trackpad

The Apple multitouch trackpad is normally handled by the kernel `bcm5974` driver and libinput.

The toolkit checks device detection, events, libinput classification and X11/GNOME configuration before proposing changes.

## Keyboard and keyboard backlight

The toolkit checks Apple HID state, `hid_apple` parameters, actual key events, SMC/platform state and `/sys/class/leds/*kbd_backlight` endpoints.

`brightnessctl` is a control utility; it cannot create a missing kernel LED endpoint.

## Wi-Fi

Broadcom Wi-Fi is always classified by exact PCI ID and current driver/firmware state.

The project explicitly avoids the common “install every Broadcom driver until something works” pattern.

## Bluetooth

The normal path is the kernel USB Bluetooth stack plus BlueZ. Firmware packages are conditional on controller identity and logs.

## Audio / camera / optical drive

The toolkit separates kernel device detection from desktop/application routing using ALSA, V4L2, udev/lsblk and related tools.

## Battery / power / thermal

The toolkit reports battery health, power state, sensors and Apple SMC/fan exposure before changing policy.

Fan-control daemons remain experimental until the reference model has been explicitly validated.

See [`docs/hardware-integration.md`](docs/hardware-integration.md).

---

# Current graphics baseline

Reference machine:

- `MacBookPro6,2`
- Ubuntu 24.04.4 LTS
- X11 session
- Linux 7.0 Ubuntu kernel
- OpenCore 1.0.7
- Intel `i915` + Mesa Crocus
- NVIDIA GT 330M + `nouveau`
- classic `apple_gmux`
- `switcheroo-control` 2.6

## Proven working

- Both GPUs load under X11.
- Intel Mesa/Crocus direct hardware acceleration works.
- `vga_switcheroo` and Apple gmux are functional.
- The physical internal display can be routed to Intel.
- Xorg can run Intel as the primary GPU.
- NVIDIA PRIME render offload works while Intel is primary.
- OpenCore 1.0.7 boots Ubuntu successfully after a staged/validated upgrade.

The desired rendering architecture — **Intel primary + NVIDIA on demand** — has therefore already been demonstrated temporarily. Remaining work is persistence, boot ordering, GNOME policy and dGPU power management.

## Known problematic/rejected paths

- GNOME Wayland + this dual-GPU topology can hard-freeze the reference machine.
- Nouveau can emit `DATA_ERROR [INVALID_VALUE]`, notably with Chromium.
- Nouveau video decode lacks the tested NVA5 firmware path.
- NVIDIA-primary Xorg can expose the internal panel twice, producing a false `2880x900` desktop.
- firmware `boot_vga` still makes `switcheroo-control` call NVIDIA the default GPU.
- runtime creation of Apple's `gpu-power-prefs` EFI variable is rejected with `EINVAL` on the reference machine.
- NVIDIA 340 is not a supported solution for this modern Ubuntu stack.

See [`docs/findings.md`](docs/findings.md) and [`docs/failed-experiments.md`](docs/failed-experiments.md).

---

# Safety model

Every recommendation uses the maturity model:

```text
planned -> experimental -> proven -> stable
```

Any path may become:

```text
rejected
```

A fix is not stable merely because it worked once.

Persistent actions require:

1. applicability check;
2. checkpoint;
3. rollback prepared first;
4. one independent modification at a time;
5. immediate verification;
6. reboot only when required;
7. postcheck before continuing.

Hard rules for the reference platform include:

- no NVIDIA 340;
- no permanent `nomodeset`;
- no Nouveau clock increases/overclocking;
- no automated retry loop for `gpu-power-prefs`;
- no Wayland multi-GPU stable baseline yet;
- no blind replacement of an OpenCore/OCLP EFI tree;
- no blind dual installation of Broadcom STA and b43;
- no automatic `pommed`, `mbpfan` or `macfanctld` policy changes;
- no gmux changes while graphical/DRM/audio clients hold affected devices unless the reviewed experiment explicitly handles them.

Read [`docs/safety.md`](docs/safety.md) and [`SECURITY.md`](SECURITY.md).

---

# Repository map

## Human / agent entrypoints

- `README.md`
- `AGENTS.md`
- `docs/quick-triage.md`
- `docs/decision-tree.md`
- `docs/runbook.md`
- `docs/reporting.md`

## Machine-readable knowledge

- `knowledge/cases.json`
- `knowledge/integration-cases.json`
- `knowledge/evidence.json`
- `profiles/MacBookPro6,2.json`
- `packages/manifests/noble-amd64.json`

## Offline rescue

- `docs/offline-rescue.md`
- `packages/README.md`
- `scripts/offline/prepare-bundle.sh`
- `scripts/offline/verify-bundle.sh`
- `scripts/offline/install-bundle.sh`

## Whole-Mac integration

- `docs/hardware-integration.md`
- `scripts/integration-probe.sh`

## Graphics / OpenCore engineering

- `docs/architecture.md`
- `docs/findings.md`
- `docs/opencore.md`
- `docs/investigation-timeline.md`
- `docs/reference-checkpoint.md`
- `docs/resume-point.md`
- `scripts/experimental/`

## Development / governance

- `docs/project-charter.md`
- `docs/package-architecture.md`
- `docs/status-model.md`
- `docs/roadmap.md`
- `CONTRIBUTING.md`
- `.github/workflows/validate.yml`
- `tests/`

---

# Current next engineering goal

The primary GPU task remains a **reversible early-boot Intel display-routing + Intel-primary Xorg configuration** that:

- runs before GDM/Xorg clients acquire both GPUs;
- routes the internal panel to Intel safely;
- starts the desktop on Intel i915/Crocus;
- keeps NVIDIA/Nouveau available for explicit PRIME rendering;
- avoids the duplicate LVDS layout;
- has rollback and postcheck built in.

In parallel, the compatibility layer will continue turning validated trackpad, Wi-Fi, Bluetooth, keyboard/backlight, thermal, audio, camera and storage findings into model-gated actions and offline rescue package sets.

---

# Contributing

Use the structured diagnostic issue form and attach redacted reports.

When contributing a fix, include:

- supported model/profile;
- maturity status;
- evidence/preconditions;
- packages required;
- offline availability;
- state touched;
- rollback;
- postcheck.

See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## License

MIT. Hardware and software names belong to their respective owners.
