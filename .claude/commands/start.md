# /start <issue-id> — Task Kickoff

> Run this before `/build`. Never start coding without completing this checklist.

## Step 1 — Fetch issue details

```bash
gh issue view <issue-id> --repo manhthien2005/Meep
```

Extract:
- **Title** — task name + scope
- **Assignee** — module owner
- **Module** — module nào (label `module:<name>` hoặc đọc trong body)
- **Acceptance criteria** — what done looks like
- **Files có thể chạm** — output scope
- **Files phải đọc trước** — context files
- **Dependencies / blockers** — issue numbers that must be closed first
- **Spec / plan reference** — `docs/specs/` + `docs/plans/`

## Step 2 — Check blockers

```bash
gh issue view <blocking-id> --repo manhthien2005/Meep --json state,title
```

State = `OPEN` → **STOP**: "Issue #X (`<title>`) chưa done. Không thể bắt đầu."
All blockers `CLOSED` → continue.

## Step 3 — Load context files

```bash
git fetch origin develop
git status --short
```

Read every file listed under "Files phải đọc trước". If section empty:
- Read every file under "Files có thể chạm" that exists on `develop`.
- Focus on: abstract interfaces, freezed models, Riverpod providers, AppError hierarchy.

**Goal:** Understand the existing contract before writing a single line.

## Step 4 — Identify module + load rule context

- Read `docs/specs/<module>.md` if exists.
- Check solo-dev contract rules in root `CLAUDE.md`.
- If task touches presentation/theme/shared → check `apps/mobile/CLAUDE.md`.

If no Module field → ask: "Module nào của task này? (auth/feed/post/...)"

## Step 5 — Verify contract exists

Confirm leader đã merge contract vào `develop`:

- Spec: `docs/specs/<module>.md` exists.
- Models: `git log --oneline origin/develop -- apps/mobile/lib/features/<module>/data/` có commit từ leader.
- Stub providers throw `UnimplementedError`.

If contract chưa có → **STOP**: "Contract module `<X>` chưa có trên develop. Ping @manhthien2005 trước khi start."

## Step 6 — Create branch + update project status

```bash
git checkout -b feature/<DevName>/<short-desc> origin/develop

pwsh -File scripts/set-issue-status.ps1 -IssueNum <issue-id> -Status "In Progress"
```

DevName mapping:
| GitHub | DevName |
|---|---|
| `manhthien2005` | `ThienPDM` |
| `CatS1mp` | `KhoaLND` |
| `katheramp` | `HanDHG` |
| `JanaKimmm` | `NganTNK` |

## Step 7 — Summary

```
Issue:    #<id> <title>
Module:   <module-name>
Owner:    <DevName>
Blockers: ✅ all closed / ❌ blocked by #X
Contract: ✅ spec + models on develop / ⚠️ missing
Branch:   feature/<DevName>/<short-desc>
Status:   ✅ In Progress

Context loaded:
  - <file1> — <why>

Ready → run /build
```

If any blocker or contract check failed → do NOT proceed to `/build`.
