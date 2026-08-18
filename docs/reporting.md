# Diagnostic reporting and redaction

Good reports shorten diagnosis. Huge unfiltered logs often make diagnosis slower.

## Minimum report contents

For graphics/boot issues capture:

- timestamp;
- DMI model;
- Ubuntu/kernel;
- kernel command line;
- X11 vs Wayland;
- GPU PCI IDs and active drivers;
- `boot_vga` for both GPUs;
- `apple_gmux` / `vga_switcheroo` state;
- `switcherooctl list`;
- DRM nodes;
- Xorg providers and connected outputs when on X11;
- OpenCore version when available;
- GDM Wayland setting;
- relevant current-boot kernel errors;
- for reboot regressions, relevant previous-boot errors.

`scripts/collect-diagnostics.sh` is the normal starting point.

## Correlate timestamps

Always record when the user observed the symptom and when an application was launched.

A later Chromium-triggered Nouveau error does not explain an earlier display-manager glitch unless timestamps support that relationship.

## Do not publish secrets or unnecessary identity data

Before attaching a report publicly, review it for:

- usernames/home paths when unnecessary;
- serial numbers;
- filesystem UUIDs/PARTUUIDs when unnecessary;
- MAC addresses;
- IP addresses;
- email addresses;
- API keys/tokens;
- browser profile content;
- EFI serial/spoofing values;
- unrelated application logs.

If a value is needed to compare consistency but not identity, replace it with a stable placeholder such as:

```text
<REDACTED_SERIAL>
<REDACTED_PARTUUID>
<USER_HOME>
```

## Prefer focused evidence

Examples:

```bash
journalctl -b -k --no-pager \
  | grep -Ei 'i915|nouveau|apple.?gmux|vga_switcheroo|drm|GPU HANG|DATA_ERROR|INVALID_VALUE'
```

For a previous failed boot:

```bash
journalctl -b -1 -k --no-pager \
  | grep -Ei 'i915|nouveau|apple.?gmux|vga_switcheroo|drm|GPU HANG|DATA_ERROR|INVALID_VALUE'
```

Do not repeatedly run OCR or screenshot-based log extraction when machine-readable text is available.

## Agent reporting format

Agents should summarize a report as:

```text
Model:
OS/kernel:
Session:
Last persistent change:
Symptom time:
Matched known case:
Evidence:
Contradicting evidence:
Risk:
Next action:
Rollback:
Required postcheck:
```

This structure should be preferred over a long narrative when handing the case to another agent or maintainer.
