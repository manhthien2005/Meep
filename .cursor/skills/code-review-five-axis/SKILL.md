---
name: code-review-five-axis
description: Six-axis code review framework (folder name "five-axis" kept for backward compat) — Fast/Deep paths + precision-first output. Use when reviewing your own changes before PR or reviewing teammate's PR. Evaluates contract adherence, correctness, readability, architecture, security, performance — but defaults to flagging only real bugs (🔴 + 🟡), not nits.
---

# Code Review — Six-Axis (Solo-Dev Calibrated)

> Updated 2026-05-21: upgraded từ 5-axis generic sang 6-axis tuned cho Meep solo-dev model. Inspiration: Bugbot (precision-first), CodeRabbit (noise dials), Greptile (severity threshold), Google eng-practices ("improves overall health" not perfection).

## When to use

- **Self-review** trước khi `gh pr create`. Bắt buộc qua `/review` (xem `workflow-review.mdc`).
- **Reviewer review** — anh là default CODEOWNERS, co-required với module owner.
- **Stuck** — fresh perspective.

## Pre-flight — Detect path (Fast vs Deep)

Run trước khi bắt đầu axes:

```bash
git diff develop...HEAD --stat
```

| Diff size | Path | Time | Coverage |
|---|---|---|---|
| ≤ 50 lines | **Fast** | ~5 phút | Axes 0+1+4 (Contract / Correctness / Security). Skip Readability/Architecture/Performance unless code touches hot points. |
| 50-500 lines | **Standard** | ~10 phút | Full 6 axes. |
| > 500 lines | **STOP** | — | Recommend split PR trước khi review. ≥ 200 lines/PR = ideal industry. |

**Override:**
- `/review --deep` → force Deep path bất kể size.
- `/review --fast` → force Fast path (chỉ dùng cho hotfix mà anh đã hiểu rõ).

## Severity & precision rules

Bugbot pattern: **chỉ flag bug thật**. Default output:

| Tier | Khi flag | Default? |
|---|---|---|
| 🔴 Critical | Bugs, security holes, breaking changes, contract violation | Always |
| 🟡 Important | Performance issue, maintainability blocker, missing test | Always |
| 🟢 Suggestion | Nit, naming, micro-optimization, style | **Skip default** — only on `/review --deep` |
| ✅ Highlights | Good pattern dev did | **Skip default** — only on `/review --deep` |

**Stop conditions:**

- Có ≥ 1 🔴 → **STOP output 🟢/✅**. Focus dev fix Critical trước. Re-review sau.
- Fast path → max 5 findings tổng. Không liệt kê quá nhiều.
- KHÔNG bikeshed naming/style khi `flutter analyze` + `dart format` đã clean — linter làm rồi.

---

## Axis 0 — Contract Adherence (HIGHEST PRIORITY)

> Solo-dev model của Meep: leader define spec + freezed model + abstract interface upfront. Code lệch contract = automatic 🔴, dù logic "đúng".

**Read first:**
- `docs/specs/<module>.md` — acceptance criteria.
- Freezed model file của module — field signature.
- Abstract interface file — method signature.

**Checklist:**

- [ ] Code đáp ứng đầy đủ acceptance criteria trong spec? (trace từng AC → code).
- [ ] Freezed model: KHÔNG đổi field name/type/required-ness mà không qua leader?
- [ ] Abstract interface: KHÔNG đổi method signature, return type, exception?
- [ ] Module owner KHÔNG touch code module khác? (cross-module strict — xem `25-dev-code-standards.mdc`).
- [ ] KHÔNG touch shared code (`core/`, `shared/widgets/`, `firestore.rules`) nếu chưa ping leader?
- [ ] Spec mention "no Firestore collection mới" → code KHÔNG tạo collection mới?
- [ ] TODO marker `// TODO(<task-id>/<DevName>): ...` đã wire correct DevName?

**🔴 Critical examples:**
- Spec yêu cầu username unique nhưng code không check → contract violation.
- Dev thêm field `bio` vào `UserProfile` model mà spec không có → tự ý đổi contract.
- Dev sửa 1 dòng trong `features/auth/` khi đang làm task module `feed/` → cross-module touch.

---

## Axis 1 — Correctness (does it work?)

**Checklist:**

- [ ] Logic đúng cho happy path?
- [ ] Edge cases: empty/null/max/boundary/negative?
- [ ] Error path: throw `AppError` đúng type, không swallow?
- [ ] Async/concurrency: race condition? `mounted` check sau await?
- [ ] State: clear source of truth, no stale state?
- [ ] Off-by-one / timezone / encoding?

**🔴 Critical:**
- `await` rồi `setState()` không check `mounted` → crash sau dispose.
- Throw raw `Exception` thay vì `AppError` typed → caller không catch được.

**🟡 Important:**
- Empty list handling missing.
- Edge case max-length boundary chưa test.

---

## Axis 2 — Readability (auto-skip nếu lint clean)

> Skip nếu `flutter analyze` + `dart format --set-exit-if-changed` exit 0 — linter đã catch syntax/style.

**Chỉ flag:**

- [ ] Naming describe intent, KHÔNG implementation (`fetchUserById` ✓, `doDbStuff` ✗).
- [ ] Function > 80 lines → split (xem rule 21 §Code organization).
- [ ] Comment giải thích **why**, không **what**.
- [ ] Magic number → named constant.

**🟡 Important:** Function 200 lines, 5 nested if.
**🟢 Suggestion (skip default):** rename biến `temp` → `imageBytes`, extract magic number `200` → `kCaptionMaxLength`.

---

## Axis 3 — Architecture (does it fit the system?)

**Checklist:**

- [ ] Layering: data → application → presentation. UI KHÔNG call `FirebaseFirestore.instance` directly.
- [ ] Dependency direction: feature import shared, không reverse.
- [ ] Reuse existing pattern (Repository, Riverpod provider) — không invent ad-hoc.
- [ ] Boundary qua interface — implementation swap-able.
- [ ] DI explicit — KHÔNG hidden singleton, KHÔNG global mutable state.
- [ ] No premature abstraction (single-impl interface, factory không lý do).

**🔴 Critical:**
- Widget call `FirebaseFirestore.instance.collection(...)` trực tiếp → bypass repository.
- Native widget Android (apps/widget/) call Firebase SDK trực tiếp → KHÔNG được. Phải qua `home_widget` package.

**🟡 Important:**
- Tạo Riverpod controller mới khi có thể consume controller existing.
- Singleton `GetIt` lookup giữa controller — phải inject qua provider.

---

## Axis 4 — Security (Meep-specific)

**Generic:**
- [ ] No hardcoded secret / API key / FCM server key trong source.
- [ ] User input validate qua zod (TS) hoặc form validator (Flutter). KHÔNG trust client.
- [ ] Auth check trên mọi protected endpoint / Firestore rule (`request.auth != null`).
- [ ] Authz check: ownership (`isOwner(uid)`) — không chỉ "is authenticated".
- [ ] PII (email, phone, displayName, caption) KHÔNG log vào `console.log`/`logger.*`/`print`/Crashlytics.

**Meep-specific (7 hot points):**
- [ ] Firestore rules change → có rules unit test cover **owner / friend / stranger / unauthenticated**?
- [ ] Image upload → MIME (`image/.*`) + size (≤ 10 MB) validate **server-side** (Storage rule hoặc Cloud Function), không chỉ client?
- [ ] EXIF data strip trong resize Function? (location lộ → privacy issue cho Meep).
- [ ] Pair ID computation deterministic? (`min < max` sort — xem `05-domain-language.mdc`).
- [ ] Cloud Function trigger → region `asia-southeast1` explicit?
- [ ] Cloud Function timeout + maxInstances explicit?
- [ ] Native widget code (`apps/widget/`) → KHÔNG call Firebase trực tiếp, qua `home_widget` only.

**🔴 Critical:**
- Firestore rule `allow read, write: if true` (kể cả tạm).
- Hardcoded `ghp_xxx` trong source.
- Caption body log vào logger.

---

## Axis 5 — Performance (Meep hot points)

**Checklist:**

- [ ] Firestore: KHÔNG N+1 query (1 query 50 users, không 50 queries 1 user).
- [ ] Pagination on large list — không `.get()` whole collection.
- [ ] Compound query → index declared trong `firestore.indexes.json`?
- [ ] Image: resize trước upload, lazy-load, cache (`cached_network_image`).
- [ ] Cloud Function cold start: heavy import (`sharp`, `firebase-admin/messaging`) lazy inside handler, không top-level.
- [ ] Flutter rebuild: `const` constructor, `ListView.builder` (không `ListView(children: [...])` cho list > 5).
- [ ] Riverpod: `ref.watch(provider.select(...))` nếu chỉ cần subset.
- [ ] Stream/controller dispose: `ref.onDispose(() => sub.cancel())` cho mọi subscription.

**🔴 Critical:**
- `ListView(children: List.generate(1000, ...))` — render off-screen widgets.
- Firestore query không có index → fail trên prod (works trên emulator).

**🟡 Important:**
- Stream subscription không dispose → memory leak.
- Function top-level `import sharp` → cold start +500ms.


---

## Output format

### Default (precision-first — Fast or Standard path)

```markdown
## Code Review: <module/scope>

### 🔴 Critical
- <file:line> <issue> → <fix>

### 🟡 Important
- <file:line> <issue> → <fix>

### Summary
- Path: Fast / Standard / Deep
- Diff: <X> lines, <Y> files
- Verdict: BLOCK (có 🔴) / NEEDS-FIX (có 🟡) / READY-TO-MERGE
```

### Deep path output (chỉ khi user gõ `/review --deep`)

```markdown
## Code Review: <module/scope>

### 🔴 Critical
- ...

### 🟡 Important
- ...

### 🟢 Suggestion (nit — fix nếu thuận tiện, không block)
- ...

### ✅ Highlights
- <good pattern dev did, reinforce>

### Summary
- ...
```

### Stop conditions

- Có ≥ 1 🔴 → output **CHỈ** 🔴 + Summary. KHÔNG output 🟡/🟢/✅. Focus dev fix Critical, re-review sau.
- Fast path → max 5 findings tổng. Nếu vượt → recommend chuyển sang Standard/Deep.

---

## Example outputs

### Fast path output

```markdown
## Code Review: PostRepository fix

### 🔴 Critical
- `post_repository.dart:45`: `createPost` không validate `authorId != null` trước query → crash khi user logout race với upload. Fix: throw `AppError.unauthenticated()` early.

### Summary
- Path: Fast (32 lines, 2 files)
- Verdict: BLOCK — fix Critical trước.
```

### Standard path with multiple issues

```markdown
## Code Review: Feed pagination

### 🔴 Critical
- `feed_repository.dart:78`: Compound query `where('authorId', whereIn: ids).orderBy('createdAt', desc)` chưa có index trong `firestore.indexes.json` → fail prod, works emulator.

### 🟡 Important
- `feed_controller.dart:23`: Stream subscription không dispose. Add `ref.onDispose(() => sub.cancel())`.
- `feed_page.dart:56`: `ListView(children: List.generate(...))` cho 100 items → render off-screen. Đổi `ListView.builder`.

### Summary
- Path: Standard (180 lines, 4 files)
- Verdict: BLOCK — Critical (index missing) phải fix trước deploy.
```

---

## Anti-patterns trong review

| Anti-pattern | Vấn đề |
|---|---|
| "Looks good to me" không đọc kỹ | Rubber-stamp = no review |
| Bikeshed naming khi có 🔴 chưa fix | Lạc focus |
| Suggest rewrite cả module trong PR nhỏ | Scope creep |
| Block PR vì style preference (`if` vs ternary) | Religious, không ship |
| Flag 🟢 khi đã có 🔴 | Distract dev khỏi Critical |
| Liệt kê 20 findings cho PR 50 dòng | Token waste, dev nản |

---

## Self-review = ship faster

15 phút self-review tiết kiệm:
- 30 phút debug post-merge.
- 2 giờ rollback nếu break prod.
- Reputation với team.

---

## Quick checklist (run trước commit, không thay axis review)

```
[ ] Tests pass: `flutter test` / `npm test` ran, output read (skill `verification-before-completion`)
[ ] Lint clean: `flutter analyze` / `npm run lint` exit 0
[ ] Format clean: `dart format --set-exit-if-changed .`
[ ] Branch name: `<type>/<DevName>/<short-desc>`
[ ] No commented-out dead code
[ ] No `console.log` / `print` debug
[ ] No `// TODO` không link issue
[ ] Diff focused — chỉ thay đổi cho task này, không "while I'm here"
[ ] Commit message conventional + tiếng Việt mô tả WHY
[ ] Cross-module touch: KHÔNG đụng module dev khác (xem rule 25)
```

