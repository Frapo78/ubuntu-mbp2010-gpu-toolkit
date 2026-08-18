# Troubleshooting decision tree

Use this when the problem report is vague. The objective is to reach a known case with the fewest risky actions.

```text
START
  |
  +-- Does Ubuntu boot to a usable shell/session?
  |      |
  |      +-- NO --> classify as boot-critical
  |      |           |
  |      |           +-- Did the problem begin after EFI/OpenCore change?
  |      |           |      +-- YES --> restore/verify EFI checkpoint first
  |      |           |
  |      |           +-- Did it begin after GRUB/kernel cmdline change?
  |      |                  +-- YES --> restore previous cmdline first
  |      |
  |      +-- YES --> continue read-only diagnosis
  |
  +-- Is the problem a hard graphical freeze?
  |      |
  |      +-- session=wayland + both GPUs active
  |      |      --> wayland-multigpu-freeze
  |      |
  |      +-- session=x11
  |             --> correlate journal timestamps, Xorg, holders and app launch
  |
  +-- Is the screen usable but layout is wrong / 2880x900?
  |      --> duplicate-internal-lvds
  |
  +-- Does the problem begin when Chromium starts?
  |      |
  |      +-- Nouveau INVALID_VALUE / firmware errors
  |             --> chromium-nouveau-invalid-value
  |
  +-- Does an Intel browser test fail?
  |      |
  |      +-- host Mesa Intel acceleration succeeds
  |             --> intel-browser-false-negative
  |
  +-- Are both GPUs healthy but NVIDIA is called Default?
  |      |
  |      +-- NVIDIA boot_vga=1, Intel boot_vga=0
  |             --> nvidia-default-because-boot-vga
  |
  +-- Is the requested outcome Intel desktop + NVIDIA on demand?
  |      --> intel-primary-nvidia-prime
  |          (proven architecture, persistence still experimental)
  |
  +-- Is someone trying to create gpu-power-prefs?
  |      --> gpu-power-prefs-einval
  |          STOP automatic retries
  |
  +-- Is the task an OpenCore update?
         --> opencore-safe-update
```

## Boot-critical branch

A boot-critical failure gets priority over feature work.

Before changing anything else, identify the **last persistent change**. Restore that single variable first. Examples:

- OpenCore component/config change;
- GRUB kernel command line;
- GDM Wayland setting;
- persistent Xorg OutputClass;
- systemd service that writes gmux/power state.

Do not stack another workaround on top of an unknown boot regression.

## Graphical branch

Always separate these layers:

1. firmware/OpenCore;
2. kernel drivers (`i915`, `nouveau`, `apple_gmux`);
3. physical mux state (`vga_switcheroo`);
4. display server (Xorg/Wayland);
5. Mesa/DRI renderer;
6. desktop policy (`switcheroo-control` / GNOME);
7. application-specific GPU stack (Chromium/ANGLE etc.).

A failure at layer 7 is not automatically a driver failure at layer 2.

## Timestamp rule

If an error appears only after an application starts, do not use it to explain an earlier boot/login glitch unless timestamps prove the relationship.

This rule was important on the reference machine: Nouveau `INVALID_VALUE` errors appeared after Chromium launch and did not explain the earlier X-shaped cursor / delayed GNOME repaint.
