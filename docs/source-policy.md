# Evidence and upstream source policy

The project combines real-machine evidence with upstream documentation. Those are not the same thing and must stay distinguishable.

## Source classes

### A. Reference-machine evidence

Directly observed on the investigated MacBookPro6,2.

Examples:

- specific `boot_vga` values;
- a successful Intel-primary Xorg test;
- a specific Nouveau error after Chromium launch;
- a failed EFI-variable write;
- a successful OpenCore reboot.

These should be recorded in `knowledge/evidence.json` and, when reusable, in `knowledge/cases.json`.

### B. Upstream authoritative documentation

For technical behavior, prefer primary sources such as:

- Linux kernel documentation/source;
- Ubuntu documentation/package data;
- Mesa documentation;
- GNOME / switcheroo-control upstream;
- Acidanthera OpenCore documentation/source;
- official project issue trackers when they are the only authoritative record of a hardware-specific limitation.

Use upstream sources to explain mechanisms, not to overwrite contradictory machine evidence silently.

### C. Inference

Sometimes evidence supports a likely explanation without directly proving every link.

Label it as inference until another test confirms it.

Example pattern:

```text
Observed A + observed B strongly suggests C.
C remains an inference until test D distinguishes it from alternative E.
```

### D. Community reports

Community reports can identify hypotheses or additional hardware cases, but should not directly promote a fix to `stable`.

Require reproduction or authoritative mechanism evidence.

## Claim discipline

A documentation statement should make clear whether it means:

- "Linux upstream says this mechanism works this way";
- "the reference Mac reproduced this behavior";
- "a second model also reproduced it";
- "this is our current hypothesis".

Avoid broad statements such as "2010 MacBook Pros do X" when only MacBookPro6,2 has been tested.

## Updating a known case

When new evidence contradicts an existing case:

1. do not delete the old evidence;
2. record the new environment/model/version;
3. determine whether the case needs narrower applicability;
4. update support matrix/profile gating;
5. only then revise the safe direction.

## Current important upstream-informed constraints

The original investigation used upstream material to reason about:

- `vga_switcheroo` and Apple gmux behavior;
- the role of Apple's `gpu-power-prefs` variable;
- efivarfs data format;
- OpenCore version-matched `ocvalidate`;
- OpenCore update staging and rollback expectations.

The repository records the **machine outcomes** separately so future maintainers do not confuse documented capability with successful behavior on this exact firmware/hardware combination.
