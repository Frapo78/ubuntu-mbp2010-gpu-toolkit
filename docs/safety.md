# Safety rules

These rules are intentionally conservative.

1. **Prefer read-only diagnosis before configuration changes.**
2. **One experiment per reboot.**
3. Always create an automatic or immediately available rollback before touching boot-critical configuration.
4. Do not change gmux while Xorg, GNOME, Chromium, WirePlumber or other clients still hold DRM/audio devices.
5. Keep a working X11 route until the Wayland failure is understood.
6. Never install NVIDIA 340 on current Ubuntu for this machine.
7. Do not use Nouveau performance-state overclocking as a workaround.
8. Treat EFI-variable writes as high risk and hardware/firmware-specific.
9. Do not mix an OpenCore upgrade and a GPU-policy change in the same reboot.
10. Experimental scripts belong in `scripts/experimental/` and should never be presented as general fixes.

## Recovery assets to keep

- known-good EFI backup
- matching OpenCore `ocvalidate`
- rollback script for any OpenCore update
- copy of `/etc/gdm3/custom.conf`
- copy of `/etc/default/grub`
- copy of `/etc/X11/xorg.conf.d`
- diagnostic report from the last known-good boot
