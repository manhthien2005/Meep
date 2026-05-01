# Architectural Decision Records (ADRs)

One-page records for non-trivial architectural / technology decisions that future-you (or future collaborators) might re-question.

## When to write an ADR

Write an ADR when you:

- Pick one technology over another with non-obvious tradeoffs (e.g. "Riverpod over BLoC").
- Choose a non-standard pattern for the codebase (e.g. "denormalize authorName into posts/").
- Make a security / privacy decision that limits future options (e.g. "no public posts ever").
- Decide to defer a feature you'd otherwise build (e.g. "no comments in MVP because moderation is hard").

Don't write an ADR for:

- Every package version bump.
- Reversible code-style choices.
- Decisions already covered in `.windsurf/rules/`.

## Naming

`NNNN-<short-slug>.md` — sequential 4-digit number + kebab-case slug. Example: `0003-no-public-posts.md`.

## Template

See `0001-firebase-first-backend.md` for a complete example, or `class-ai-agent` repo for the canonical Michael Nygard format. Short version:

```markdown
# NNNN. <Title>

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Deprecated | Superseded by ADR-XXXX

## Context
What problem are we solving? What forces are at play?

## Decision
What did we choose? Be specific.

## Alternatives considered
- Option A — pros/cons
- Option B — pros/cons

## Consequences
- Positive: ...
- Negative: ...
- Neutral / unknowns: ...
```

## Lifecycle

ADRs are **append-only history**. Don't edit a past ADR's decision — write a new ADR that supersedes it and update the old one's status to "Superseded by ADR-NNNN".
