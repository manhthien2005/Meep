# /build — Incremental Implementation (TDD)

> "The simplest thing that could work."

Implement task by task from `tasks/todo-<feature>.md`. Each task = one Red-Green-Refactor cycle. Each commit leaves codebase in a working state.

## Pre-flight

1. Read `docs/plans/<feature>.md` and `tasks/todo-<feature>.md`.
2. Branch must be `<type>/<DevName>/<short-desc>` — NOT `develop`/`deploy`.
   ```bash
   git branch --show-current
   ```
3. **Infra-file guard** — before touching `.claude/`, `.cursor/`, `.github/`, `docs/adr/`, `scripts/`:
   - Must be on `chore/<DevName>/...` branch, NOT `feature/`.
   - If on `feature/` branch → **STOP**. Stash → create `chore/<DevName>/<desc>` from `develop`.
4. Identify next task: first `- [ ]` not ticked.

## TDD Cycle — RED → GREEN → REFACTOR

### Phase RED — Write a failing test first

```dart
// Flutter
test('rejects post with empty caption', () async {
  final controller = PostController(repo: FakePostRepository());
  final result = await controller.createPost(caption: '', imageUrl: 'x.jpg');
  expect(result.isFailure, true);
  expect(result.error, isA<EmptyCaptionError>());
});
```

```ts
// Functions / BE
test('returns 400 when authorId missing', async () => {
  const res = await request(app).post('/posts').send({ caption: 'hi' });
  expect(res.status).toBe(400);
});
```

- One behavior per test.
- Real-ish code — use `fake_cloud_firestore`, in-memory fakes (NOT mocks of everything).

**Verify RED:**
```bash
flutter test test/<path>/<file>_test.dart   # or
npm test -- <file>.test.ts
```
Test must FAIL. If passes immediately → you're testing existing behavior, rewrite.

### Phase GREEN — minimum code to pass

Write only enough code for the test to pass. No extra options, no abstractions, no "for later" code.

**Verify GREEN:**
```bash
flutter test     # full suite
```

New test passes ✓ + old tests still pass ✓.

### Phase REFACTOR — clean up while green

- Rename for clarity, extract helpers, remove duplication.
- No new behavior during refactor. Tests stay green.

## Per-task workflow

### Step 1: Load context
- Read task description in plan.
- Read files to be touched (existing patterns + adjacent code).
- Confirm dependency tasks are done.

### Step 2: Run TDD cycle (above)

### Step 3: Final verify — MANDATORY

Before claiming done:
1. Which command proves this task is complete?
2. Run it (fresh, not a cached result).
3. Read the full output, count failures.
4. Only then claim done.

```bash
# Flutter
flutter test test/<feature>/ && flutter analyze

# Functions
cd firebase/functions && npm test && npm run lint
```

### Step 4: Commit

```bash
git branch --show-current               # confirm still on feature branch
git diff --name-only --cached           # scan staged files
git add <specific files>
git commit -m "feat(<scope>): <mô tả tiếng Việt>"
```

**Before `git add`:** scan staged files. If any path starts with `.claude/`, `.cursor/`, `.github/`, `docs/adr/`, `scripts/` → do NOT add on a `feature/` branch.

### Step 5: Update todo

```markdown
- [x] T2.1: Create PostRepository.createPost
- [ ] T2.2: ...
```

## Rules

| Rule | Why |
|---|---|
| ≤ 100 lines per increment | Test before writing too much |
| Touch only what's needed | No "while I'm here" refactors |
| `flutter analyze` / `npm run lint` clean after every commit | Keep it building |
| No skipped tests | `skip:` = tech debt |

## When you hit a blocker

1. **Stop** — don't push through a broken state.
2. Run `/debug` (systematic root cause, 4 phases).
3. Add a regression test alongside the fix.
4. Resume from where you stopped.

## When all tasks done

```bash
# Flutter
flutter test --coverage && flutter analyze

# BE
npm test -- --coverage && npm run lint
```

Then:
```bash
pwsh -File scripts/tick-issue-checklist.ps1 -IssueNum <issue-id>
pwsh -File scripts/set-issue-status.ps1 -IssueNum <issue-id> -Status "Review"
```

**Run `/review` — MANDATORY before creating PR.** Never `gh pr create` before `/review` passes.

## Flutter + Firebase patterns (quick reference)

> **Reference architecture:** `.claude/reference-architectures/auth.md` có 11 patterns chuẩn với file paths cụ thể. Snippets dưới đây là intro — đọc reference khi cần chi tiết / edge cases.

### Repository pattern

> Full pattern: AUTH reference §2 — abstract + Firebase impl + `_mapXxxError` boundary
> Files: [auth_repository.dart](../../apps/mobile/lib/features/auth/data/auth_repository.dart), [firebase_auth_repository.dart](../../apps/mobile/lib/features/auth/data/firebase_auth_repository.dart)

```dart
abstract class PostRepository {
  Future<Post> createPost({required String caption, required String imageUrl});
  Stream<List<Post>> watchFeed();
}

class FirestorePostRepository implements PostRepository {
  // All Firebase I/O here. NEVER in widgets/controllers.
  // try { ... } on FirebaseException catch (e) { throw _mapXxxError(e); }
}
```

### Riverpod controller

> Full pattern: AUTH reference §4 — `_afterFailure(e)` helper + `clearError()`
> File: [login_controller.dart](../../apps/mobile/lib/features/auth/application/login_controller.dart)

```dart
@riverpod
class FeedController extends _$FeedController {
  @override
  Future<List<Post>> build() async {
    return ref.watch(postRepositoryProvider).fetchFeed(limit: 20);
  }
}
```

### freezed data class

> Full pattern: AUTH reference §1 — folder layout
> File: [user_profile.dart](../../apps/mobile/lib/features/auth/data/user_profile.dart)

```dart
@freezed
class Post with _$Post {
  const factory Post({
    required String id,
    required String authorId,
    required String caption,
    required String imageUrl,
    required DateTime createdAt,
  }) = _Post;

  factory Post.fromFirestore(DocumentSnapshot snap) { ... }
}
```

### Error model

> Full pattern: AUTH reference §3 — `AppError.fromUnknown` + `OperationCancelledError`
> File: [app_error.dart](../../apps/mobile/lib/core/error/app_error.dart)

```dart
// ✅ Typed AppError — never raw Exception
if (uid == null) throw const UnauthenticatedError();

// Helper to collapse try-catch boilerplate
} catch (e) {
  state = _afterFailure(e);   // uses AppError.fromUnknown internally
}
```

## Anti-patterns

| Anti-pattern | Problem |
|---|---|
| Code first, test later | Test passes immediately → proves nothing |
| 5 consecutive "WIP" commits | Dirty history, can't revert |
| Mix 3 features in one commit | Hard to review |
| Skip RED verify | Test might test the wrong thing |
| `gh pr create` trước `/review` | Skip quality gate |
| "While I'm here" rename in unrelated files | Scope creep |
