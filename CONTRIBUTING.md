# Contributing

This project accepts contributions from humans and AI-assisted/agentic workflows, but all changes must preserve the repository's evidence and safety discipline.

## Reporting a problem

Use the structured **Diagnostic / compatibility problem** issue form.

If Ubuntu is usable, attach a redacted report from:

```bash
chmod +x scripts/collect-diagnostics.sh
./scripts/collect-diagnostics.sh
```

Include at minimum:

- exact Mac model identifier;
- Ubuntu release;
- kernel;
- X11 or Wayland;
- GPU PCI IDs;
- gmux / `vga_switcheroo` state;
- `switcherooctl list`;
- last persistent change before the problem;
- whether the issue reproduces before launching Chromium or another GPU-heavy application.

Do not post passwords, tokens, serial numbers, account identifiers, IP/MAC addresses, unnecessary UUIDs, browser profile content or unrelated private logs.

See `docs/reporting.md`.

## Before proposing a fix

Read:

1. `AGENTS.md` if an agent is involved;
2. `docs/status-model.md`;
3. `docs/safety.md`;
4. `knowledge/cases.json`;
5. `docs/failed-experiments.md`.

Do not reintroduce a rejected path without new evidence explaining why the previous rejection no longer applies.

## Contribution types

### Documentation / evidence

Good contributions include:

- a reproduced finding on a second machine;
- a new failure signature;
- correction of an inaccurate support claim;
- a more precise rollback/postcheck;
- upstream documentation that materially changes a diagnosis.

When adding a new finding, update the machine-readable knowledge base when appropriate.

### Hardware profile

A new profile under `profiles/` should include measured hardware/topology facts, not guesses based on marketing name.

Also update `docs/support-matrix.md`.

### Stable script/action

A stable mutation must document:

- supported profiles;
- prerequisites;
- risk level;
- exact state/files/devices touched;
- checkpoint behaviour;
- apply behaviour;
- rollback behaviour;
- postcheck;
- idempotent/already-satisfied behaviour where practical.

A change is not stable merely because it worked once.

### Experimental script

Research-grade changes belong in `scripts/experimental/`.

They should:

- fail closed on model/topology mismatch;
- explain the risk;
- create rollback before persistent mutation;
- avoid multiple independent boot-critical changes;
- clean up temporary services/files on failure;
- never be called implicitly by stable quickstart tooling.

## Maturity promotion

Normal progression:

```text
planned -> experimental -> proven -> stable
```

A path can become `rejected` at any point.

When promoting a fix, include the evidence that satisfies the next maturity level.

## Repository checks

Before merging, run:

```bash
python3 tests/test_repository.py
find scripts -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
```

GitHub Actions runs equivalent baseline validation automatically.

## Agent-generated changes

Agent contributions are welcome, but an agent must not claim hardware behaviour it did not observe or that is not supported by repository evidence/upstream documentation.

An agent should leave enough structure that another maintainer can answer:

- What evidence caused this change?
- What hardware does it apply to?
- What happens if it fails?
- How is it rolled back?
- How do we verify success after reboot?

If those answers are missing, the change is not ready.
