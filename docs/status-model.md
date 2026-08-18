# Solution maturity model

Every fix, script and recommendation in this repository should carry an explicit maturity state.

## `stable`

Suitable for the normal recovery/compatibility path on the explicitly supported hardware and Ubuntu range.

Requirements:

- repeatable;
- conservative;
- rollback or non-destructive by design;
- no unresolved boot-critical side effects;
- documented preconditions and postcheck.

Examples today:

- read-only diagnostics;
- cleaning known one-shot test residue;
- keeping the reference machine on X11;
- disabling the duplicate logical LVDS output in the current X11 session.

## `proven`

Demonstrated successfully on the reference MacBookPro6,2 but not yet packaged as a normal automatic fix.

Examples today:

- Intel Crocus hardware acceleration;
- Apple gmux switch to Intel;
- Intel-primary Xorg;
- NVIDIA PRIME render offload while Intel is primary.

A `proven` result can become `stable` after persistence, boot/reboot behaviour, rollback and broader side effects are validated.

## `experimental`

A research action with known risk or incomplete coverage.

Requirements:

- live under `scripts/experimental/`;
- exact model/topology checks where possible;
- explicit warning;
- rollback planned before execution;
- never used automatically by quickstart tooling.

## `rejected`

Tested or researched and deliberately excluded from the solution path because it is unsafe, unsupported, misleading or ineffective.

Rejected findings are retained in the repository so future humans/agents do not repeat them.

Examples today:

- NVIDIA 340 on modern Ubuntu;
- permanent `nomodeset`;
- Wayland multi-GPU as the stable baseline on the reference Mac;
- Nouveau clock increases as a workaround;
- repeated runtime `gpu-power-prefs` creation attempts.

## `planned`

Desired behaviour or a proposed implementation that has not yet been proven.

Examples today:

- boot-safe persistent Intel-primary desktop;
- reliable NVIDIA runtime suspend/resume;
- final GNOME dedicated-GPU UX;
- packaged installer/manager.

## Promotion rule

Never promote a status based only on plausibility.

Use this sequence where applicable:

`planned -> experimental -> proven -> stable`

A path can move to `rejected` from any stage when evidence shows that continuing it is unsafe or unproductive.
