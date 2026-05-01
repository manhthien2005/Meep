# Plans

Implementation plans written via the `/plan` workflow.

## Naming

`YYYY-MM-DD-<feature-slug>.md` — same slug as the corresponding spec.

## Pairs with

- A spec at `docs/specs/<same-slug>.md`.
- A short-lived todo at `tasks/todo-<slug>.md`.

## Template

See `.windsurf/workflows/plan.md` Phase 4 + skill `writing-plans` for the full template.

## Conventions

- Each plan task includes: file paths, exact test code, exact implementation code, exact commands, expected output.
- No placeholders ("TBD", "TODO", "implement later") — see `.windsurf/skills/writing-plans/SKILL.md`.
- Vertical slices, not horizontal layers (1 task = end-to-end value).
- Commit a plan once approved by you; update with addendums when the implementation diverges.
