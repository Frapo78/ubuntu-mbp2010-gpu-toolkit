# Ubuntu MacBook Pro 2010 GPU Toolkit

A reproducible troubleshooting and compatibility toolkit for running modern Ubuntu on the **MacBook Pro 15-inch Mid 2010 (MacBookPro6,2)** with its unusual muxed dual-GPU architecture:

- Intel Ironlake / Arrandale integrated graphics (`i915`, Mesa Crocus)
- NVIDIA GeForce GT 330M / GT216M (`nouveau`)
- Apple `gmux`
- `vga_switcheroo`
- OpenCore as boot manager

The project started from a real Ubuntu 24.04 troubleshooting session and turns the findings into safe, repeatable diagnostics and recovery actions.

## Goal

The long-term target is a Linux user experience close to macOS hybrid graphics:

1. **Intel by default** for desktop, browser and normal workloads.
2. **NVIDIA on demand** for applications that benefit from the discrete GPU.
3. A GNOME-friendly launcher or small GUI to select the dedicated GPU.
4. Automatic dGPU power management where the hardware/kernel combination permits it.
5. No fragile proprietary legacy NVIDIA driver hacks.

## Current proven baseline

Tested on:

- MacBookPro6,2
- Ubuntu 24.04.4 LTS
- X11 session
- Linux 7.0 Ubuntu kernel
- OpenCore 1.0.7
- Intel `i915` + Crocus
- NVIDIA `nouveau`
- `apple_gmux` 1.9.33
- `switcheroo-control` 2.6

### Proven working

- Both GPUs load successfully under X11.
- Intel Mesa/Crocus hardware acceleration works.
- `vga_switcheroo` and Apple gmux are functional.
- Physical display mux switching to Intel works.
- Xorg can run Intel as the primary GPU.
- NVIDIA PRIME render offload works while Intel is primary.
- OpenCore 1.0.7 boots Ubuntu successfully.

### Known problematic paths

- GNOME Wayland + this dual-GPU configuration can freeze the machine.
- Nouveau on the GT 330M can emit `DATA_ERROR [INVALID_VALUE]` with Chromium.
- Nouveau video-decode firmware `nva5_fuc084*` is missing on a standard installation.
- With NVIDIA as Xorg primary, both GPUs may expose the same LVDS panel and create a false `2880x900` desktop.
- `switcheroo-control` currently follows firmware `boot_vga`, so NVIDIA is reported as the default GPU.
- Runtime creation of Apple's `gpu-power-prefs` EFI variable is rejected with `EINVAL` on the tested machine.
- OpenCore NVRAM injection is therefore not considered a safe fallback for this variable.

## Do not do this

- Do **not** install NVIDIA 340 on modern Ubuntu.
- Do **not** use `nomodeset` as a permanent solution.
- Do **not** increase Nouveau clocks to hide performance problems.
- Do **not** change gmux while graphical/DRM/audio clients still hold the GPU devices.
- Do **not** experiment with EFI variables without a tested rollback path.

## Quick start

Collect a report:

```bash
chmod +x scripts/collect-diagnostics.sh
./scripts/collect-diagnostics.sh
```

Return to the conservative known-good baseline:

```bash
chmod +x scripts/stabilize-known-good.sh
./scripts/stabilize-known-good.sh
```

## Project structure

- `docs/architecture.md` — how this Mac's graphics stack fits together
- `docs/findings.md` — evidence-backed results from the investigation
- `docs/opencore.md` — OpenCore notes and safe upgrade approach
- `docs/safety.md` — rules that prevent hard-to-recover experiments
- `docs/roadmap.md` — path toward macOS-like hybrid graphics
- `docs/failed-experiments.md` — approaches that were tested and rejected
- `scripts/collect-diagnostics.sh` — read-only system report
- `scripts/stabilize-known-good.sh` — conservative cleanup/checkpoint
- `scripts/experimental/` — experiments that require explicit review

## Status

**Research / early alpha.** The stable diagnostic and rollback pieces are useful now; automatic hybrid graphics is still being engineered.

## License

MIT. Hardware and software names belong to their respective owners.
