# /debug — Systematic Debugging

> "Fix root causes, not symptoms."

Use when hitting:
- A test failure (CI or local).
- A bug from user report / Crashlytics / runtime error.
- Strange behaviour (intermittent, "works on my machine").
- Build / lint failure you don't understand.

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

Phase 1 not done → no fix proposals.

## Phase 1 — Root cause investigation

**Before changing ANY line:**

1. **Read the error message carefully.** Full stack trace. Note line number, file path, error code.
2. **Reproduce reliably.** Can you trigger it 100%? If flaky → gather data, don't guess.
3. **Check recent changes.**
   ```bash
   git log -n 10 --oneline
   git diff HEAD~5 -- <suspect file>
   ```
4. **Trace data flow** from symptom backwards to source:
   - Error at line X, value Y is wrong.
   - Where does Y come from? Which function sets Y?
   - Trace back to the **real source** — don't stop at first non-null caller.
5. **Multi-component system** (UI → controller → repo → Firestore → rules):
   - Add log at each boundary, run once to find WHERE it fails.
   - Then focus investigation on that component.

## Phase 2 — Pattern analysis

1. Find similar **working code** in the same codebase. Compare.
2. Read the **full reference** (Flutter docs, Firebase docs) — don't skim.
3. List every difference between working and broken code, no matter how small.
4. Understand dependencies — config, env, version, platform.

## Phase 3 — Hypothesis & test

1. **Form one specific hypothesis.** "I think the root cause is X because Y."
2. **Test with a minimal change** — change one variable, not five.
3. Hypothesis correct → Phase 4. Wrong → form NEW hypothesis. Don't stack more fixes.

## Phase 4 — Implementation

1. **Write a failing test that reproduces the bug** (TDD "Bug fix" section below).
2. **Implement the fix** — root cause only, NOT bundled with "while I'm here" cleanup.
3. **Verify:**
   - Reproduction test passes.
   - Other tests still pass.
   - The bug is actually gone.
4. **If the fix doesn't work:**
   - < 3 attempts → back to Phase 1 with new info.
   - **≥ 3 attempts → STOP.** Architecture might be wrong. Discuss with user.

## Bug fix → regression test (TDD)

1. Write test that reproduces the bug (don't touch code).
2. Run → confirm FAIL with right symptom.
3. Fix code → run → PASS.
4. **Revert fix** → run → FAIL (proof test actually catches the bug).
5. Restore fix → run → PASS.
6. Commit.

Skip step 4 → the test might pass for the wrong reason.

## Meep-specific debugging entry points

| Symptom | First check |
|---|---|
| Flutter widget doesn't rebuild | Trace `build` → state → notifier → repo. Don't `setState()` randomly. |
| Firestore query empty in prod, OK in emulator | Rules first → index → field-name typo (case-sensitive) → query path. |
| Firestore query empty everywhere | Compound query missing index — check `firestore.indexes.json`. |
| FCM not received on Android | Token registration timing → topic subscription → server payload → channel ID. |
| Flaky test | DO NOT retry. Find the race condition / shared state / missing await. |
| Cloud Function timeout | `timeoutSeconds`. Long task → Cloud Tasks / Pub/Sub. |
| `setState() called after dispose` | Check `mounted` first, or migrate to Riverpod. |

```bash
# Test failure
flutter test test/path/test.dart --reporter=expanded
cd firebase/functions && npm test -- file.test.ts

# Recent changes
git log -n 10 --oneline
git diff HEAD~5 -- <suspect file>
```

**Remove debug logs before commit** — search `[DEBUG]` in `lib/` then clean.

## Commit

```bash
git add <files>
git commit -m "fix(<scope>): <mô tả tiếng Việt>

Root cause: <short — what was wrong>
Fix: <approach>
Test: regression test in <test file>

Closes #<issue-id>"
```

## Red flags — STOP and go back to Phase 1

- "Quick fix now, investigate later."
- "Let me try changing X and see."
- "I don't fully understand it, but this might work."
- Proposing a fix without tracing the data flow.
- 3+ fix attempts and bug still there / new symptoms appearing.

## Output

- ✅ Root cause documented in commit message.
- ✅ Regression test alongside the fix.
- ✅ Bug verified gone (actual repro step no longer fails).
- ✅ No "while I'm here" cleanup.
