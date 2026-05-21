---
description: Start working on a GitHub issue — load full context, verify blockers, create branch, prepare environment.
---

# /start <issue-id> — Task Kickoff

> Run this before `/build`. Never start coding without completing this checklist.

## Step 1 — Fetch issue details

```bash
gh issue view <issue-id> --repo manhthien2005/Meep
```

Read and extract:
- **Title** — task name + scope
- **Assignee** — module owner của task
- **Module** — module nào (xem field `Module` hoặc label `module:<name>` trong issue body)
- **Acceptance criteria** — what done looks like
- **Files có thể chạm** — output scope
- **Files phải đọc trước** — context files (read these in Step 3)
- **Dependencies / blockers** — issue numbers that must be closed first
- **Spec / plan reference** — `docs/specs/` + `docs/plans/` path

## Step 2 — Check blockers

For every issue listed under "Blocked by #":

```bash
gh issue view <blocking-id> --repo manhthien2005/Meep --json state,title
```

- If state = `OPEN` → **STOP**. Report: "Issue #X (`<title>`) chưa done. Không thể bắt đầu task này."
- If all blockers = `CLOSED` → continue.

## Step 3 — Load context files

Pull latest develop to ensure contracts are up to date:

```bash
git fetch origin develop
git status
```

Read every file listed under **"Files phải đọc trước"** in the issue.

If the section is empty or missing:
- Read every file listed under "Files có thể chạm" that already exists on `develop`.
- Focus on: abstract interfaces, freezed models, Riverpod providers, AppError hierarchy.

**Goal:** Understand the existing contract before writing a single line.

## Step 4 — Identify module + load rule context

Check the `Module` field in issue (or label `module:<name>`):

- Read `docs/specs/<module>.md` if exists — module spec + acceptance.
- Read `25-dev-code-standards.md` — solo-dev contract rules.
- If task touches presentation/theme/shared widgets → `24-flutter-ui-patterns.md` auto-loads via glob.

If no Module field set → ask: "Module nào của task này? (auth/feed/post/...)"

## Step 5 — Verify contract exists

Confirm leader đã merge contract vào `develop`:

- Spec: `docs/specs/<module>.md` exists.
- Models: `git log --oneline origin/develop -- apps/mobile/lib/features/<module>/data/` có commit từ leader.
- Stub providers throw `UnimplementedError` (chưa wire real impl).

If contract chưa có → **STOP**. Report: "Contract module `<X>` chưa có trên develop. Ping @manhthien2005 trước khi start."

## Step 6 — Create branch + update project status

Branch format: `feature/<DevName>/<short-desc>`

DevName mapping (GitHub handle → DevName):
| GitHub handle | DevName | Role |
|---|---|---|
| `manhthien2005` | `ThienPDM` | Leader (define contracts, review PR) |
| `CatS1mp` | `KhoaLND` | Module Owner |
| `katheramp` | `HanDHG` | Module Owner + UI/UX (Figma) |
| `JanaKimmm` | `NganTNK` | Module Owner + UI/UX (Figma) |

Resolve DevName from the assignee fetched in Step 1. If the assignee is not in this table → ask: "DevName của bạn là gì?"

**Run the following (in order):**

```bash
# 1. Create and switch to the feature branch
git checkout -b feature/<DevName>/<short-desc> origin/develop

# 2. Update issue status to "In Progress" on the project board
pwsh -File scripts/set-issue-status.ps1 -IssueNum <issue-id> -Status "In Progress"
```

## Step 7 — Summary + handoff to /build

Print a concise summary:

```
Issue:    #<id> <title>
Module:   <module-name>
Owner:    <DevName> (assignee)
Blockers: ✅ all closed / ❌ blocked by #X
Contract: ✅ spec + models on develop / ⚠️ missing (stop + ping leader)
Branch:   feature/<DevName>/<short-desc>
Status:   ✅ set to "In Progress" on project board
Scope:    <module folder> + <related> (cross-module touch → ping leader first)

Context loaded:
  - <file1> — <why>
  - <file2> — <why>

Ready → run /build to start TDD cycle.
```

If any blocker or contract check failed → do NOT proceed to `/build`.
