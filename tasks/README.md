# Tasks

Short-lived TODO checklists per feature, written via the `/plan` workflow.

## Naming

`todo-<feature-slug>.md` — same slug as the corresponding spec/plan.

## Format

```markdown
# TODO: <Feature>

> Plan: docs/plans/YYYY-MM-DD-<feature>.md

## Phase 1: Foundation
- [ ] T1.1: ...
- [ ] T1.2: ...

## Checkpoint: Foundation complete

## Phase 2: Core features
- [ ] T2.1: ...
- [ ] T2.2: ...

## Checkpoint: MVP complete
```

## Lifecycle

- Created by `/plan`.
- Updated by `/build` as tasks tick off.
- Deleted (or archived) once the feature is fully shipped + verified.

## Conventions

- One file per feature, not per dev session.
- Don't put long discussion / design rationale here — that lives in the spec/plan/ADR.
- A todo file with > 30 unchecked items is a smell — the feature is too big, split it.
