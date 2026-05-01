# Specs

Feature specifications written via the `/spec` workflow.

## Naming

`YYYY-MM-DD-<feature-slug>.md` — e.g. `2026-05-01-friend-feed.md`.

## Lifecycle

Each spec moves through:

1. **Draft** — written via `/spec`, contains discovery + chosen approach.
2. **Approved** — reviewed by you. Move on to `/plan`.
3. **Implemented** — feature is shipped. Mark `Status:` accordingly.

## Template

See `.windsurf/workflows/spec.md` Phase 3 for the full template, or copy from an existing approved spec.

## Conventions

- Each spec is a single self-contained file.
- Keep specs **scoped to one feature** — multi-subsystem feature → split into sub-specs.
- Don't edit a spec after it's "Implemented" — write an addendum or a new spec.
