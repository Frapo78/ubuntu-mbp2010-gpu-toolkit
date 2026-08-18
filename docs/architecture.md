# Graphics architecture

## Hardware

MacBookPro6,2 contains two GPUs connected through Apple's hardware multiplexer:

- Intel integrated GPU at PCI `0000:00:02.0`
- NVIDIA GT 330M at PCI `0000:01:00.0`
- NVIDIA HDA function at PCI `0000:01:00.1`
- Apple classic gmux

The internal LCD can be driven through either GPU. Linux therefore sees a **muxed** rather than a simple muxless-PRIME laptop.

## Linux components

### i915 + Crocus

The Intel GPU uses the kernel `i915` driver and the Mesa Crocus userspace driver. Direct host Mesa testing proved that this path is hardware accelerated and usable.

### Nouveau

The NVIDIA GPU uses Nouveau. Basic 3D and PRIME offload work, but Chromium can trigger GT216/NVA5 graphics errors. Legacy NVIDIA 340 is not a viable modern-Ubuntu solution.

### apple_gmux and vga_switcheroo

`apple_gmux` exposes the physical multiplexer to `vga_switcheroo`.

Typical default firmware state on the tested machine:

```text
0:DIS:+:Pwr:0000:01:00.0
1:IGD: :Pwr:0000:00:02.0
2:DIS-Audio: :DynOff:0000:01:00.1
```

`+` means the discrete GPU owns the active display path.

### Xorg

X11 is currently the safe desktop backend. When NVIDIA is firmware/default primary, Xorg can bind NVIDIA as screen 0 and Intel as a secondary GPU provider.

When Intel is explicitly selected as Xorg primary and the display mux is on Intel, desktop operation is smooth and NVIDIA PRIME render offload remains available.

### switcheroo-control

`switcheroo-control` exposes both GPUs to desktop applications and provides `DRI_PRIME` environments. On this machine it currently marks NVIDIA as default because firmware `boot_vga` remains on NVIDIA.

## Target design

The desired architecture is:

```text
Firmware/OpenCore
      |
      v
Intel display path ----------> Xorg / GNOME desktop
      |
      +-----------------------> Crocus (default renderer)

NVIDIA GT 330M
      |
      +-----------------------> PRIME render offload on demand
      |
      +-----------------------> runtime power management when idle
```

If GNOME cannot be made to model the firmware/default semantics correctly, a small manager can present the intended policy without pretending firmware state has changed.
