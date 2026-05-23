# /fix-issue — Targeted Issue Resolution

End-to-end fix for a specific issue: GitHub issue, Crashlytics report, user complaint, or a clear bug with reproduction steps.

## Pre-flight

```bash
git checkout -b fix/<DevName>/<short-description> origin/develop
```

Get issue details: link / ID / description, repro steps, stack trace, affected version/platform.

## Step 1: Understand the issue

1. Read the full issue description, comments, related issues.
2. Read error message / stack trace line by line.
3. Identify affected component(s): UI? data layer? rule? Function?

**DO NOT fix** an issue you can't reproduce, unless stack trace + logs clearly identify root cause.

## Step 2: Root cause analysis

Use `/debug` systematic process (4 phases: root cause → pattern → hypothesis → fix).

```bash
git log -n 20 --oneline -- <affected files>
```

| Symptom | First check |
|---|---|
| `setState() after dispose` | Riverpod migration vs `mounted` guard |
| Firestore query empty in prod, OK in emulator | Rules → index → field-name typo |
| FCM not delivered | Token registration → topic → payload → fg/bg state |
| Auth token expired loop | Refresh handler in `AuthRepository` boundary |

## Step 3: Plan a minimal fix

- Identify the **minimal change** to address root cause.
- DON'T bundle refactors or other bug fixes.
- Consider side effects: will this break old tests / other features?

If ≤ 20 lines: implement directly.
If big (multi-file, architectural): consider `/spec` or discuss with user first.

## Step 4: Implement (TDD)

**Bug fix → reproduction test procedure:**
1. Write failing test that reproduces bug.
2. Run → confirm FAIL with right symptom.
3. Fix code → run → PASS.
4. Revert fix → run → FAIL.
5. Restore fix → run → PASS.
6. Commit.

Name the test: `regression: <issue title> (#<id>)`.

## Step 5: Verify end-to-end

### Mobile fix
- Run on real device.
- Repro original steps → confirm bug gone.
- Smoke-test related features for no regression.

### BE / Functions fix
- Deploy to emulator → run integration tests.
- Check logs: no new errors.

**Before claiming "fixed":**
- ✅ Unit tests pass.
- ✅ Original reproduction steps → bug gone.
- ✅ Full test suite passes.
- ✅ Lint clean.

## Step 6: Commit

```bash
git add <files>
git commit -m "fix(<scope>): <mô tả tiếng Việt>

Root cause: <short — what was wrong>
Fix: <approach>
Test: regression test in <test file>

Closes #<issue-id>"
```

## Step 7: PR

Run `/review` first, then:

```bash
gh pr create --base develop \
  --title "fix(<scope>): <mô tả tiếng Việt>" \
  --body "## Issue
Closes #<id>

## Root cause
<1-2 sentences>

## Fix
<approach + why>

## Verification
- [ ] flutter test passes
- [ ] flutter analyze clean
- [ ] Manual repro confirmed bug gone"
```

## Step 8: Post-merge

- Confirm fix deployed successfully.
- Monitor Crashlytics / logs for 24h.
- Close issue with confirmation comment.

## When the issue isn't a bug

- **Feature request in disguise** → push back, suggest `/spec`.
- **User misunderstanding** → explain expected behavior, don't change code.
- **Documentation gap** → fix the doc, don't fix code.

## Anti-patterns

| Anti-pattern | Problem |
|---|---|
| Fix without reproducing | Might fix the wrong thing |
| Fix multiple issues in one commit | Can't revert granularly |
| Skip the regression test | Bug can recur silently |
| Fix the symptom, not root cause | Similar issues appear elsewhere |
| "While I'm here" refactor | Hard-to-review diff |
