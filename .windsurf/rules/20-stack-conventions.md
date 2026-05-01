---
trigger: always_on
---

# Stack Conventions — General

Project-wide conventions that apply regardless of which subsystem you're touching.

For language- / framework-specific rules, see:

- `21-flutter-rules.md` — loaded when editing `apps/mobile/**`
- `22-functions-rules.md` — loaded when editing `firebase/functions/**` or `services/api/**`
- `23-firestore-rules.md` — loaded when editing Firestore/Storage rules + indexes

## Git — Team Workflow

### Branches

- **`develop`** — integration branch (default). All features merge here via PR.
- **`deploy`** — production. Only merged from `develop` via PR (end of sprint, near release).
- **Feature branch format:** `<type>/<DevName>/<short-desc>`
  - Type enum: `feature`, `fix`, `chore`, `refactor`, `docs`, `test`, `style`, `perf`, `build`, `ci`, `revert`.
  - DevName: PascalCase (e.g. `ThienPDM`, `KhoaLND`).
  - Short-desc: lowercase, kebab-case, English (technical).
  - Examples: `feature/ThienPDM/auth-google-signin`, `fix/KhoaLND/feed-empty-state`, `chore/HoaiNT/bump-firebase-deps`.
- Always checkout feature branches from `develop`: `git checkout -b feature/ThienPDM/auth-google develop`.

### Commits (Conventional Commits + Vietnamese)

- **One logical change per commit.** No "WIP", no vague "fixes".
- **Format:**
  ```
  <type>(<scope>): <short Vietnamese description>

  <optional body — Vietnamese, explain WHY>

  <footer — Refs #N or Closes #N>
  ```
- **Subject ≤ 72 chars**, no trailing period, description in Vietnamese.
- **Type:** lowercase English (`feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `style`, `perf`, `build`, `ci`, `revert`).
- **Scope:** module — `auth`, `feed`, `post`, `friend`, `widget`, `deps`...
- **Examples:**
  - `feat(auth): thêm đăng nhập Google qua Firebase Auth`
  - `fix(feed): xử lý feed rỗng khi user chưa có bạn`
  - `chore(deps): cập nhật firebase_core lên 3.10.0`
  - `refactor(post): tách PostMapper ra file riêng`

### Push & merge

- **Never** push directly to `develop` or `deploy` — always via PR.
- **`git push --force`:** forbidden on `develop`/`deploy`. `--force-with-lease` on your own feature branch OK when truly needed.
- **PR template** at `.github/pull_request_template.md`. Title + body in Vietnamese.
- **CI must PASS** before merge (commitlint + lint + test).
- **≥ 1 reviewer approve** (leader is default CODEOWNERS).

### When to release to `deploy`

- After sprint review → leader creates PR `develop` → `deploy` with title `release: v0.X.Y`.
- CI deploys production automatically (with manual approval gate).
- Tag git release `v0.X.Y` from the merge commit SHA.

## Naming

| Thing | Convention | Example |
|---|---|---|
| Folders | `kebab-case` | `feed-controller/` |
| Dart files | `snake_case` | `feed_controller.dart` |
| Dart classes | `UpperCamelCase` | `FeedController` |
| Dart vars/methods | `lowerCamelCase` | `fetchFeed()` |
| TS vars/functions | `camelCase` | `fetchFeed()` |
| TS classes/types | `PascalCase` | `FeedController`, `Post` |
| Firestore collections | plural `lower_snake_case` | `posts`, `friend_requests` |
| Firestore fields | `camelCase` | `createdAt`, `authorId` |
| Storage paths | `posts/{uid}/{postId}/{filename}.jpg` | — |
| Env vars | `UPPER_SNAKE_CASE` | `FIREBASE_PROJECT_ID` |

## Tech-stack decisions (already made — do NOT re-litigate)

- Flutter (not RN, not native+native).
- Riverpod 2 with code-gen for state management.
- `freezed` + `json_serializable` for data classes.
- Firebase first for backend.
- Node 20 + TypeScript (strict) for any server-side code.
- `vitest` for TypeScript tests (over Jest).
- `flutter_test` + `fake_cloud_firestore` + `firebase_auth_mocks` for Flutter tests.

## File / module organization

- **Feature-first**, not layer-first. Each feature folder owns its data + logic + UI.
- **Files ≤ 300 lines.** If a file grows beyond that, look for a split.
- **Imports at the top** — no lazy imports mid-file unless there's a documented reason (e.g. cold-start optimization in Cloud Functions).

## Comments & docs

- Comments explain **why**, not **what** — the code says what.
- Public APIs (exported classes / functions in libraries) get a short doc comment.
- Don't leave `// TODO` without a linked issue or `// TODO(<name>): ...`.

## When to write a new doc

| Decision scope | Where it goes |
|---|---|
| Feature design | `docs/specs/YYYY-MM-DD-<feature>.md` (via `/spec`) |
| Implementation breakdown | `docs/plans/YYYY-MM-DD-<feature>.md` (via `/plan`) |
| Architectural decision (cross-feature impact) | `docs/adr/NNNN-<title>.md` |
| Short-term checklist | `tasks/todo-<feature>.md` |

ADRs (Architectural Decision Records) are for "we chose X over Y because Z" decisions that future-you might re-question. Keep them ≤ 1 page.
