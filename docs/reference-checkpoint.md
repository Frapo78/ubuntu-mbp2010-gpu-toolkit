# Reference machine checkpoint — 2026-08-19

This file captures the point at which active experimentation was paused.

- MacBookPro6,2
- Ubuntu 24.04.4 LTS
- kernel 7.0.0-29-generic
- X11
- OpenCore REL-107-2026-03-20
- Intel i915 loaded, `boot_vga=0`
- NVIDIA Nouveau loaded, `boot_vga=1`
- switcheroo-control 2.6 active
- firmware/default GPU reported as NVIDIA
- no `gpu-power-prefs` EFI variable
- no persistent experimental Xorg GPU override
- current dual-GPU Xorg can expose duplicate internal LVDS outputs

Next engineering task: create a persistent, boot-safe Intel-primary desktop while retaining NVIDIA PRIME on-demand.
