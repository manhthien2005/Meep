# Meep — Agent Operating Manual

Anchor file for any AI agent working on this codebase. Always loaded together with `.windsurf/rules/*.md`. **Read this top-to-bottom before doing anything.**

> **Output language:** Vietnamese by default — see `.windsurf/rules/00-personal-operating-mode.md`. This file (and most other `.windsurf/*` files) is written in English so the agent parses instructions reliably; the agent still talks to the user in Vietnamese.

## 1. What is Meep

Meep is a private/intimate photo-sharing app for close friends — small, focused, mobile-first.

- **Mobile (Flutter)** is the primary client.
- **Home-screen widget** showing latest images is a key differentiator. **MVP target: Android AppWidget only.** iOS WidgetKit is deferred post-MVP — see `docs/adr/0002-android-first-defer-ios.md`.
- **Meep ≠ Locket clone.** Defining differentiator features (must ship M3): Diary, Space, RollCall, Camera. See Tier 0+ in `.windsurf/rules/10-project-context.md` §Core MVP scope.
- **Firebase-first backend:** Auth, Firestore, Storage, Cloud Functions, FCM. A self-hosted Node/TypeScript service is added only when something genuinely cannot be done in Firebase.
- **Team capstone:** 4 dev student (anh là leader). Every decision must keep onboarding low (a new dev productive in <1 day) and ops surface small.
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
└── .windsurf/
    ├── hooks.json             # safety hooks (block_dangerous_commands, protect_secrets)
    ├── hooks/                 # Python hook scripts
    ├── rules/                 # 10 rule files (always_on + glob-scoped)
    ├── skills/                # 10 SKILL.md folders (TDD, debugging, ...)
    ├── workflows/             # 9 slash commands (/start /spec /plan /build /test /review /debug /fix-issue /deploy)
    └── mcp_config.example.json  # sample MCP servers (copy to user-level path — see §9)
```

`.agent-kits/` is git-ignored and contains source repositories used as reference. **Do not edit anything inside it.**

## 3. Tech stack

Full table + rationale lives in:
- `.windsurf/rules/10-project-context.md` — high-level decisions + Firebase-first rationale.
- `.windsurf/rules/20-stack-conventions.md` — naming + cross-cutting conventions.
- `.windsurf/rules/21-flutter-rules.md` (loaded when editing `apps/mobile/**`).
- `.windsurf/rules/22-functions-rules.md` (loaded when editing `firebase/functions/**`).
- `.windsurf/rules/23-firestore-rules.md` (loaded when editing rules / indexes).
- `.windsurf/rules/24-flutter-ui-patterns.md` (loaded when editing `presentation/`, `core/theme/`, `shared/widgets/`).
- `docs/adr/0001-firebase-first-backend.md` — why Firebase over self-host.

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
User message
   ↓
Cascade always loads:
   - AGENTS.md (this file)
   - .windsurf/rules/*.md with trigger: always_on
   - The user's message
   ↓
Cascade also loads on demand:
   - Glob-scoped rules (21-flutter, 22-functions, 23-firestore) when matching files are touched
   - Skills via the Skill tool when their description fits the task
   - Workflows when the user types /<slash-command>
   ↓
For every read/write/run, hooks intercept:
   - pre_run_command   → block_dangerous_commands.py  (rm -rf, format, prod deploy …)
   - pre_read_code     → protect_secrets.py            (.env, *.pem, adminsdk JSON …)
   - pre_write_code    → protect_secrets.py
   Exit 0 → action proceeds
   Exit 2 → action blocked, reason shown
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

## 8. First-run setup checklist

Tooling currently installed on this machine:

- ✅ **Flutter 3.41.4** (stable channel)
- ✅ **Node 22.17.0** (local OK — backward-compat với Node 20. **CI + Cloud Functions runtime = Node 20** để match production engine. Test BE features cần Node 20 trước khi push để tránh CI fail.)
- ✅ **Git 2.51**
- ✅ **Java 21 LTS** (Android dev)
- ✅ **Python 3.13.4** (used by Cascade hooks)
- ❌ **Firebase CLI** — needs `npm install -g firebase-tools`
- ❌ **flutterfire CLI** — needs `dart pub global activate flutterfire_cli`
- ❌ **MCP servers** — see §8 below
- ❌ **RTK** (token-killer proxy) — optional, see §9 below

### One-time setup commands

```bash
# Firebase CLI + login
npm install -g firebase-tools
firebase login

# flutterfire CLI (used to wire google-services.json / GoogleService-Info.plist)
dart pub global activate flutterfire_cli

# Flutter app deps + code generation
cd apps/mobile
flutter pub get
flutterfire configure --project=<your-firebase-project-id>
dart run build_runner build --delete-conflicting-outputs
cd ../..

# Functions deps
cd firebase/functions
npm install
cd ../..

# Project alias
cp firebase/.firebaserc.example firebase/.firebaserc
# Edit firebase/.firebaserc with your real project IDs

# Local env
cp .env.example .env
# Edit .env with your real values

# Smoke test the emulator suite
firebase emulators:start --project default
```

## 9. MCP servers — curated minimal set

Windsurf reads MCP servers from a **user-level** file:

- macOS / Linux: `~/.codeium/windsurf/mcp_config.json`
- Windows: `C:\Users\<you>\.codeium\windsurf\mcp_config.json`

(There is **no** workspace-level MCP config — Windsurf only supports the user-level file.)

A starting point lives at `.windsurf/mcp_config.example.json`. To activate:

```pwsh
# Windows
$mcpDir = "$env:USERPROFILE\.codeium\windsurf"
New-Item -ItemType Directory -Force -Path $mcpDir | Out-Null
Copy-Item .windsurf\mcp_config.example.json "$mcpDir\mcp_config.json"
```

```bash
# macOS / Linux
mkdir -p ~/.codeium/windsurf
cp .windsurf/mcp_config.example.json ~/.codeium/windsurf/mcp_config.json
```

Then restart Windsurf or click "Refresh" on the MCPs panel in Cascade.

### Enabled by default

- **context7** — up-to-date library docs (Flutter / Firebase / Riverpod / freezed). Prevents the agent hallucinating outdated APIs. Free tier, no API key.

### Deliberately NOT enabled (and why)

| MCP | Why skipped |
|---|---|
| `filesystem` | Redundant — Cascade already has `read_file`, `write_to_file`, `edit`, `find_by_name`, `grep_search`, `list_dir` natively (faster, no extra hop). |
| `github` | `git` + `gh` CLI are faster and more direct for the team's PR workflow. Add when triage volume justifies it (likely Phase 2). |
| `memory` | Redundant — Cascade has `create_memory` natively, persists across sessions. |
| `postgres` | Project uses Firestore (see ADR `0001-firebase-first-backend`). Add only when a real Postgres dependency appears. |
| `firebase` | No audited official server yet (as of 2026-04). Prefer the `firebase` CLI directly — already guarded by `block_dangerous_commands.py` for prod targets. |

If you later need any of these, add the entry to `~/.codeium/windsurf/mcp_config.json` and restart Cascade.

## 10. RTK (Rust Token Killer) — optional

RTK proxies shell commands and compresses noisy output before it enters the Cascade context (60–90% token saving on `git status`, test runners, etc.). Not installed yet — `.windsurf/rules/50-token-discipline.md` already has fallback flags for noisy commands, so this is purely an optimization.

If you want to install it later, three options:

**Option 1 — Pre-built binary (fastest, no Rust needed):**
1. Download `rtk-x86_64-pc-windows-msvc.zip` from the [releases page](https://github.com/rtk-ai/rtk/releases).
2. Extract `rtk.exe` to `C:\Users\<user>\.local\bin\` (create the folder if missing).
3. Add that folder to `PATH` (System Properties → Environment Variables).
4. Restart Windsurf, verify with `rtk --version`.
5. Activate: `rtk init --agent windsurf`.

**Option 2 — Cargo (if you install Rust first):**
```pwsh
winget install Rustlang.Rustup
rustup default stable
cargo install --git https://github.com/rtk-ai/rtk
rtk init --agent windsurf
```

**Option 3 — WSL** (Linux native, full hook system): see [docs](https://github.com/rtk-ai/rtk#windows).

## 11. Source kits (reference only)

The `.agent-kits/` folder (gitignored) contains seven cloned reference repos. They were inspected during the bootstrap of this project's `.windsurf/` setup. **Do not edit anything inside `.agent-kits/`.** If a skill needs an update, edit the file in `.windsurf/skills/` directly.

| Folder | Origin | What was kept |
|---|---|---|
| `superpowers/` | obra/superpowers | Methodology skills: TDD, systematic-debugging, verification, brainstorming, writing-plans |
| `class-ai-agent/` | bahdotsh/class-ai-agent | Slash-command workflow scaffolds (rewritten for Flutter/Firebase) |
| `andrej-karpathy-skills/` | karpathy | `karpathy-guidelines` skill, near-verbatim |
| `caveman/` | JuliusBrussee/caveman | Windsurf `.windsurf/` format reference + adapted into `caveman-vi` |
| `everything-claude-code/` | hesreallyhim/everything-claude-code | Inspected; not used wholesale (Claude-Code-specific plugin system) |
| `mattpocock-skills/` | mattpocock | Inspected; not cherry-picked (overlaps with superpowers) |
| `rtk/` | rtk-ai/rtk | Documented install path only; not auto-installed |

The folder is ~150MB on disk. Safe to delete with `Remove-Item -Recurse -Force .agent-kits` once you're comfortable with what's in `.windsurf/`.
