# Investigation timeline

This is the condensed engineering record behind the toolkit.

## Stage 0 — starting symptom

The machine could boot Ubuntu, but graphics behaviour was inconsistent:

- dual Intel + NVIDIA hardware
- NVIDIA often acting as the firmware/default GPU
- browser-related Nouveau errors
- high GPU temperature under some workloads
- previous use of `nomodeset` masking the Intel path
- uncertainty around OpenCore and Apple gmux interaction

The rule from the beginning became: **collect evidence before making each boot-critical change**.

## Stage 1 — Chromium / Nouveau diagnosis

A dedicated Chromium GPU report showed:

- Nouveau active on the GeForce GT 330M
- missing `nva5_fuc084` / `nva5_fuc084d`
- `msvld` initialization failure
- repeated `DATA_ERROR 00000004 [INVALID_VALUE]`
- `nouveau_cli_work` CPU activity
- temperatures high enough to trigger downclocking

Conclusion:

- missing firmware explains failed Nouveau video decode
- it does not prove that all 3D acceleration is broken
- Chromium is a strong trigger for the Nouveau error path

## Stage 2 — removing `nomodeset`

The first attempt to enable Intel KMS by removing `nomodeset` caused hard freezes.

A rollback script restored the prior boot configuration.

This established a core project rule:

> never interpret “both drivers load” as “the desktop stack can safely coordinate both GPUs”.

## Stage 3 — freeze forensics

Boot and Xorg/Wayland logs showed:

- i915 initialized
- Nouveau initialized
- `apple_gmux` detected
- `vga_switcheroo` enabled
- no i915 hang/reset preceding the freeze
- GNOME Wayland attempted accelerated iGPU/dGPU framebuffer sharing
- framebuffer sharing initialization failed
- Nouveau then produced a large graphics error storm

Conclusion:

**GNOME Wayland multi-GPU was the catastrophic trigger**, not basic i915 initialization.

## Stage 4 — force X11

GDM was configured with:

```ini
WaylandEnable=false
```

With Xorg:

- both GPUs remained available
- the previous Wayland-specific failure disappeared
- the system stopped hard-freezing during the same initialization path

New issue discovered:

- both GPUs exposed the same physical internal panel
- Xorg created a false two-monitor / 2880x900 layout

Conclusion:

X11 is the safe development baseline.

## Stage 5 — vga_switcheroo probe

The machine reported approximately:

```text
DIS  NVIDIA  active / powered
IGD  Intel   available / powered
DIS-Audio    dynamic-off capable
```

Both DRM render paths existed.

`switcheroo-control` saw two GPUs, but marked NVIDIA as default because the firmware still set NVIDIA `boot_vga=1`.

## Stage 6 — browser offload experiments

Several Chromium launch combinations were tested with Intel:

- `DRI_PRIME`
- desktop GL
- ANGLE GL
- GLES-related paths

Some failed because Chromium/ANGLE could not create the expected context.

This initially looked suspicious for Intel, so a browser-independent Mesa test was required.

## Stage 7 — host Mesa proves Intel is healthy

Direct Mesa testing selected:

- kernel `i915`
- userspace Crocus
- direct rendering
- hardware acceleration

No corresponding kernel error appeared.

Conclusion:

**Intel hardware acceleration works.**
Chromium/ANGLE failures are application/userspace-path failures, not proof of broken Intel hardware.

## Stage 8 — physical gmux test

A temporary `MIGD` switch was performed.

Observed:

- short display transition
- panel remained usable
- return to discrete path succeeded
- no new GPU kernel errors

Conclusion:

`apple_gmux` / `vga_switcheroo` can physically route the display to Intel on this machine.

## Stage 9 — Intel-primary Xorg test

A temporary i915 Xorg OutputClass using `PrimaryGPU=yes` was tested.

Observed:

- desktop fluid
- normal application use
- Intel Crocus acceleration active
- internal 1440x900 panel usable
- no i915 error storm

Conclusion:

Intel is a viable normal desktop GPU.

## Stage 10 — Intel-primary + NVIDIA PRIME

The next test combined:

- Intel Xorg primary
- panel routed to Intel
- NVIDIA kept present as secondary render provider
- explicit `DRI_PRIME=pci-0000_01_00_0`

Observed:

- Intel default rendering accelerated
- NVIDIA PRIME rendering accelerated
- light NVIDIA `glxgears` workload completed without new GPU faults
- rollback to the previous state worked

This is the project's most important positive result:

> **The rendering architecture needed for “Intel default + NVIDIA on demand” already works.**

The remaining challenge is boot/default semantics, policy and power management.

## Stage 11 — why GNOME still calls NVIDIA “default”

A preflight report showed:

```text
Intel  boot_vga=0
NVIDIA boot_vga=1
```

`switcheroo-control` consequently reported:

```text
NVIDIA Default=yes
Intel  Default=no
```

The mismatch is therefore not a PRIME rendering failure. It is a firmware/default-GPU semantics problem.

## Stage 12 — OpenCore audit

The existing EFI was audited instead of blindly upgraded.

Important discoveries:

- OpenCore/OCLP-related configuration markers existed
- EFI/BOOT contained additional fallback components
- stock-file replacement had to be staged carefully
- matching `ocvalidate.linux` was required

The old config produced one OpenCore 1.0.7 validation issue:

```text
Misc -> BlessOverride -> \EFI\Microsoft\Boot\bootmgfw.efi is redundant
```

Only that redundant entry was removed in staging.

## Stage 13 — OpenCore 1.0.7 upgrade

The candidate config validated cleanly.

The following OpenCore components were updated in the real ESP after backup:

- OpenCore.efi
- OpenRuntime.efi
- OpenCanopy.efi
- OpenLinuxBoot.efi
- ResetNvramEntry.efi
- BootKicker.efi
- OpenShell.efi
- corrected config.plist

The machine rebooted successfully.

Postcheck confirmed:

- live hashes matched the 1.0.7 staging set
- `opencore-version` reported `REL-107-2026-03-20`
- `ocvalidate` passed
- GPU state remained unchanged

## Stage 14 — login “X cursor” investigation

After the OpenCore reboot, the desktop briefly showed an X-shaped cursor / delayed repaint.

Logs showed:

- no i915 hang/reset responsible for that moment
- Xorg still started NVIDIA as primary
- Intel was attached as secondary
- both LVDS copies were active
- logical desktop remained 2880x900
- GNOME Shell completed startup later

Nouveau `INVALID_VALUE` errors appeared only **after Chromium launched**, not during the initial X-shaped cursor phase.

Conclusion:

the login visual glitch is much more consistent with the awkward dual-panel Xorg layout/session repaint than with an OpenCore regression.

## Stage 15 — `gpu-power-prefs` research and tests

Apple gmux supports an EFI preference variable that can select the initial GPU.

On the reference machine:

- efivarfs is mounted read/write
- other EFI variables such as `opencore-version` are readable
- `gpu-power-prefs` is initially absent

Several safe one-shot scripts were built with automatic cleanup.

The final correct-format creation attempt used:

```text
07 00 00 00 01 00 00 00
```

where the first DWORD contains EFI attributes and the second DWORD represents the Intel preference.

Linux returned:

```text
Invalid argument
```

The variable was not created and the autorevert helper removed itself.

Acidanthera also documents real-Mac cases where OpenCore NVRAM injection of this variable fails with `Invalid Parameter`.

Decision:

**do not base the project on runtime `gpu-power-prefs` writes.**

## Stage 16 — final switcheroo-control probe

Before pausing the investigation:

- `switcheroo-control` 2.6 was installed, enabled and running
- it starts before GDM
- Intel remained `boot_vga=0`
- NVIDIA remained `boot_vga=1`
- NVIDIA was therefore `Default=yes`
- Xorg held both DRM cards
- Chromium held the NVIDIA render node
- there was no persistent experimental GPU Xorg override

This is the checkpoint from which development resumes.

## Engineering direction from here

The next work should not revisit already disproven paths.

Priority:

1. make Intel-primary Xorg + Intel display routing boot-safe and persistent
2. keep NVIDIA PRIME render offload available
3. correct GNOME dedicated-GPU launch semantics or wrap them cleanly
4. test runtime suspend/resume of the discrete GPU
5. only then build a GTK/libadwaita manager if native integration cannot express the desired policy
