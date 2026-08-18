# Human / agent troubleshooting handoff

Use this format when pausing work, transferring a case to another maintainer/agent, or resuming after a reboot.

The handoff should describe the **current machine state**, not retell the entire conversation.

## Compact template

```text
CASE
  Machine model:
  Ubuntu/kernel:
  Session:
  Toolkit profile:

CURRENT STATE
  Boots normally: yes/no
  Intel driver/boot_vga:
  NVIDIA driver/boot_vga:
  gmux/vga_switcheroo:
  switcheroo-control default:
  Active display/output layout:
  OpenCore version:

SYMPTOM / GOAL
  Exact symptom or desired next state:

MATCHED KNOWLEDGE
  Case ID(s):
  Evidence ID(s):
  Contradicting evidence:

LAST PERSISTENT CHANGE
  What changed:
  Checkpoint location:
  Rollback:

RESULT OF LAST TEST
  Observed:
  Kernel/Xorg errors:
  Was cleanup successful:

RISK STATE
  Stable / proven / experimental / rejected / planned:
  Known hazards:

NEXT SINGLE ACTION
  Hypothesis:
  Script/action:
  Expected success signal:
  Expected failure signal:
  Required postcheck:

REPOSITORY UPDATE REQUIRED
  yes/no
  Files/issues to update:
```

## Reference-machine handoff at current checkpoint

```text
CASE
  Machine model: MacBookPro6,2
  Ubuntu/kernel: Ubuntu 24.04.4 LTS / 7.0.0-29-generic
  Session: X11
  Toolkit profile: profiles/MacBookPro6,2.json

CURRENT STATE
  Boots normally: yes
  Intel: i915/Crocus, boot_vga=0
  NVIDIA: Nouveau/NVA5, boot_vga=1
  gmux/vga_switcheroo: working, DIS currently firmware/display default
  switcheroo-control: NVIDIA Default=yes, Intel Default=no
  Display: 1440x900 after duplicate LVDS disabled session-only
  OpenCore: 1.0.7
  gpu-power-prefs: absent

SYMPTOM / GOAL
  Make Intel the persistent normal desktop/display path while preserving NVIDIA PRIME on demand.

MATCHED KNOWLEDGE
  Cases:
    - nvidia-default-because-boot-vga
    - intel-primary-nvidia-prime
    - gpu-power-prefs-einval (rejected path)
  Evidence:
    - E003 through E011 as applicable

LAST PERSISTENT CHANGE
  OpenCore 1.0.7 was installed and validated earlier.
  Final freeze/stable step left no experimental Xorg override or gpu-power-prefs residue.

RESULT OF LAST TEST
  Runtime EFI creation of gpu-power-prefs with correct attributes+DWORD was rejected with EINVAL; cleanup succeeded.
  switcheroo-control probe confirmed the daemon is healthy and follows firmware/default semantics.

RISK STATE
  Stable baseline: X11 + current NVIDIA firmware default.
  Proven but not persistent: Intel-primary + NVIDIA PRIME.
  Rejected: gpu-power-prefs automation path.

NEXT SINGLE ACTION
  Issue #1: design a boot-safe, reversible pre-GDM Intel display-routing + Intel-primary Xorg action.
  Do not start runtime PM until that is postchecked.

REPOSITORY UPDATE REQUIRED
  Yes: every new test result must update evidence/findings/timeline/case maturity as needed.
```
