# Operational runbook

This is the standard workflow for humans or agents handling a new report.

## Phase A — intake

Record:

- exact Mac model identifier;
- Ubuntu release;
- kernel;
- whether the session is X11 or Wayland;
- whether the machine currently boots normally;
- the last persistent change made before the problem;
- the exact symptom and when it begins;
- whether the symptom is reproducible without launching Chromium or other GPU-heavy apps.

Do not start with a fix.

## Phase B — evidence capture

Run:

```bash
chmod +x scripts/collect-diagnostics.sh
./scripts/collect-diagnostics.sh
```

Preserve the report from the current state before making changes.

For severe freezes, collect the **previous boot** journal after recovering:

```bash
journalctl -b -1 -k --no-pager
```

## Phase C — classify

Use:

- `docs/quick-triage.md`
- `docs/decision-tree.md`
- `knowledge/cases.json`

If a known case matches, state the case ID explicitly.

If no known case matches, create a new investigation record rather than forcing the symptoms into an existing diagnosis.

## Phase D — choose the least invasive action

Preferred order:

1. read-only confirmation;
2. session-only change;
3. reversible userspace configuration;
4. persistent Xorg/GDM/systemd configuration;
5. kernel command-line change;
6. gmux/power transition;
7. EFI/OpenCore/NVRAM change.

Escalate only as high as needed.

## Phase E — checkpoint

Before persistent changes, save the affected state.

Typical checkpoint items:

```text
/etc/gdm3/custom.conf
/etc/default/grub
/etc/X11/xorg.conf.d/
relevant systemd units
/boot/efi/EFI/
current diagnostic report
```

A rollback command/script should exist **before** the risky action runs.

## Phase F — apply one change

One independent hypothesis per change/reboot.

Bad example:

- update OpenCore;
- change `gpu-power-prefs`;
- make Intel PrimaryGPU;
- alter Nouveau power management;
- reboot once.

If that fails, there is no clean causal signal.

Good example:

- stage and validate OpenCore update;
- install it;
- reboot;
- postcheck;
- only then start a separate GPU experiment.

## Phase G — postcheck

A fix is not established because the desktop appeared once.

Check as applicable:

```bash
cat /proc/cmdline
switcherooctl list
sudo cat /sys/kernel/debug/vgaswitcheroo/switch
xrandr --listproviders
xrandr --listactivemonitors
journalctl -b -k --no-pager
```

For renderer checks, distinguish default renderer from explicit PRIME renderer.

Confirm:

- boot completed;
- expected display server is in use;
- expected GPU owns the display/render role;
- duplicate outputs are absent or intentionally disabled;
- no new i915/Nouveau fault storm appeared;
- expected secondary GPU remains available;
- rollback is still usable if the next reboot differs.

## Phase H — update repository knowledge

If the result changes what is known, update the repository in the same troubleshooting cycle.

### New successful evidence

Update:

- `docs/findings.md`;
- `docs/investigation-timeline.md`;
- the corresponding `knowledge/cases.json` entry;
- `docs/reference-checkpoint.md` when the stable machine state changes.

### Failed experiment

Update:

- `docs/failed-experiments.md`;
- case status/avoid rules if relevant;
- experimental script with the failure guard if the script remains useful.

### New reusable fix

A new fix should not go directly to the normal quickstart. Move it through:

`experimental -> proven -> stable`

using the criteria in `docs/status-model.md`.

## Phase I — closeout

A troubleshooting cycle is complete when:

- machine state is known;
- any persistent changes are documented;
- rollback exists or is no longer needed;
- findings are captured;
- next unresolved hypothesis is explicit.
