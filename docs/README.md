# Documentation index

## Solve a problem quickly

- `quick-triage.md` — symptom-first known cases
- `decision-tree.md` — choose the least-risk diagnostic branch
- `runbook.md` — full intake → evidence → fix → rollback → postcheck workflow
- `reporting.md` — collect and redact useful reports
- `handoff.md` — resume or transfer a troubleshooting case without replaying chat history

## Understand the hardware and current evidence

- `architecture.md` — Intel/NVIDIA/gmux/Xorg/PRIME architecture
- `findings.md` — reproduced technical conclusions
- `investigation-timeline.md` — chronological engineering record
- `reference-checkpoint.md` — last known-good reference-machine state
- `system-baseline.md` — non-GPU Ubuntu findings from the same machine

## Safety and scope

- `status-model.md` — stable / proven / experimental / rejected / planned
- `safety.md` — operational safety rules
- `failed-experiments.md` — paths that should not be repeated without new evidence
- `support-matrix.md` — supported/tested hardware and capabilities
- `source-policy.md` — distinguish machine evidence, upstream documentation and inference
- `opencore.md` — staged OpenCore update methodology

## Build the final toolkit

- `project-charter.md` — mission and end-state
- `package-architecture.md` — profiles/knowledge/actions/orchestrator architecture
- `roadmap.md` — development phases
- `resume-point.md` — exact next engineering task

## Machine-readable companions

Human documentation is complemented by:

- `../profiles/`
- `../knowledge/`
- `../AGENTS.md`
- `../tests/`

Do not extract one command from a document and ignore its maturity status, hardware scope or rollback requirements.
