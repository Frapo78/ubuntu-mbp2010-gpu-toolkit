# Resume point

When development resumes, start here.

## Do not redo

- Do not retry Wayland multi-GPU.
- Do not reinstall `nomodeset`.
- Do not retry `gpu-power-prefs` through efivarfs.
- Do not inject `gpu-power-prefs` into OpenCore as a blind fallback.
- Do not install NVIDIA 340.
- Do not increase Nouveau clocks.

## Known-good proofs to rely on

1. Intel Crocus acceleration works.
2. gmux can route the panel to Intel.
3. Intel-primary Xorg is smooth.
4. NVIDIA PRIME offload from Intel-primary works.
5. OpenCore 1.0.7 is installed and validated.
6. X11 is safer than Wayland on this machine.

## Next test

Design a **reversible early-boot display-routing + Intel-primary Xorg** configuration.

Requirements:

- run after `vga_switcheroo` is ready
- run before GDM/Xorg clients acquire both GPUs
- no EFI/NVRAM dependency
- rollback file created before enablement
- one reboot only
- postcheck:
  - active gmux client
  - Xorg primary device
  - single 1440x900 LVDS output
  - Intel default renderer
  - NVIDIA PRIME renderer
  - switcheroo-control view
  - DRM holders
  - Nouveau/i915 kernel errors
