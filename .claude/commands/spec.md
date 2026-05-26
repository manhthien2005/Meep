# /spec — Specification-Driven Development

> "Plan the work, then work the plan."

Build a clear spec **before** writing code. Align on requirements, constraints, acceptance criteria.

## The Hard Gate

**Do NOT write any code, do NOT scaffold anything** until a design has been presented and the user has approved it. Every feature — even "simple" ones — goes through this process.

## Pre-flight

1. Read `docs/specs/` to understand context and prior specs.
2. `git status --short` — no uncommitted intentional changes.
3. Read [`docs/specs/2026-05-04-auth.md`](../../docs/specs/2026-05-04-auth.md) — reference spec format (Goal/User stories/Scope/Technical/Security/Testing/Boundaries/Worst path/Risks). Cấu trúc này đã proven qua AUTH module — copy structure khi viết spec module mới.

## Phase 1 — Discovery (one question at a time)

Ask the user **one question at a time**, prefer multiple-choice. Explore:

**Scope:**
- What user pain point does this feature solve?
- Who is the primary user?
- What's the smallest MVP scope? What's OUT-OF-SCOPE?

**Acceptance:**
- Main user flow: step 1 → 2 → 3?
- Important edge cases (offline, no permission, throttling, abuse)?
- What does "done" look like? What can be demoed?

**Technical:**
- Firebase tier constraint (Spark vs Blaze)?
- Specific data privacy concern (PII, location)?
- Integration with existing features?

## Phase 2 — Propose 2-3 approaches

Lead with your recommendation:

```markdown
**Approach A (recommended):** [short name]
- Pros: ...
- Cons: ...
- Effort: ...

**Approach B:** [short name]
- ...
```

Wait for user to choose.

## Phase 3 — Generate the spec doc

Save to `docs/specs/YYYY-MM-DD-<feature-slug>.md`:

```markdown
# Spec: [Feature Name]

**Date:** YYYY-MM-DD
**Status:** Draft
**Owner:** <DevName>

## Goal
[1-2 sentences]

## User stories
- As a [role], I want [action], so that [outcome].

## Scope

### In-scope (MVP)
1. [Feature A] — Acceptance: [specific measurable criterion]

### Out-of-scope
- [thing NOT in this iteration]

## Technical approach

### Architecture
[ASCII diagram or 2-3 sentences]

### Data model
- Firestore collections: ...
- Storage paths: ...

### API / contract
[Cloud Function signature, Firestore query shape]

### Dependencies
- New Flutter packages: [name + version + reason]
- Firebase services: [Auth/Firestore/Storage/FCM/Functions]

## Security
- Firestore rule changes: ...
- PII handling: ...

## Testing strategy
- Unit: ...
- Widget: ...
- Firestore rules tests: owner / friend / stranger / unauthenticated

## Boundaries

### Always do
- [non-negotiable]

### Ask first
- [when caption > 200 chars: truncate or reject?]

### Never do
- [hard constraint]

## Open questions
- [unresolved]

## Risks
- [technical, performance, cost]
```

## Phase 4 — Self-review & user gate

1. **Self-review checklist:**
   - Placeholder scan: "TBD", "TODO", empty sections, vague requirements?
   - Internal consistency: do sections contradict each other?
   - Scope check: focused enough for one implementation plan?
   - Ambiguity: any requirement readable two ways? → pick one, make explicit.

2. **Commit the spec:**
   ```bash
   git add docs/specs/<file>.md
   git commit -m "docs(spec): thêm thiết kế <feature>"
   ```

3. **Notify user:**
   > "Spec done, committed tại `docs/specs/<file>.md`. Anh review rồi báo em chỉnh trước khi chạy /plan."

4. **Wait for approval.**

## Phase 5 — Transition

Once approved → run `/plan` to break into tasks.

## Output

- ✅ `docs/specs/YYYY-MM-DD-<feature>.md` committed.
- ✅ Chosen approach has clear reasoning.
- ✅ Acceptance criteria are measurable.
- ✅ Out-of-scope is explicit.

## Key principles

- **One question at a time** — don't overwhelm.
- **YAGNI ruthlessly** — remove unneeded features from every design.
- **Explore alternatives** — always 2-3 approaches before deciding.
- **Incremental validation** — present, approve, move on.
