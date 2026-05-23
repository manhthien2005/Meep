# /review — Five-Axis Code Review

> "15 minutes of self-review saves 30 minutes of debugging + 2 hours of rollback."

**Thứ tự bắt buộc:** `/build` → `/review` → `gh pr create`. KHÔNG tạo PR trước khi `/review` sạch.

## Pre-flight

Identify scope:
```bash
git diff develop...HEAD --stat
git log develop..HEAD --oneline
```

| Diff size | Path |
|---|---|
| ≤ 50 lines | **Fast** — Axes Contract + Correctness + Security (~5 phút) |
| 50-500 lines | **Standard** — Full 6 axes (~10 phút) |
| > 500 lines | **STOP** — Recommend split PR before review |

Override: `--deep` forces full 6 axes regardless of size.

## Phase 1 — Read context

1. Read spec: `docs/specs/<feature>.md` + `docs/plans/<feature>.md`.
2. Check commit messages: what did the author intend?
3. Map changed files to layers (data / application / presentation / config / rules / functions).

## Phase 2 — Run automated checks

```bash
# Flutter
cd apps/mobile
flutter analyze
flutter test
dart format --set-exit-if-changed .

# Functions / BE
cd firebase/functions
npm run lint
npm test
```

## Phase 3 — Manual 6-axis pass

### Axis 0 — Contract Adherence (HIGHEST PRIORITY)

> Code lệch contract = automatic 🔴, dù logic "đúng".

- [ ] Code đáp ứng đầy đủ acceptance criteria trong spec?
- [ ] Freezed model: KHÔNG đổi field name/type mà không qua leader?
- [ ] Abstract interface: KHÔNG đổi method signature?
- [ ] Module owner KHÔNG touch code module khác?
- [ ] KHÔNG touch shared code (`core/`, `shared/widgets/`, `firestore.rules`) nếu chưa ping leader?
- [ ] TODO marker format đúng `// TODO(<task-id>/<DevName>): ...`?

### Axis 1 — Correctness

- [ ] Logic đúng cho happy path?
- [ ] Edge cases: empty/null/max/boundary/negative?
- [ ] Error path: throw `AppError` đúng type, không swallow?
- [ ] Async: race condition? `mounted` check sau await?
- [ ] State: clear source of truth, no stale state?

🔴 Critical:
- `await` rồi `setState()` không check `mounted` → crash.
- Throw raw `Exception` thay vì `AppError` typed.

### Axis 2 — Readability (skip nếu lint clean)

Skip nếu `flutter analyze` + `dart format` exit 0.

Only flag:
- [ ] Naming describes intent (not implementation).
- [ ] Function > 80 lines → split.
- [ ] Comment explains **why**, not **what**.
- [ ] Magic number → named constant.

### Axis 3 — Architecture

- [ ] Layering: data → application → presentation. UI KHÔNG call `FirebaseFirestore.instance` directly.
- [ ] Reuse existing pattern (Repository, Riverpod provider).
- [ ] DI explicit — no hidden singleton.
- [ ] No premature abstraction (single-impl interface without reason).

🔴 Critical:
- Widget calls `FirebaseFirestore.instance.collection(...)` trực tiếp → bypass repository.
- Native widget Android (`apps/widget/`) calls Firebase SDK trực tiếp.

### Axis 4 — Security (Meep-specific)

- [ ] No hardcoded secret / API key in source.
- [ ] User input validated (zod for TS, form validator for Flutter).
- [ ] Auth check on every protected endpoint.
- [ ] PII (email, displayName, caption) NOT in logs.

**7 Meep hot points:**
- [ ] Firestore rules change → có rules unit test: owner / friend / stranger / unauthenticated?
- [ ] Image upload → MIME + size validate **server-side** (Storage rule or Cloud Function)?
- [ ] EXIF data strip trong resize Function?
- [ ] Pair ID computation deterministic? (`min < max` sort)
- [ ] Cloud Function trigger → region `asia-southeast1` explicit?
- [ ] Cloud Function timeout + maxInstances explicit?
- [ ] Native widget (`apps/widget/`) → KHÔNG call Firebase trực tiếp?

🔴 Critical:
- Firestore rule `allow read, write: if true` (kể cả tạm).
- Caption body trong logger.

### Axis 5 — Performance

- [ ] No N+1 Firestore query.
- [ ] Pagination on large list (not `.get()` whole collection).
- [ ] Compound query → index in `firestore.indexes.json`?
- [ ] Flutter rebuild: `const` constructor, `ListView.builder` for list > 5.
- [ ] Stream disposal: `ref.onDispose(() => sub.cancel())`.
- [ ] Cloud Function cold start: heavy imports lazy inside handler.

🔴 Critical:
- `ListView(children: List.generate(1000, ...))`.
- Firestore query không có index → fail prod.

## Phase 4 — Output

### Default (precision-first)

```markdown
## Code Review: <module/scope>

### 🔴 Critical
- <file:line> <issue> → <fix>

### 🟡 Important
- <file:line> <issue> → <fix>

### Summary
- Path: Fast / Standard
- Diff: <X> lines, <Y> files
- Verdict: BLOCK (có 🔴) / NEEDS-FIX (có 🟡) / READY-TO-MERGE
```

**Stop conditions:**
- ≥ 1 🔴 → output **only** 🔴 + Summary. Focus dev fix Critical, re-review sau.
- Fast path → max 5 findings.
- KHÔNG bikeshed naming/style khi lint đã clean.

## Phase 5 — Action

- 🔴 or 🟡 → return to `/build` or `/fix-issue`. After fix → re-review delta only.
- All clean → merge / approve.

After clean:
```bash
git push origin <branch>
gh pr create --base develop \
  --title "<type>(<scope>): <mô tả tiếng Việt>" \
  --body "$(cat .github/pull_request_template.md)"
```

## Quick checklist (mini-review for small commits)

- [ ] Tests pass (ran command, read output).
- [ ] Lint clean.
- [ ] Diff focused — only changes for this task.
- [ ] No `console.log` / `print` debug left.
- [ ] No commented-out dead code.
- [ ] No `// TODO` without linked issue.
- [ ] Commit message conventional + Vietnamese description.
- [ ] Branch name `<type>/<DevName>/<short-desc>`.
- [ ] Cross-module touch: KHÔNG đụng module dev khác.
