# MacBook Pro 2010 hardware integration

The toolkit is broader than graphics. The final package should help a user reach a stable Ubuntu installation where the MacBook-specific hardware is discoverable, diagnosable and, where appropriate, configured automatically.

The reference platform remains **MacBookPro6,2 (15-inch Mid 2010)**. Similar models must be measured before inheriting model-specific actions.

## Trackpad

The Apple multitouch trackpad is supported by the Linux kernel `bcm5974` driver. Userspace behavior is normally handled by libinput.

### What the toolkit should check

- `bcm5974` module loaded or bound to the expected USB device;
- device visible under `/dev/input/event*`;
- libinput identifies it as a touchpad/clickpad;
- tap/click/scroll settings;
- X11 configuration overrides that may conflict with GNOME settings;
- physical click behavior separately from software gesture behavior.

### Useful packages

- `libinput-tools`
- `evtest`
- `xinput` for the X11 baseline

These packages are diagnostic/configuration tools; they do not replace `bcm5974`.

## Keyboard and function keys

Apple keyboard behavior commonly involves the kernel HID stack, including `hid_apple` where applicable. The toolkit should inspect the actual input device and loaded modules before changing function-key semantics.

Potential checks:

- Apple keyboard USB/HID identity;
- `hid_apple` module parameters;
- GNOME media-key handling;
- duplicate hotkey handlers;
- function/media key expectations.

Ubuntu still packages `pommed`, an Apple-laptop hotkey handler, but it is classified **experimental** here because a second userspace hotkey daemon can conflict with modern GNOME handling. It must not be installed automatically.

## Keyboard backlight

When the kernel/platform driver exposes keyboard lighting correctly, userspace should find an LED-class endpoint ending in `kbd_backlight` under `/sys/class/leds/`.

The toolkit should:

1. discover all `*:kbd_backlight` endpoints;
2. record `brightness` and `max_brightness`;
3. verify write capability through supported userspace controls;
4. correlate keyboard brightness keys with actual LED changes.

Useful package:

- `brightnessctl`

No custom backlight daemon should be installed merely because brightness keys do not work; first establish whether the kernel LED endpoint exists.

## Display brightness

The display-backlight path depends on which GPU/display route is active. The toolkit should enumerate `/sys/class/backlight/`, identify the active display path, and avoid mixing display-brightness troubleshooting with keyboard LED troubleshooting.

`brightnessctl` is useful for both discovery and control where the kernel exposes a supported sysfs class device.

## Wi-Fi

Broadcom wireless requires exact hardware classification.

The toolkit must collect:

- PCI vendor/device ID;
- current kernel driver and candidate modules;
- rfkill state;
- `iw` interface/PHY information;
- NetworkManager state if available;
- firmware/module errors from the current boot.

### Driver policy

Do **not** install Broadcom STA (`wl`) and `b43` indiscriminately.

Two offline package sets are provided:

- `wifi_broadcom_sta`: `broadcom-sta-dkms`, DKMS and matching kernel headers;
- `wifi_b43_tools`: `b43-fwcutter` and the Ubuntu firmware installer tooling.

The actual selection must come from the hardware profile / knowledge case. A future support matrix may map validated PCI IDs to a preferred path.

### Important offline caveat for b43

Ubuntu's `firmware-b43-installer` normally fetches proprietary firmware during package installation. A USB bundle is therefore not considered a complete b43 repair kit unless the online bundle-building step has also captured a usable `firmware/b43/` payload. The repository will not redistribute proprietary firmware blindly.

## Bluetooth

The normal userspace stack is BlueZ; common USB adapters use the kernel `btusb` path.

The toolkit should check:

- USB Bluetooth controller identity;
- `btusb` binding;
- `rfkill` soft/hard blocks;
- `bluetooth.service`;
- `bluetoothctl show` / controller availability;
- firmware errors in the kernel journal.

Packages:

- `bluez` — runtime stack
- `bluez-firmware` — available as an additional firmware package when actually required
- `blueman` — optional diagnostic/convenience GUI, not required by GNOME

## Audio

The project should distinguish kernel/ALSA device detection from PipeWire/GNOME routing.

Useful diagnostics:

- `aplay -l`
- `arecord -l`
- mixer state
- PipeWire/WirePlumber devices

Packages:

- `alsa-utils`
- `pavucontrol` as optional UI

## Camera / iSight path

Do not assume a camera driver from the Mac model name alone. Enumerate USB/video devices first.

Useful package:

- `v4l-utils`

The expected modern first check is whether a usable `/dev/video*` device exists and which kernel driver owns it.

## Battery and power

The reference machine has an aging battery, so the toolkit should report health without applying aggressive power-management policy automatically.

Useful tools:

- `upower`
- `acpi`
- `powertop`

Do not automatically install or enable competing laptop power-policy daemons until interactions with GNOME/Ubuntu power management have been tested.

## Sensors and fans

`applesmc` is central to Apple SMC sensor/fan visibility when supported.

Useful diagnostics:

- `sensors`
- sysfs Apple SMC entries
- fan RPM/min/max exposure
- CPU/GPU thermal throttling evidence

Packages:

- `lm-sensors`
- `mbpfan` and `macfanctld` exist in Ubuntu, but both are classified **experimental** in this project. They alter fan policy and must never be installed together or enabled automatically without model-specific thermal validation.

## Storage and optical drive

Useful packages:

- `smartmontools` for SATA SSD/HDD health
- `udisks2` / `eject` for optical-media integration
- optional optical/audio workflow: `asunder`, `lame`, `flac`, `k3b`

The toolkit should treat filesystem/SMART health separately from graphical or power symptoms.

## Firmware baseline

`linux-firmware` is included in the full rescue bundle because it provides firmware for many kernel drivers. It is intentionally large. A minimal diagnostic USB may omit it; a full recovery USB should include it.

## Maturity rule

A package existing in Ubuntu is not enough to make it a recommended fix.

Each integration action must still follow:

`planned -> experimental -> proven -> stable`

and model-specific daemons/drivers must be gated by measured hardware state.
