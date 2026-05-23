# Flutter / Dart Rules

> Loaded when working in `apps/mobile/`. Supplements root `CLAUDE.md`.

## Layering (strict)

- **No Firestore / FirebaseAuth / Storage call in widgets or controllers.** All Firebase I/O goes through a `Repository` class.
- **No business logic in widgets.** Widgets render state and dispatch intents.

```
core/               — DI (Riverpod), theme, error model, routing
features/<feature>/
  data/             — repositories (Firestore, Storage, local cache)
  application/      — controllers / state notifiers / services
  presentation/     — widgets / pages
```

A widget that touches `FirebaseFirestore.instance` directly is a bug.

## State management — Riverpod 2 (code-gen)

- Use `@riverpod` annotation + code-gen: `dart run build_runner build --delete-conflicting-outputs`.
- `ref.watch` / `ref.read` only — do NOT mix `Provider.of(context)`.
- Inject every dependency via a Riverpod provider — no global singleton, no `getIt` inside business logic.
- `ref.onDispose(() => sub.cancel())` for every stream subscription.

## Data classes — freezed + json_serializable

- Always immutable. No mutable fields.
- Convert `DocumentSnapshot` → model in a `fromFirestore(snap)` factory on the data class. NEVER inline in widgets/controllers.

## Error model

- Throw typed `AppError`s, never raw `Exception`. Subclass per failure (`AuthFailedError`, `PostNotFoundError`...).
- Repositories convert `FirebaseException` / `PlatformException` into `AppError` at the boundary.

## Async / streams

- Prefer `Stream` from Firestore for live data (feeds, friend list).
- Use `StreamProvider` / `FutureProvider` to surface to UI.
- NEVER `Future.delayed(...)` to "wait for state".

## Widget split thresholds

| Smell | Threshold | Action |
|---|---|---|
| Widget body | > 150 lines | Split into sub-widgets |
| Function / method | > 80 lines | Extract method |
| Class | > 300 lines | Split by SRP |
| Nesting | > 5 levels | Early return / extract |

| Usage frequency | Extract to |
|---|---|
| Used ≥ 2 times in 1 feature | `features/<feature>/presentation/widgets/` |
| Used ≥ 3 times cross-feature | `lib/shared/widgets/` |

## Widget-specific

- `const` constructors when possible.
- `ListView.builder` for lists > 5 items. NEVER `ListView(children: [...])` for unbounded lists.
- NEVER pass huge inline `Map`/`List` as widget props — extract to `static const`.

## Testing

- Unit-test controllers + repositories with `fake_cloud_firestore` and `firebase_auth_mocks`.
- Widget tests for non-trivial UI (form, list, dialog).
- Integration test for login + post + feed loop minimum.
- Prefer `FakeFirebaseFirestore` over `MockFirestore`.
- Test files mirror lib: `lib/features/feed/post_repository.dart` ↔ `test/features/feed/post_repository_test.dart`.

```bash
flutter test
flutter test test/features/feed/
flutter test --coverage
flutter analyze
dart format --set-exit-if-changed .
```

## Common gotchas

| Issue | Fix |
|---|---|
| `Future` inside `build()` | Use `FutureProvider` / `StreamProvider` |
| Slow rebuild | `const` constructors, `ref.watch(provider.select(...))` |
| `setState()` after dispose | Check `mounted` first, or migrate to Riverpod |

---

## Flutter UI Patterns — Presentation Layer

### Design tokens — NO hardcoding

- Hardcoded color `Color(0xFF1A73E8)` → use `Theme.of(context).colorScheme.primary`.
- Hardcoded font `TextStyle(fontSize: 16)` → use `Theme.of(context).textTheme.bodyMedium`.
- Figma has new color/font not in theme → **add to `core/theme/` first via leader-gated PR**.

### Solo-dev module scope

Module Owner được touch tất cả layers trong module mình. Khoá lại + ping leader khi cần:
- `apps/mobile/lib/core/theme/` — shared design tokens.
- `apps/mobile/lib/shared/widgets/` — cross-module widget reuse.
- `apps/mobile/lib/core/error/`, `core/router/`, `core/di/` — shared infra.
- `firebase/firestore.rules`, `storage.rules`, `firestore.indexes.json`.
- `features/<other-module>/**` — module của dev khác.

### Accessibility — minimum required

- Every `IconButton`, `GestureDetector`, custom tap area: `Semantics(label: '...')` or `tooltip`.
- Touch target ≥ 48x48 logical pixels.
- NEVER `fixedFontSize` on `Text`.

### Figma → Flutter mapping

1. 1 Figma frame = 1 widget class.
2. Layer name → variable/widget name: `btn_primary_lg` → `PrimaryButtonLarge`.
3. Frame Auto-Layout → `Column`/`Row` with `spacing` or `SizedBox` token.
4. Component variants → enum + factory constructor: `Button.primary()`, `Button.secondary()`.

### Loading / error / empty — 4 required states

```dart
ref.watch(provider).when(
  loading: () => LoadingIndicator(),
  error: (e, _) => ErrorView(error: e),
  data: (items) => items.isEmpty
      ? EmptyState(message: 'Chưa có gì ở đây')
      : ItemList(items: items),
);
```

Empty state must have a Vietnamese CTA.

### Ask leader before

- Adding a new UI dependency (`flutter_animate`, `gap`, `flutter_svg`...).
- Overriding `MaterialApp` global theme.
- Changing `core/theme/` shared tokens.
