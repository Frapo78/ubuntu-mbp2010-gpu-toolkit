# Roadmap

The project now has two parallel engineering tracks:

1. **hybrid graphics** — reach a stable Intel-default + NVIDIA-on-demand architecture;
2. **whole-Mac compatibility / rescue** — make the rest of MacBookPro6,2 hardware diagnosable, repairable and installable even offline.

Both tracks share the same safety framework: detect → diagnose → classify → checkpoint → fix → postcheck.

## Phase 1 — reproducible baseline

- [x] Detect MacBookPro6,2 hardware
- [x] Collect GPU / gmux / switcheroo / Xorg diagnostics
- [x] Establish X11 as the safe baseline
- [x] Validate Intel Crocus acceleration
- [x] Validate physical gmux switch
- [x] Validate Intel-primary Xorg
- [x] Validate NVIDIA PRIME offload
- [x] Upgrade and validate OpenCore 1.0.7
- [x] Document rejected `gpu-power-prefs` runtime path
- [x] Add agent operating protocol and machine-readable knowledge/profile layer
- [x] Add whole-Mac integration probe and integration knowledge cases
- [x] Add Ubuntu 24.04 amd64 package manifest
- [x] Add offline USB bundle builder/verifier/installer architecture

## Phase 2A — permanent Intel-primary desktop

- [ ] Build a boot-safe service/configuration that moves the display path to Intel before the graphical session
- [ ] Persist Xorg Intel `PrimaryGPU`
- [ ] Ensure only one internal LVDS output is active
- [ ] Confirm normal suspend/resume and external display behaviour
- [ ] Confirm Chromium uses a stable path by default

Tracked primarily by issue #1.

## Phase 2B — validate offline rescue bundles

- [ ] Build `minimal` Noble/amd64 bundle on clean environment
- [ ] Build `rescue` Noble/amd64 bundle
- [ ] Build `full` Noble/amd64 bundle including conditional driver packages
- [ ] Verify SHA-256 and local APT repository after USB copy
- [ ] Prove stable package installation with networking disabled
- [ ] Prove conditional driver gates and kernel/header mismatch failures
- [ ] Test b43 captured-firmware workflow without network access
- [ ] Record exact package versions/toolkit commit in generated bundle
- [ ] Define GitHub Release artifact format after the workflow is stable

Tracked by issue #7.

## Phase 3A — native dedicated-GPU launching

- [ ] Determine whether `switcheroo-control` can be taught the intended default policy despite firmware `boot_vga`
- [ ] Verify GNOME “Launch using Dedicated Graphics Card”
- [ ] Preserve explicit `DRI_PRIME=pci-0000_01_00_0` as the ground-truth fallback

## Phase 3B — whole-Mac hardware inventory and integration

Reference machine, read-only first:

- [ ] inventory trackpad USB identity / `bcm5974`
- [ ] inventory Apple keyboard / HID / `hid_apple`
- [ ] inventory keyboard-backlight and display-backlight endpoints
- [ ] identify exact Broadcom Wi-Fi PCI ID and current path
- [ ] identify Bluetooth USB controller / `btusb` / firmware requirements
- [ ] inventory ALSA audio devices
- [ ] inventory camera/video path
- [ ] inventory battery and power state
- [ ] inventory `applesmc` sensors/fan endpoints
- [ ] inventory SATA/optical devices
- [ ] add sanitized diagnostic fixture
- [ ] update `profiles/MacBookPro6,2.json` with non-GPU hardware

Then, subsystem by subsystem:

- [ ] validate trackpad/libinput baseline
- [ ] validate Apple function/media-key policy
- [ ] validate keyboard backlight control
- [ ] validate display brightness path in the stable GPU architecture
- [ ] choose and validate Wi-Fi driver/package path
- [ ] validate Bluetooth stack/firmware path
- [ ] validate audio routing
- [ ] validate camera support
- [ ] validate battery reporting/power behavior
- [ ] validate thermal/fan behavior before considering a fan daemon
- [ ] validate optical-drive integration

Tracked by issues #8 and #9.

## Phase 4 — NVIDIA power management

- [ ] Measure whether Xorg holds the NVIDIA card in a way that prevents runtime suspend
- [ ] Test `power/control=auto` for NVIDIA GPU and HDA
- [ ] Verify automatic resume during PRIME workloads
- [ ] Verify return to suspended state after the workload exits

## Phase 5 — unified action/checkpoint framework

- [ ] Build common applicability checks
- [ ] Build checkpoint state format
- [ ] Generate rollback before persistent modification
- [ ] Add immediate verify and reboot/postcheck contracts
- [ ] Add machine-readable action result / exit codes
- [ ] Add package/offline availability metadata to actions
- [ ] Make the same action usable online or from a USB bundle

Tracked by issue #2.

## Phase 6 — unified CLI

Target UX:

```text
mbp-ubuntu detect
mbp-ubuntu diagnose
mbp-ubuntu status
mbp-ubuntu fix <case-id>
mbp-ubuntu integration status
mbp-ubuntu packages status
mbp-ubuntu offline verify <bundle>
mbp-ubuntu gpu status
mbp-ubuntu gpu launch --nvidia <command>
mbp-ubuntu rollback <action-id>
```

- [ ] JSON output mode for agents
- [ ] concise human output by default
- [ ] package/offline diagnostics
- [ ] never run experimental actions implicitly
- [ ] fixture-based classification tests

Tracked by issue #5.

## Phase 7 — user-facing manager

If native GNOME semantics remain insufficient:

- [ ] GTK4/libadwaita status application
- [ ] “Intel / Automatic / NVIDIA app” modes
- [ ] one-click dedicated-GPU launcher
- [ ] whole-Mac integration/status page where useful
- [ ] current gmux and runtime-power status
- [ ] optional polkit helper for privileged operations
- [ ] no hidden destructive EFI writes

## Phase 8 — packaging / release

Only after core actions are stable:

- [ ] versioned installer/CLI package
- [ ] `.deb` or another appropriate Ubuntu-native package
- [ ] generated USB rescue artifact for supported suite/model/kernel combinations
- [ ] release manifest with package versions and SHA-256 sums
- [ ] upgrade/migration path between toolkit versions
- [ ] offline rollback assets

## Phase 9 — broader compatibility

- [ ] Detect related 2010 MacBook Pro models
- [ ] Separate model-specific quirks from shared logic
- [ ] Add new real-machine profiles only from measured evidence
- [ ] Distinguish NVIDIA-gmux 2010 families from later AMD-gmux hardware
- [ ] Add tests using saved sanitized diagnostic fixtures
- [ ] gate every persistent action by supported profile/topology
