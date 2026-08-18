# Machine-readable knowledge

This directory is intended for tooling and troubleshooting agents as well as maintainers.

## Files

- `cases.json` — known symptom/evidence/diagnosis/safe-direction cases
- `evidence.json` — ledger of reproduced conclusions from the reference investigation

## Rules

### Cases are diagnostic objects, not generic advice

A case should contain enough evidence signals to avoid matching solely on a vague symptom.

Prefer:

```text
symptom + machine state + timestamps + driver/session signals
```

over:

```text
"screen froze" -> apply fix
```

### Status must use repository vocabulary

Use only:

- `stable`
- `proven`
- `experimental`
- `rejected`
- `planned`

See `docs/status-model.md`.

### Negative evidence matters

A failed/rejected path belongs in the knowledge base when it prevents repeated unsafe work.

Example: correct-format `gpu-power-prefs` runtime creation returned `EINVAL` on the reference machine. Agents should therefore stop retrying it automatically rather than interpreting absence of the variable as permission to try again.

### Paths must resolve

Documentation/script paths referenced by `cases.json` are validated by `tests/test_repository.py`.

### Do not encode secrets

Machine-readable knowledge should describe topology and behaviour, not contain serial numbers, account IDs, tokens, private UUIDs or raw unredacted logs.

## Future direction

As the toolkit matures, cases can become inputs to a unified classifier/CLI. Keep the format declarative enough that diagnosis does not depend on parsing human prose from the investigation timeline.
