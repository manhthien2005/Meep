# Meep Adapter — dart-run-static-analysis

> Adapt official skill cho Meep workflow.

## Meep analysis commands (apps/mobile/CLAUDE.md §Testing commands)

```bash
# Foreground sanity check
cd apps/mobile && flutter analyze

# Auto-fix safe lints
cd apps/mobile && dart fix --apply

# Format check (used in CI)
cd apps/mobile && dart format --set-exit-if-changed .
```

## When to run

| Trigger | Command |
|---|---|
| Before commit (pre-commit hook) | `flutter analyze` + `dart format --set-exit-if-changed .` |
| After codegen (`build_runner`) | `flutter analyze` |
| After dependency upgrade | `flutter analyze` |
| In `/review` skill (custom Meep command) | both above |
| In CI `pr-check.yml` | both above + `flutter test` |

## Meep-specific lint config

Lint rules live trong `apps/mobile/analysis_options.yaml`. Check trước khi adjust:
- Riverpod 2 lints (`riverpod_lint` package)
- freezed lints
- Custom rule: prefer_const_constructors (per CLAUDE.md widget perf)

## Gotcha (per global memory `feedback-flutter-workflow.md`)

- `dart format` + trailing comma có thể conflict — Meep convention: **trailing comma everywhere** (Dart formatter respects this).
- Pre-commit hook re-stage pattern: `dart format` modifies files → hook re-stage automatically.

## Auto-fix safe categories

- Unused imports
- Const constructor opportunities
- Sort directives
- Prefer single quotes
- Trailing comma additions

## Auto-fix DANGEROUS — disable

- `prefer_final_locals` → có thể break if mutation needed
- `use_super_parameters` → cosmetic, leave alone in heavy refactor

## CI gate signal

Status quo (assumed):
```yaml
- run: cd apps/mobile && flutter analyze --no-pub
- run: cd apps/mobile && dart format --set-exit-if-changed .
```

If gate not yet in `.github/workflows/pr-check.yml` → audit `06_testing_ci_release` flag as P1.

## Cite as authority

- `.claude/skills/dart-run-static-analysis/SKILL.md`
- `apps/mobile/CLAUDE.md` §Testing
- Global memory `feedback-flutter-workflow.md` (trailing comma)
