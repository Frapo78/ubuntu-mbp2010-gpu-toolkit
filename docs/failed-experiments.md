# Failed or rejected experiments

Failures are useful when they prevent other users from repeating dangerous work.

## `nomodeset`

Useful only as an emergency diagnostic fallback. It disables the Intel KMS path and prevents the desired hybrid design.

## GNOME Wayland dual GPU

Produced a severe multi-GPU failure path and Nouveau error storm on the reference machine.

**Status:** rejected for the stable baseline.

## Chromium forced Intel ANGLE/GLES paths

Several browser-specific launch combinations failed to create a usable Intel context even though host Mesa Intel acceleration works.

**Conclusion:** browser failure does not imply broken i915/Crocus.

## `gpu-power-prefs` through Linux efivarfs

Both short and DWORD-shaped payload attempts were tested. The correct-format creation was rejected with:

```text
Invalid argument
```

No EFI variable was left behind.

**Status:** do not retry automatically.

## OpenCore NVRAM injection for `gpu-power-prefs`

Acidanthera reports real-Mac cases where the same variable under OpenCore NVRAM Add returns `Invalid Parameter`.

**Status:** not used as a fallback.

## NVIDIA 340

Unsupported on the modern Ubuntu/kernel stack and inconsistent with the safety goal.

**Status:** never install as part of this project.
