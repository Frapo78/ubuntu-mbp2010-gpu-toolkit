# Packages and offline rescue bundles

This directory defines the Ubuntu packages used by the toolkit.

The repository intentionally does **not** commit binary `.deb` packages. Binary packages become stale quickly, some are kernel-version dependent, and `linux-firmware` alone is hundreds of megabytes.

Instead the project stores:

- versioned package manifests;
- package-set maturity and safety metadata;
- an online bundle builder that downloads packages and dependency closure from Ubuntu archives;
- an offline installer that uses the USB bundle as a temporary local APT repository;
- SHA-256 checksums and bundle metadata.

A generated USB bundle can therefore contain the actual `.deb` files while Git remains small and auditable.

## Package classes

- `runtime_core` — packages expected to be useful in the supported stable baseline.
- `diagnostics` — tools used to identify hardware and failures; installing them should not change drivers or boot policy.
- `integration` — utilities for Apple-specific input/backlight/network/audio/power integration.
- `conditional_driver` — driver packages that must only be installed after hardware/driver classification.
- `optional_ui` — convenience applications, never required for recovery.
- `experimental` — packages whose daemon/policy can change hardware behavior; never installed automatically.

## Important Broadcom rule

Do not blindly install both the proprietary Broadcom STA (`wl`) and the open `b43` path.

`firmware-b43-installer` is especially important for offline rescue: the package itself is only an installer and normally downloads proprietary firmware during installation. A USB bundle is not considered `b43-offline-complete` unless a firmware payload has also been captured into `firmware/b43/` by the bundle builder.

## Kernel-provided Apple support

Some of the most important MacBook integration components are kernel drivers, not separate Ubuntu packages:

- `bcm5974` — Apple multitouch trackpad
- `hid_apple` — Apple keyboard/HID behavior
- `applesmc` — Apple SMC sensors and platform integration
- `apple_gmux` — graphics multiplexer
- `btusb` — common USB Bluetooth transport
- `uvcvideo` — USB video class camera path when applicable

The package lists therefore include diagnostic/control utilities without pretending that installing those utilities provides the underlying kernel driver.

## Manifests

Current reference manifest:

- `manifests/noble-amd64.json`

The manifest is intentionally conservative. Other Ubuntu releases and Mac models need their own validated manifests or explicit compatibility evidence.
