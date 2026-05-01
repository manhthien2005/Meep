---
trigger: always_on
---

# Testing & Verification

The single most important rule: **claims of "done" require evidence, never confidence alone.**

## Two-line summary

- **Write a test before the code** for any non-trivial behaviour. (See skill `tdd`.)
- **Run the test and read the actual output** before claiming the work is done. (See skill `verification-before-completion`.)

## Minimum testing baseline (per feature)

| Area | Required |
|---|---|
| Pure logic (controllers, services, utilities) | Unit tests with edge cases |
| Repositories | Unit tests against `fake_cloud_firestore` / in-memory fakes |
| UI critical path (login, post, feed) | Widget test or integration test |
| Firestore / Storage rules | Rules unit tests in `firebase/functions/test/rules.test.ts` |
| Cloud Function entry points | Vitest test calling the handler with a fake event |

If a feature ships without these, it's a **prototype**, not finished work.

## What "done" means

A piece of work is done **only when** all of these are true:

1. The acceptance criteria from the spec are met (or there's an explicit decision to defer).
2. New behaviour is covered by tests, **and you ran the tests in this session and read the output**.
3. The lint / format check passes.
4. No commented-out blocks of dead code, no `// TODO` you didn't link to a follow-up.
5. The diff stays focused on the task — no unrelated refactors.

When you tell the user "done", say what you ran and what the output was — never just "done".

## "Should pass" / "probably works" / "I'm confident" — banned

You must not use these phrases as a substitute for evidence. If you didn't run it, say "I haven't run it yet, run `<exact command>` to verify".

## When tests fail

Don't:
- Comment them out.
- Add `if (process.env.CI) skip()`.
- Adjust the assertion to match the broken behaviour.

Do:
- Read the failure carefully.
- Use skill `systematic-debugging` if the cause isn't obvious.
- Fix the root cause. Then run the test again.

## When tests are flaky

Flaky = sometimes pass, sometimes fail without code changes.

- Don't rerun until they pass.
- Treat as a real bug — find the race condition, the missing await, the shared state.
- A flaky test in CI is worse than no test: it trains you to ignore failures.

## Coverage targets (rough)

Coverage is a smell-detector, not a goal. Target ranges:

- **Business logic (controllers, services, rules):** ≥ 80%
- **Data layer (repositories):** ≥ 70%
- **UI widgets:** ≥ 50% (snapshot-style tests are fragile)
- **Themes, simple utilities:** best-effort

If coverage drops noticeably, ask why **before** raising the number.

## Commands the agent should know by heart

```bash
# Flutter
flutter test                                # all tests
flutter test test/features/feed/            # one folder
flutter test --coverage                     # with coverage report
flutter analyze                             # lint
dart format --set-exit-if-changed .         # format check

# TypeScript / Functions / BE
npm test                                    # run vitest
npm run lint                                # eslint
npm run typecheck                           # tsc --noEmit (if scripted)

# Firebase emulator-driven tests
firebase emulators:exec --only firestore "npm run test:rules"

# E2E (when set up)
flutter test integration_test/
```
