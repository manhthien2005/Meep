# Meep

> Private photo sharing app for close friends. Mobile-first (Flutter + Firebase). Capstone project.

<!-- TODO(setup): replace `<org>` với GitHub org/user thật ở 2 chỗ: (1) badge URL ngay dưới, (2) clone URL ở section "Setup nhanh". Cũng cập nhật `.github/ISSUE_TEMPLATE/config.yml` + `docs/team-workflow.md`. -->
[![PR Check](https://github.com/<org>/meep/actions/workflows/pr-check.yml/badge.svg?branch=develop)](https://github.com/<org>/meep/actions/workflows/pr-check.yml)

## Tổng quan

Meep là app chia sẻ ảnh riêng tư cho nhóm bạn thân — không có public feed, không follower, không suggestions. Tính năng đặc biệt: **home-screen widget Android** hiển thị ảnh mới nhất của bạn bè.

> **MVP target: Android only.** iOS deferred post-MVP — xem [ADR-0002](docs/adr/0002-android-first-defer-ios.md). Flutter codebase vẫn cross-platform-ready, sau MVP add iOS lại không phải viết lại.

**MVP scope:**

1. Đăng nhập (email + Google)
2. Add/accept bạn (closed graph)
3. Chụp ảnh + caption
4. Friend feed
5. Push notification (FCM Android) khi bạn post
6. Home-screen widget Android

**Out of scope (MVP):** iOS targeting, Apple Sign-In, iOS WidgetKit, likes, comments, stories, public posting.

## Tech stack

| Layer | Stack |
|---|---|
| Mobile | Flutter (latest stable) + Riverpod 2 + freezed |
| Backend | Firebase (Auth, Firestore, Storage, Functions, FCM) |
| Functions runtime | Node 20 + TypeScript (strict) |
| Native widget | Android AppWidget (Kotlin). _iOS WidgetKit deferred_ |
| CI/CD | GitHub Actions |
| Task tracking | GitHub Projects v2 |

Chi tiết tech decisions: [`docs/adr/`](docs/adr/).

## Team

4 dev student capstone. Branch + commit format track per dev.

| Tên | Vai trò |
|---|---|
| `ThienPDM` | Leader, default CODEOWNERS |
| `<DevName2>` | (cập nhật) |
| `<DevName3>` | (cập nhật) |
| `<DevName4>` | (cập nhật) |

## Setup nhanh

```bash
git clone https://github.com/<org>/meep.git
cd meep
npm install                              # Bind husky + commitlint
git config commit.template .gitmessage   # Setup tiếng Việt commit template

cd apps/mobile && flutter pub get
flutterfire configure --project=<firebase-project-id>
dart run build_runner build --delete-conflicting-outputs
cd ../..

cd firebase/functions && npm install && cd ../..

cp .env.example .env
cp firebase/.firebaserc.example firebase/.firebaserc
# Sửa 2 file trên với project ID thật

flutter run    # Trong apps/mobile
```

Setup chi tiết: [`docs/team-workflow.md`](docs/team-workflow.md) §2.

## Workflow

| Bước | Tool / file |
|---|---|
| Tạo feature | `git checkout -b feature/<DevName>/<desc> develop` |
| Commit | Conventional Commits + tiếng Việt (xem `.gitmessage`) |
| PR | Title + body tiếng Việt theo `.github/pull_request_template.md` |
| Review | ≥ 1 reviewer (anh) approve, CI PASS |
| Merge | Squash and merge vào `develop` |
| Release | Anh tạo PR `develop` → `deploy`, manual approval, CI deploy prod |

Full workflow: [`docs/team-workflow.md`](docs/team-workflow.md).

## Development

### Chạy app

```bash
cd apps/mobile
flutter run -d android               # Debug Android (target chính)
flutter run --release                # Test release build
# flutter run -d ios                 # iOS deferred — xem ADR-0002
```

### Chạy Cloud Functions emulator

```bash
cd firebase
firebase emulators:start
# Mở http://localhost:4000 cho Emulator UI
```

### Test

```bash
# Flutter
cd apps/mobile && flutter test
cd apps/mobile && flutter test --coverage

# Functions
cd firebase/functions && npm test

# Firestore rules
cd firebase && firebase emulators:exec --only firestore "cd functions && npm run test:rules"

# All
npm test                             # From root, runs flutter + functions
```

### Lint + format

```bash
cd apps/mobile
flutter analyze
dart format --set-exit-if-changed lib test

cd firebase/functions
npm run lint
npm run typecheck
```

## Repo structure

```
Meep/
├── apps/
│   ├── mobile/                # Flutter app (primary client)
│   └── widget/                # Native home-screen widget (Android AppWidget; iOS WidgetKit deferred per ADR-0002)
├── firebase/
│   ├── functions/             # Cloud Functions (TypeScript)
│   ├── firestore.rules        # Security rules
│   ├── firestore.indexes.json
│   └── storage.rules
├── services/
│   └── api/                   # OPTIONAL standalone Node BE (không có cho đến khi cần)
├── docs/
│   ├── specs/                 # Feature specs (`/spec` workflow)
│   ├── plans/                 # Implementation plans (`/plan` workflow)
│   ├── adr/                   # Architectural Decision Records
│   └── team-workflow.md       # ← Đọc trước khi viết commit đầu tiên
├── tasks/                     # Short-lived TODO checklists
├── .github/
│   ├── workflows/             # GitHub Actions CI/CD
│   ├── ISSUE_TEMPLATE/        # Issue templates tiếng Việt
│   ├── CODEOWNERS
│   └── pull_request_template.md
├── .husky/                    # Local git hooks (commit-msg, pre-commit, pre-push)
├── .windsurf/                 # AI agent rules + skills + workflows
├── AGENTS.md                  # AI agent operating manual
├── CONTEXT.md                 # Domain language reference
├── commitlint.config.js
├── package.json               # husky + commitlint
└── .gitmessage                # Commit message template tiếng Việt
```

## Documentation

- [Team Workflow](docs/team-workflow.md) — Branching, commit, PR, CI/CD chi tiết
- [Agent Manual](AGENTS.md) — Cho AI agent (Cascade) khi pair-program
- [Domain Language](CONTEXT.md) — Vocabulary của project (Post, Pair ID, Fan-out, ...)
- [ADR](docs/adr/) — Quyết định kiến trúc lớn

## License

Capstone project — không public license. Reach out anh nếu muốn fork/reuse.

## Acknowledgements

- Methodology skills (TDD, systematic debugging) — adapted from [obra/superpowers](https://github.com/obra/superpowers).
- Coding guidelines — based on [Andrej Karpathy's coding guidelines](https://karpathy.bearblog.dev/).
