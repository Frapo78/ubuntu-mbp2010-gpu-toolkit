# Ubuntu system baseline beyond graphics

Graphics is the hardest part of this project, but the reference MacBookPro6,2 investigation also exposed ordinary Ubuntu compatibility and maintenance issues. They are documented here so humans/agents can distinguish a GPU problem from an unrelated system problem.

These entries are **reference-machine findings**, not automatic fixes for every MacBook Pro.

## Touchpad / click behaviour

The reference machine uses the Apple `bcm5974` touchpad through libinput.

A persistent X11 configuration was used for clickfinger behaviour:

```ini
Section "InputClass"
    Identifier "Apple bcm5974 clickfinger"
    MatchDriver "libinput"
    MatchProduct "bcm5974"
    Driver "libinput"
    Option "ClickMethod" "clickfinger"
EndSection
```

Reference path:

```text
/etc/X11/xorg.conf.d/90-bcm5974-clickfinger.conf
```

The machine also has a mechanically less responsive physical left-click area, so agents should distinguish **input configuration** from **hardware click mechanics** before modifying libinput.

## Chromium packaging

The reference machine moved Chromium from Snap to Flatpak while preserving the existing browser profile and making the Flatpak build the normal launcher/default browser.

Important lesson for diagnosis:

- browser packaging/runtime can change ANGLE/Mesa behaviour;
- a Chromium GPU failure must not automatically be classified as a kernel GPU failure;
- reproduce with host Mesa tools before changing graphics drivers.

## Snap / mesa content snap resource use

A high-memory snap-related state was improved on the reference machine after refreshing the relevant Mesa content snap (`mesa-2404`).

Do not remove snapd globally merely because one snap revision or content snap behaves badly. First identify the exact process/revision and whether an update resolves it.

## SSD / trim

The reference machine uses a SATA SSD and has periodic `fstrim` enabled.

For similar installations verify rather than assume:

```bash
systemctl status fstrim.timer
lsblk -o NAME,MODEL,FSTYPE,SIZE,MOUNTPOINTS
```

Do not add continuous `discard` or other storage tuning automatically without checking the filesystem/device.

## Battery

The reference battery is aged rather than new. Battery health should therefore be treated as a separate source of thermal/runtime behaviour rather than attributing all power symptoms to GPU switching.

Useful generic checks:

```bash
upower -i "$(upower -e | grep BAT | head -1)"
```

Record energy-full vs design capacity and cycle count when available.

## Optical drive / audio tools

The reference optical drive works under Ubuntu. Audio-CD/ripping/burning tools were configured successfully, so a missing application or codec should not be confused with a hardware/ATA failure without checking the device first.

Useful checks:

```bash
lsblk
lspci -nnk | grep -A3 -Ei 'audio|sata|ide'
```

## Rule for expanding this section

Add a non-GPU fix here only when at least one of these is true:

- it was reproduced on the reference Mac;
- it is required by the compatibility toolkit;
- it prevents a common false diagnosis of a GPU/boot problem.

For model-specific persistent fixes, create a dedicated script only after the same `experimental -> proven -> stable` maturity process used by the GPU work.
