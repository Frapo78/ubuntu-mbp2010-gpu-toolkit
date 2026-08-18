# Findings

This document records conclusions that were reproduced on the reference MacBookPro6,2.

## 1. Wayland is the main catastrophic trigger

Removing `nomodeset` enables both GPUs, but GNOME Wayland multi-GPU initialization can enter a failure path involving accelerated framebuffer sharing. Nouveau then produces a large error storm and the machine can freeze.

**Decision:** keep `WaylandEnable=false` while working on this hardware.

## 2. X11 dual-GPU is substantially safer

With both `i915` and Nouveau active under Xorg, the previous Wayland-specific failure disappears and no i915 GPU hangs/resets were observed.

## 3. Intel acceleration is healthy

Direct host Mesa tests with `DRI_PRIME` select Intel `i915` / Crocus, report direct rendering and hardware acceleration, and do not create kernel GPU errors.

This is important: Chromium/ANGLE failures on Intel were a userspace/browser path, not proof that Intel acceleration was broken.

## 4. gmux switching works

A temporary `MIGD` test switched the physical panel path to Intel and returned to the discrete path successfully.

## 5. Intel-primary Xorg works

A temporary Xorg `OutputClass` with `PrimaryGPU=yes` for i915 produced a fluid 1440x900 desktop.

## 6. NVIDIA PRIME offload works from Intel-primary

With Intel as Xorg primary, explicit `DRI_PRIME=pci-0000_01_00_0` selects Nouveau/NVA5 and runs a light 3D load successfully.

This is the strongest proof that the desired final architecture is feasible at the rendering level.

## 7. Firmware default remains NVIDIA

Current firmware state exposes:

- Intel `boot_vga=0`
- NVIDIA `boot_vga=1`

`switcheroo-control` consequently marks NVIDIA as `Default=yes`.

## 8. Apple's gpu-power-prefs runtime write is rejected

The tested machine exposes working efivarfs and OpenCore runtime variables, but attempts to create:

`gpu-power-prefs-fa4ce28d-b62f-4c99-9cc3-6815686e30f9`

return `EINVAL`, including with the expected DWORD payload format.

**Decision:** stop retrying runtime EFI writes. Do not build the solution around this mechanism.

## 9. Chromium can trigger Nouveau errors

When Chromium uses the NVIDIA render node, Nouveau can emit repeated:

```text
gr: DATA_ERROR 00000004 [INVALID_VALUE]
```

Missing `nva5_fuc084` / `nva5_fuc084d` firmware also prevents Nouveau video decode initialization.

## 10. Duplicate internal-panel outputs

When both GPUs expose the internal panel to Xorg, the single physical 1440x900 LCD may appear as two logical monitors, creating a false 2880x900 desktop.

Turning off the duplicate output fixes the logical layout; Intel-primary + correct gmux routing avoids the underlying situation more cleanly.
