---
trigger: glob
globs: apps/mobile/**/*.dart,apps/mobile/pubspec.yaml,apps/mobile/test/**,apps/mobile/integration_test/**
---

# Flutter / Dart Rules

Loaded only when editing the Flutter app. For general rules see `20-stack-conventions.md`.

## Layering (strict)

- **No Firestore / FirebaseAuth / Storage call in widgets or controllers.** All Firebase I/O goes through a `Repository` class.
- **No business logic in widgets.** Widgets render state and dispatch intents.
- **Layered:**
  - `core/` — DI (`Provider`/`Riverpod`), theme, error model, routing.
  - `features/<feature>/data/` — repositories (Firestore, Storage, local cache).
  - `features/<feature>/application/` — controllers / state notifiers / services.
  - `features/<feature>/presentation/` — widgets / pages.

A widget that touches `FirebaseFirestore.instance` directly is a bug. Push the call into a repository.

## State management — Riverpod 2 (code-gen)

- Use `@riverpod` annotation + code-gen — `dart run build_runner build --delete-conflicting-outputs`.
- Use `ref.watch` / `ref.read` only — do NOT mix in `Provider.of(context)` from the `provider` package.
- Inject every dependency via a Riverpod provider — **no global singleton, no `getIt` lookup inside business logic**.
- Cancel subscriptions / streams in `ref.onDispose(() => sub.cancel())`.

**Pattern reference:** see skill `flutter-firebase-patterns` (`FeedController` example + repository wiring).

## Data classes — freezed + json_serializable

- Always immutable. No mutable fields.
- Don't add behaviour to data classes — keep them dumb.
- Convert `DocumentSnapshot` → model in a `fromFirestore(snap)` factory on the data class, or in a separate `mapper.dart`. NEVER inline in widgets/controllers.

**Pattern reference:** see skill `flutter-firebase-patterns` (full `Post` freezed example + `fromFirestore` factory).

## Error model

- Throw typed `AppError`s, never raw `Exception`. Subclass per failure case (`AuthFailedError`, `PostNotFoundError`, ...).
- Use `Result<T, AppError>` returns when the caller is expected to handle the error path branch-by-branch (instead of try/catch in the UI).
- Repositories convert `FirebaseException` / `PlatformException` into `AppError` at the boundary.

## Async / streams

- Prefer `Stream` from Firestore for live data (feeds, friend list).
- Use `StreamProvider` / `FutureProvider` to surface to UI.
- Always cancel subscriptions: in Riverpod use `ref.onDispose(() => sub.cancel())`.
- Don't `Future.delayed(...)` to "wait for state" — use proper completion (`pumpAndSettle()`, `expectLater(future, completes)`).

## Code organization & widget split

Applies to **all Dart files** in `apps/mobile/**`. Solo-dev module owner editing `presentation/` cũng follow rule này — plus UI-specific rule trong `24-flutter-ui-patterns.md`.

### When to split (split threshold)

| Smell | Threshold | Action |
|---|---|---|
| Widget body | > 150 lines | Split into sub-widgets (private `_HeaderSection`, `_ContentSection` in same file, or separate file) |
| Function / method | > 80 lines | Extract method with clear intent name |
| Class | > 300 lines | Split by SRP — 1 class = 1 responsibility |
| Constructor / function parameters | > 5 | Consider config object or class wrapper |
| Cyclomatic complexity (branch + loop) | > 15 | Extract complex logic into helper functions |
| Nesting (if/for/while nested) | > 5 levels | Early return, extract method, or use data structures instead of branches |

These thresholds are **guidelines for code review + linter (once set up)**, not hard limits. Legitimate cases may exceed them (e.g. switch case mapping 25 Firebase error codes) — use `// ignore_for_file:` annotation with explanatory comment.

### When to reuse (extraction threshold)

| Usage frequency | Extract to |
|---|---|
| Used ≥ 2 times in 1 feature | `features/<feature>/presentation/widgets/` (for widgets) or `features/<feature>/<layer>/_helpers.dart` (for logic) |
| Used ≥ 3 times cross-feature | `lib/shared/widgets/` (for widgets) or `lib/core/<topic>/` (for utilities) |
| Used once but **complex logic** ≥ 30 lines | Extract method/widget in same file, with clear intent name |

### Widget-specific

- Use `const` constructors when possible — child equality holds, fast rebuild.
- `ListView.builder` for lists > 5 items. NEVER `ListView(children: [...])` for unbounded lists.
- NEVER pass huge inline `Map` / `List` as widget props — extract to `static const`.
- File names `snake_case`, class names `UpperCamelCase`. Match Figma layer names when reasonable.

### File length

- File ≤ 300 lines (per `20-stack-conventions.md` §File / module organization).
- File `*.g.dart`, `*.freezed.dart` (generated) exempt.
- Test files relaxed — arrange-act-assert can be long, but if > 500 lines → split test groups.

## Testing

- Unit-test controllers + repositories with `fake_cloud_firestore` and `firebase_auth_mocks`.
- Widget tests for any non-trivial UI (form, list, dialog).
- Integration test for the login + post + feed loop minimum.
- Don't mock things you can fake: prefer `FakeFirebaseFirestore` over `MockFirestore`.
- Test files mirror lib structure: `lib/features/feed/post_repository.dart` ↔ `test/features/feed/post_repository_test.dart`.

## Test commands

```bash
flutter test                                # all tests
flutter test test/features/feed/            # one folder
flutter test --coverage                     # with coverage
flutter analyze                             # lint
dart format --set-exit-if-changed .         # format check
```

## Common gotchas

Full table lives in skill `flutter-firebase-patterns`. The two that come up most while editing Dart code:

| Issue | Fix |
|---|---|
| `Future` inside `build()` | Use `FutureProvider` / `StreamProvider`, never call inside `build` |
| Slow rebuild | `const` constructors, split widgets, `ref.watch(provider.select(...))` for fine-grained Riverpod |
