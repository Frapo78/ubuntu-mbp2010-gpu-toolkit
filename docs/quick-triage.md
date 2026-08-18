# Quick triage — start here

This page is optimized for the first 5–15 minutes of a troubleshooting session.

## 0. Identify the machine before fixing it

Run:

```bash
cat /sys/devices/virtual/dmi/id/product_name
uname -a
printf 'session=%s\n' "$XDG_SESSION_TYPE"
lspci -nnk | grep -A4 -Ei 'VGA|3D|Display|Network'
```

For the fully investigated reference path, the expected model is:

```text
MacBookPro6,2
```

If the model differs, collect diagnostics and use the repository as evidence, not as permission to run model-specific scripts blindly.

## 1. Best first commands

Graphics/system report:

```bash
chmod +x scripts/collect-diagnostics.sh
./scripts/collect-diagnostics.sh
```

Whole-Mac integration report (trackpad, keyboard LEDs, Wi-Fi, Bluetooth, audio, camera, battery, sensors, storage):

```bash
chmod +x scripts/integration-probe.sh
./scripts/integration-probe.sh
```

Use the reports to match `knowledge/cases.json` or `knowledge/integration-cases.json`.

---

## Symptom: no Internet / Wi-Fi is broken and packages are needed now

Do not start guessing Broadcom drivers from the MacBook name.

### Fast checks

```bash
lspci -nnk | grep -A5 -Ei 'Network|Wireless|Broadcom'
rfkill list
iw dev
journalctl -b -k --no-pager | grep -Ei 'b43|brcm|broadcom|\bwl\b|firmware.*(wifi|wlan)'
```

If the machine is offline but a toolkit USB bundle is available:

```bash
./scripts/offline/verify-bundle.sh /path/to/bundle
./scripts/offline/install-bundle.sh /path/to/bundle --dry-run
```

The default installer only applies stable runtime/diagnostic package sets. Broadcom STA or b43 sets require explicit selection and experimental consent after classification.

See `docs/offline-rescue.md`, `docs/hardware-integration.md` and integration case `I003`.

---

## Symptom: trackpad missing, gestures/clicks wrong, or keyboard behavior odd

First determine whether this is kernel device detection, libinput configuration or a physical issue.

```bash
lsmod | grep -E 'bcm5974|hid_apple'
grep -Ei 'Name=|Handlers=|Phys=' /proc/bus/input/devices
libinput list-devices
```

The Apple multitouch trackpad path is normally the kernel `bcm5974` driver. `libinput-tools`, `evtest` and `xinput` help diagnose it; they are not replacement kernel drivers.

For function/media keys inspect `hid_apple` and actual events before adding legacy hotkey daemons such as `pommed`.

See integration cases `I001` and `I005`.

---

## Symptom: keyboard backlight or brightness keys do not work

Separate keyboard LEDs from display backlight.

```bash
find /sys/class/leds -maxdepth 1 -type l -printf '%f\n' 2>/dev/null
find /sys/class/backlight -maxdepth 1 -type l -printf '%f\n' 2>/dev/null
lsmod | grep -E 'applesmc|hid_apple'
```

If an LED endpoint ending in `kbd_backlight` exists, test it through `brightnessctl` before installing a separate daemon.

If no endpoint exists, installing a userspace brightness tool cannot create the missing kernel/platform device.

See integration case `I002`.

---

## Symptom: Bluetooth toggle/controller is missing

```bash
lsusb
lsmod | grep btusb
rfkill list bluetooth
systemctl status bluetooth.service --no-pager
bluetoothctl show
journalctl -b -k --no-pager | grep -Ei 'bluetooth|btusb|firmware'
```

`bluez` is the userspace runtime. `bluez-firmware` is conditional; install it only if controller identity/logs justify it. `blueman` is optional UI, not a driver fix.

See integration case `I004`.

---

## Symptom: high temperatures or strange fan behavior

Do not immediately install a fan daemon.

```bash
sensors
find /sys/devices/platform -maxdepth 4 \( -iname '*applesmc*' -o -iname '*fan*' -o -iname '*temp*' \) -print
journalctl -b -k --no-pager | grep -Ei 'thermal|thrott|temperature'
```

The project keeps `mbpfan`/`macfanctld` as experimental until model-specific thermal behavior is validated. Never enable both.

See integration case `I006`.

---

## Symptom: audio, camera or optical drive missing

Check whether the kernel sees the device before changing desktop/application configuration.

```bash
aplay -l
arecord -l
v4l2-ctl --list-devices
lsblk
ls -l /dev/sr* /dev/video* 2>/dev/null
```

See integration case `I007` and `docs/hardware-integration.md`.

---

## Symptom: hard freeze after enabling both GPUs

### Fast checks

```bash
printf '%s\n' "$XDG_SESSION_TYPE"
grep -n 'WaylandEnable' /etc/gdm3/custom.conf 2>/dev/null
journalctl -b -k --no-pager | grep -Ei 'nouveau|i915|drm|DATA_ERROR|RT_LINEAR|GPU HANG'
```

### Known reference diagnosis

On MacBookPro6,2, GNOME Wayland multi-GPU initialization was the catastrophic trigger. Both kernel drivers could initialize successfully before the desktop entered the failing path.

### Safe direction

Use X11 as the recovery/stable baseline:

```ini
WaylandEnable=false
```

Do **not** hide the problem with permanent `nomodeset`, because that also removes the Intel KMS path needed for the target architecture.

See `knowledge/cases.json` case `wayland-multigpu-freeze`.

---

## Symptom: desktop is 2880x900 / mouse can move into a phantom second screen

### Fast checks

```bash
xrandr --listactivemonitors
xrandr --query | grep -E 'Screen 0:| connected| disconnected'
```

If the single physical 1440x900 panel is exposed as both `LVDS-1` and another LVDS output, Xorg is seeing the same internal panel through both GPUs.

### Low-risk session fix

Disable only the duplicate logical output for the current X11 session, for example:

```bash
xrandr --output LVDS-1-2 --off
```

Do not assume the duplicate output name is identical on another machine. Inspect `xrandr` first.

Long term, the cleaner solution is Intel-primary + correct display routing.

---

## Symptom: Chromium causes high CPU/GPU load, artifacts or Nouveau errors

### Fast checks

```bash
journalctl -b -k --no-pager | grep -Ei 'nouveau.*(DATA_ERROR|INVALID_VALUE|firmware|msvld)'
sudo fuser -v /dev/dri/renderD128 /dev/dri/renderD129 2>/dev/null
```

Known reference signals include:

```text
nva5_fuc084 failed
nva5_fuc084d failed
msvld: init failed
DATA_ERROR 00000004 [INVALID_VALUE]
```

Do not respond by installing NVIDIA 340 or raising Nouveau clocks.

Also do not conclude that Intel is broken merely because one Chromium/ANGLE launch path fails; host Mesa testing proved Intel i915/Crocus acceleration works on the reference machine.

---

## Symptom: Intel appears present but applications/default desktop still use NVIDIA

### Fast checks

```bash
cat /sys/bus/pci/devices/0000:00:02.0/boot_vga
cat /sys/bus/pci/devices/0000:01:00.0/boot_vga
switcherooctl list
sudo cat /sys/kernel/debug/vgaswitcheroo/switch
```

Reference state:

```text
Intel  boot_vga=0
NVIDIA boot_vga=1
```

`switcheroo-control` then reports NVIDIA as default even though Intel works and PRIME offload works in the opposite direction.

This is a firmware/default-policy issue, not evidence that PRIME is unavailable.

---

## Symptom: want Intel desktop + NVIDIA only when requested

This is the project's main target and is **partially proven, not yet stable**.

Already proven on the reference machine:

1. Intel i915/Crocus is accelerated.
2. gmux can route the panel to Intel.
3. Xorg can use Intel as `PrimaryGPU`.
4. NVIDIA remains available via:

```bash
DRI_PRIME=pci-0000_01_00_0 <application>
```

Do not turn these facts into a permanent boot configuration without following the experimental protocol in `docs/resume-point.md`.

---

## Symptom: boot or OpenCore changed after an update

Do not replace the whole EFI blindly.

Check:

```bash
find /sys/firmware/efi/efivars -maxdepth 1 -iname 'opencore-version-*' -print
```

On the reference machine OpenCore 1.0.7 was staged, checked with the **matching** `ocvalidate.linux`, then installed component-by-component after an EFI backup.

See `docs/opencore.md`.

---

## Symptom: trying to force Intel at firmware boot using `gpu-power-prefs`

Stop before retrying writes automatically.

On the reference Mac, efivarfs was working and OpenCore variables were readable, but correct-format creation of Apple's `gpu-power-prefs` returned `EINVAL` and did not create the variable.

This path is currently `rejected` for automation.

---

## If the symptom does not match

1. collect both graphics/system and integration diagnostics where relevant;
2. preserve timestamps and exact error strings;
3. do not apply multiple speculative changes;
4. search `knowledge/cases.json`, `knowledge/integration-cases.json` and `docs/failed-experiments.md`;
5. if Internet is unavailable, use the offline bundle only for classified actions;
6. open an issue using the repository diagnostic template.
