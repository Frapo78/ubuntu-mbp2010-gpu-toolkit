# Roadmap

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

## Phase 2 — permanent Intel-primary desktop

- [ ] Build a boot-safe service/configuration that moves the display path to Intel before the graphical session
- [ ] Persist Xorg Intel `PrimaryGPU`
- [ ] Ensure only one internal LVDS output is active
- [ ] Confirm normal suspend/resume and external display behaviour
- [ ] Confirm Chromium uses a stable path by default

## Phase 3 — native dedicated-GPU launching

- [ ] Determine whether `switcheroo-control` can be taught the intended default policy despite firmware `boot_vga`
- [ ] Verify GNOME “Launch using Dedicated Graphics Card”
- [ ] Preserve explicit `DRI_PRIME=pci-0000_01_00_0` as the ground-truth fallback

## Phase 4 — power management

- [ ] Measure whether Xorg holds the NVIDIA card in a way that prevents runtime suspend
- [ ] Test `power/control=auto` for NVIDIA GPU and HDA
- [ ] Verify automatic resume during PRIME workloads
- [ ] Verify return to suspended state after the workload exits

## Phase 5 — user-facing manager

If native GNOME semantics remain wrong:

- [ ] GTK4/libadwaita status application
- [ ] “Intel / Automatic / NVIDIA app” modes
- [ ] one-click dedicated-GPU launcher
- [ ] current gmux and runtime-power status
- [ ] optional polkit helper for privileged operations
- [ ] no hidden destructive EFI writes

## Phase 6 — broader compatibility

- [ ] Detect related 2010 MacBook Pro models
- [ ] Separate model-specific quirks from shared logic
- [ ] Add automated report redaction
- [ ] Add tests using saved diagnostic fixtures
- [ ] Package as `.deb` or a self-contained installer only after the core policy is proven
