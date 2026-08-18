# Package architecture

The end product should be more than documentation plus shell scripts. This document defines the intended structure so future humans and agents add features in a consistent way.

## User-facing workflow

The future toolkit should guide a machine through these stages:

```text
DETECT
  -> DIAGNOSE
     -> CLASSIFY
        -> CHECKPOINT
           -> REMEDIATE
              -> REBOOT IF REQUIRED
                 -> POSTCHECK
                    -> REPORT / ROLLBACK / COMPLETE
```

Each stage should produce machine-readable state that the next stage can consume.

## Layers

### 1. Hardware profiles

Directory:

```text
profiles/
```

Contains model-specific facts such as PCI IDs, gmux topology, known safe baselines and prohibited actions.

No mutation logic belongs in a hardware profile.

### 2. Knowledge base

Directory:

```text
knowledge/
```

Contains known symptoms, evidence signatures, diagnosis text, maturity status and safe next directions.

This is the primary interface for troubleshooting agents.

### 3. Diagnostics

Directory:

```text
scripts/
```

Stable diagnostics should be safe to run repeatedly and should minimize unrelated private data.

A future unified command could look like:

```text
mbp-ubuntu diagnose
mbp-ubuntu status
```

### 4. Remediation actions

Stable remediations should eventually live under a dedicated directory, for example:

```text
actions/
```

Each action should declare:

- supported profiles;
- required current state;
- risk level;
- files/devices touched;
- checkpoint logic;
- apply logic;
- rollback logic;
- postcheck logic;
- maturity status.

### 5. Experimental actions

Current location:

```text
scripts/experimental/
```

Experimental code must remain impossible to confuse with the normal stable path.

### 6. Orchestrator / UI

Long term, a small application or CLI can consume profiles + knowledge + actions.

Possible interfaces:

```text
mbp-ubuntu diagnose
mbp-ubuntu fix duplicate-display
mbp-ubuntu gpu status
mbp-ubuntu gpu launch --nvidia chromium
mbp-ubuntu recover
```

If GNOME's native dedicated-GPU semantics cannot represent the intended policy, a GTK4/libadwaita UI can wrap the same action layer rather than duplicating logic.

## Action contract

A stable action should eventually expose an equivalent conceptual contract:

```yaml
id: example-action
supports:
  - MacBookPro6,2
risk: medium
requires:
  session: x11
touches:
  - /etc/example.conf
checkpoint: required
apply: ...
rollback: ...
postcheck: ...
status: stable
```

The exact implementation format can evolve, but the semantics should remain.

## Fail-closed behaviour

If a profile does not match, an action should refuse to run rather than attempt to be helpful.

Examples of mismatches that should stop model-specific GPU actions:

- unexpected DMI model;
- expected PCI GPU missing;
- wrong driver bound;
- `vga_switcheroo` unavailable when required;
- unknown existing persistent Xorg override;
- unexpected EFI variable state;
- rollback checkpoint cannot be created.

## Idempotence

Stable actions should, where practical, be idempotent:

- running diagnostics repeatedly should never change state;
- applying a fix that is already present should report `already satisfied`;
- cleanup should not remove unknown user configuration;
- rollback should restore exactly what the action changed.

## Packaging target

Do not package as a `.deb` or one-command installer until the core GPU policy reaches `stable` maturity.

When it does, packaging should include:

- CLI/orchestrator;
- profiles;
- knowledge base;
- stable actions;
- rollback state directory;
- optional GTK frontend;
- versioned diagnostic report format;
- uninstall/revert path.
