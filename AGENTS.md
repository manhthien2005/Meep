# Meep — Agent Operating Manual

Anchor file for any AI agent working on this codebase. Always loaded together with `.windsurf/rules/*.md` (Windsurf/Cascade) and `.cursor/rules/*.mdc` (Cursor/Kiro). **Read this top-to-bottom before doing anything.**

> **Output language:** Vietnamese by default — see `.windsurf/rules/00-personal-operating-mode.md`. This file (and most other `.windsurf/*` files) is written in English so the agent parses instructions reliably; the agent still talks to the user in Vietnamese.

## 1. What is Meep

Meep is a private/intimate photo-sharing app for close friends — small, focused, mobile-first.

- **Mobile (Flutter)** is the primary client.
- **Home-screen widget** showing latest images is a key differentiator. **MVP target: Android AppWidget only.** iOS WidgetKit is deferred post-MVP — see `docs/adr/0002-android-first-defer-ios.md`.
- **Meep ≠ Locket clone.** Defining differentiator features (must ship M3): Diary, Space, RollCall, Camera. See Tier 0+ in `.windsurf/rules/10-project-context.md` §Core MVP scope.
- **Firebase-first backend:** Auth, Firestore, Storage, Cloud Functions, FCM. A self-hosted Node/TypeScript service is added only when something genuinely cannot be done in Firebase.
- **Team capstone:** 4 student devs (anh là leader). **Solo-dev model** — mỗi dev own module end-to-end (data + logic + UI + test), không tách FE/BE. Leader define contract upfront, dev cầm contract về implement. HanDHG + NganTNK kiêm UI/UX Figma. Detail: `.cursor/rules/25-dev-code-standards.mdc` + `docs/team-workflow.md` §8.4. Decisions must keep onboarding low (a new dev productive in <1 day) and ops surface small.
- **MVP scope:** 12 firm features (Tier 0 + Tier 0+) + 3 stretch (Tier 1) + 11 cut (Tier 2). Detail: `.windsurf/rules/10-project-context.md` §Core MVP scope, `docs/product/features.md`, `docs/roadmap/milestones.md`, memory `mvp-tier-priority`.

## 2. Repository layout (current)

```
Meep/
├── AGENTS.md                  # ← agent operating manual (this file)
├── README.md                  # human-facing project intro + setup
├── CONTEXT.md                 # domain language reference (Post, Pair ID, Fan-out, ...)
├── package.json               # root — husky + commitlint deps + npm scripts
├── commitlint.config.js       # Conventional Commits config (allowed types, scope rules)
├── .gitmessage                # tiếng Việt commit message template
├── .env.example               # local-dev env template (copy to .env, gitignored)
├── .gitignore
│
├── apps/
│   └── mobile/                # Flutter app (scaffolded)
│       ├── pubspec.yaml
│       ├── analysis_options.yaml
│       ├── README.md          # Flutter-specific setup + build commands
│       ├── lib/
│       │   ├── main.dart      # ProviderScope entry
│       │   ├── core/
│       │   │   ├── theme/     # AppTheme (Material 3, light + dark)
│       │   │   └── error/     # AppError sealed hierarchy
│       │   └── features/
│       │       └── auth/      # sample feature scaffold (data + application + presentation)
│       ├── test/              # mirrors lib/ structure
│       ├── android/           # Android native (MVP target)
│       └── ios/               # iOS scaffold (kept; iOS targeting deferred per ADR-0002)
│
├── firebase/
│   ├── README.md              # Firebase CLI + emulator commands
│   ├── firebase.json
│   ├── .firebaserc.example    # copy to .firebaserc, gitignored
│   ├── firestore.rules        # default-deny + per-collection helpers
│   ├── firestore.indexes.json
│   ├── storage.rules          # 10MB cap, image MIME only
│   └── functions/             # Cloud Functions (Node 20 + TypeScript)
│       ├── package.json
│       ├── tsconfig.json
│       ├── eslint.config.mjs
│       ├── vitest.config.ts
│       └── src/
│           ├── index.ts       # entry — sample sendFriendRequest + onPostCreated
│           └── index.test.ts
│
├── services/                  # OPTIONAL self-hosted BE (does not exist yet)
│
├── docs/
│   ├── team-onboarding/           # onboarding docs + per-dev memory bootstrap
│   │   └── dev-memory-bootstrap.md   # paste to Cascade once per dev machine to set identity
│   ├── team-workflow.md       # full team onboarding doc (read FIRST nếu là dev mới)
│   ├── specs/                 # /spec workflow output
│   ├── plans/                 # /plan workflow output
│   ├── milestones/            # milestone summary docs (M1/M2/M3 reports cho giảng viên)
│   │   └── README.md          # convention + template
│   └── adr/
│       ├── README.md          # ADR conventions + lifecycle
│       ├── 0001-firebase-first-backend.md
│       ├── 0002-android-first-defer-ios.md
│       └── 0003-task-management-process.md
│
├── tasks/                     # short-lived TODO/checklist files per feature
│
├── scripts/                   # utility PowerShell scripts (issue management, GitHub Project setup)
│   ├── set-issue-status.ps1       # update Project v2 Status field (Backlog/In Progress/Review/Done)
│   ├── tick-issue-checklist.ps1   # mark acceptance criteria done in GitHub issue
│   ├── restore-auth-issue-bodies.ps1  # one-time restore auth sub-issues #20-26
│   └── setup-*.ps1 / create-*.ps1    # project scaffolding (run once by leader)
│
├── .github/
│   ├── CODEOWNERS             # anh = default reviewer cho mọi path
│   ├── pull_request_template.md  # PR body template tiếng Việt
│   ├── ISSUE_TEMPLATE/        # bug.md + feature.md + task.md + config.yml
│   └── workflows/
│       ├── pr-check.yml       # branch name + commit format + lint + test trên mọi PR
│       ├── develop-staging.yml   # push develop → build APK + deploy staging Firebase
│       └── deploy-production.yml # push deploy → manual approval → deploy prod + tag
│
├── .husky/
│   ├── commit-msg             # commitlint check (Conventional Commits + tiếng Việt)
│   ├── pre-commit             # dart format + flutter analyze + eslint staged
│   └── pre-push               # validate branch name <type>/<DevName>/<short-desc>
│
├── .windsurf/
│   ├── hooks.json             # safety hooks (block_dangerous_commands, protect_secrets)
│   ├── hooks/                 # Python hook scripts
│   ├── rules/                 # 11 rule files (always_on + glob-scoped)
│   ├── skills/                # 10 SKILL.md folders (TDD, debugging, ...)
│   ├── workflows/             # 9 slash commands (/start /spec /plan /build /test /review /debug /fix-issue /deploy)
│   └── mcp_config.example.json  # sample MCP servers (copy to user-level path — see §9)
│
└── .cursor/
    ├── hooks.json             # safety hooks (block_dangerous_commands, protect_secrets) — Cursor-native
    ├── hooks/                 # Python hook scripts (mirrors .windsurf/hooks/)
    ├── rules/                 # 21 .mdc rule files — mirrors .windsurf/rules/ + workflows + Cursor cheatsheet
    ├── skills/                # 10 SKILL.md folders — mirrors .windsurf/skills/ (auto-discovered)
    └── mcp.example.json       # workspace-level MCP config (copy to .cursor/mcp.json — gitignored)
```

`.agent-kits/` is git-ignored and contains source repositories used as reference. **Do not edit anything inside it.**

## 3. Tech stack

Full table + rationale lives in:
- `.windsurf/rules/10-project-context.md` — high-level decisions + Firebase-first rationale.
- `.windsurf/rules/20-stack-conventions.md` — naming + cross-cutting conventions.
- `.windsurf/rules/21-flutter-rules.md` (loaded when editing `apps/mobile/**`).
- `.cursor/rules/22-functions-rules.mdc` (loaded when editing `firebase/functions/**`).
- `.cursor/rules/23-firestore-rules.mdc` (loaded when editing rules / indexes).
- `.cursor/rules/24-flutter-ui-patterns.mdc` (loaded when editing `presentation/`, `core/theme/`, `shared/widgets/`).
- `.cursor/rules/25-dev-code-standards.mdc` (always loaded — solo-dev model rules).
- `docs/adr/0001-firebase-first-backend.md` — why Firebase over self-host.
- `docs/adr/0004-solo-dev-module-ownership.md` — solo-dev model decisions.

Default deploy region for Functions + Storage: `asia-southeast1`.

## 4. Where each kind of work happens

| Task | Tool / file |
|---|---|
| Define a new feature | `/spec` workflow → `docs/specs/YYYY-MM-DD-<feature>.md` |
| Break a spec into tasks | `/plan` workflow → `docs/plans/<feature>.md` + `tasks/todo-<feature>.md` |
| Sprint planning + task tracking | GitHub Projects v2 + `.github/ISSUE_TEMPLATE/task.md` (xem ADR-0003 + `docs/team-workflow.md` §8) |
| Implement a task | `/build` workflow + `tdd` skill |
| Write or expand tests | `/test` workflow |
| Investigate a bug | `/debug` workflow + `systematic-debugging` skill |
| Fix a specific issue | `/fix-issue` workflow |
| Self-review before merge | `/review` workflow + `code-review-five-axis` skill |
| Deploy to staging/prod | `/deploy` workflow |
| Architectural decision | New ADR in `docs/adr/NNNN-<title>.md` |

## 5. How rules / skills / workflows / hooks fit together

```
── Windsurf / Cascade ────────────────────────────────────────────────────────
User message → always loads:
   - AGENTS.md (this file)
   - .windsurf/rules/*.md with trigger: always_on
On demand:
   - Glob-scoped rules when matching files are touched
   - Skills via the Skill tool when their description fits the task
   - Workflows when the user types /<slash-command>
Hooks intercept every read/write/run:
   - pre_run_command   → block_dangerous_commands.py  (rm -rf, format, prod deploy …)
   - pre_read_code     → protect_secrets.py            (.env, *.pem, adminsdk JSON …)
   - pre_write_code    → protect_secrets.py
   Exit 0 → proceeds / Exit 2 → blocked

── Cursor / Kiro ─────────────────────────────────────────────────────────────
User message → always loads:
   - AGENTS.md (this file)
   - .cursor/rules/*.mdc with alwaysApply: true
On demand:
   - Glob-scoped rules (globs: pattern) when matching files are open/edited
   - Skills via .cursor/skills/<name>/SKILL.md (auto-discovered, agent-invoked when description matches)
   - Workflow rules via description match (ask agent to run /start, /spec, /plan, etc.)
Hooks intercept agent action via .cursor/hooks.json:
   - beforeShellExecution → block_dangerous_commands.py  (rm -rf, force-push prod, prod deploy …)
   - beforeReadFile       → protect_secrets.py            (.env, *.pem, adminsdk JSON …)
   - afterFileEdit        → protect_secrets.py            (block writes to secret files)
   Exit 0 + permission:allow → proceeds / Exit 2 + permission:deny → blocked
```

### Rule activation modes used

| File | Mode | Loads when |
|---|---|---|
| `00-personal-operating-mode.md` | `always_on` | every message |
| `10-project-context.md` | `always_on` | every message |
| `20-stack-conventions.md` (general) | `always_on` | every message |
| `21-flutter-rules.md` | `glob` | editing `apps/mobile/**` |
| `22-functions-rules.md` | `glob` | editing `firebase/functions/**` or `services/api/**` |
| `23-firestore-rules.md` | `glob` | editing `firebase/firestore.rules`, `firebase/storage.rules`, indexes |
| `24-flutter-ui-patterns.md` | `glob` | editing `presentation/**`, `core/theme/**`, `shared/widgets/**` |
| `30-testing-and-verification.md` | `always_on` | every message |
| `40-security-guardrails.md` | `always_on` | every message |
| `50-token-discipline.md` | `always_on` | every message |

This keeps stack-specific noise out of the context until the agent actually edits that stack's files.

**Cursor/Kiro equivalent:** same files exist as `.cursor/rules/*.mdc`. `always_on` → `alwaysApply: true`. `glob` → `globs: <pattern>`. Workflows → `description:` field (agent-requested — just ask the agent to run `/start`, `/spec`, `/plan`, etc., no slash-command system needed).

## 6. Always-on guardrails

Fully specified in `.windsurf/rules/` (loaded every message):

- Security & secrets → `40-security-guardrails.md`
- Testing & verification discipline → `30-testing-and-verification.md`
- Token discipline → `50-token-discipline.md`
- Personal operating mode (language / tone / surgical changes) → `00-personal-operating-mode.md`

Domain language and disambiguation (Post, Pair ID, Fan-out, Widget vs widget, ...) → `CONTEXT.md` at repo root.

## 7. Team workflow (read this if you're a new dev)

Full onboarding doc lives at `docs/team-workflow.md`. Quick reference:

- **Branches:** `develop` (integration) → `deploy` (production). Feature branch: `<type>/<DevName>/<short-desc>`.
- **Commit messages:** Conventional Commits với **mô tả tiếng Việt**, type prefix English. Vd `feat(auth): thêm đăng nhập Google`.
- **PR:** Title + body tiếng Việt theo template `.github/pull_request_template.md`. ≥ 1 reviewer (anh là default).
- **CI:** GitHub Actions chạy commitlint + lint + format + test trên mọi PR. Phải PASS để merge.
- **Local enforcement:** husky + commitlint. Sau khi clone, chạy `npm install` ở root để bind hooks.
- **Task tracking:** GitHub Projects v2. Issues link với commit qua `Refs #N` / `Closes #N`.

Detail rules: `.windsurf/rules/20-stack-conventions.md` §Git — Team Workflow.


## 8. Setup, MCP, and reference kits

Setup commands, MCP server config, RTK install, và source kits ref đã move sang **[docs/setup.md](docs/setup.md)** để giảm context bloat (setup info là one-time, không cần load mỗi message).

Khi bạn cần:
- **First-run setup** (Firebase CLI, flutterfire, deps) → `docs/setup.md` §1-§2.
- **MCP servers** (context7, github, figma) → `docs/setup.md` §3.
- **RTK token-killer** (optional) → `docs/setup.md` §4.
- **.agent-kits/ source kits** → `docs/setup.md` §5.
- **Restart checklist sau setup** → `docs/setup.md` §6.
