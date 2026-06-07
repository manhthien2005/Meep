# Meep Adapter — flutter-apply-architecture-best-practices

> Map official Flutter skill (ChangeNotifier + provider/get_it + built_value) → Meep convention (Riverpod 2 codegen + freezed).
> Đọc file này SAU `SKILL.md` để override khi áp dụng cho Meep.

## Layer mapping

| Official skill | Meep equivalent |
|---|---|
| MVVM with `ViewModel extends ChangeNotifier` | `@riverpod` NotifierProvider — Pattern #4 in `auth.md` |
| `ListenableBuilder` / `AnimatedBuilder` | `ConsumerWidget` + `ref.watch(provider)` |
| `provider` / `get_it` DI | Riverpod `ProviderScope.overrides` |
| Repository injected via constructor | Repository injected via `ref.read(repositoryProvider)` |
| `built_value` / `freezed` for domain models | **`freezed` (mandatory)** + `json_serializable` |
| `lib/data/` + `lib/domain/` + `lib/ui/features/` | `lib/features/<module>/data/` + `application/` + `presentation/` (feature-first, NOT layer-first) |

## Folder convention override (Meep wins)

Meep is **feature-first**, official is layer-first. Khi apply skill:
```
✗ DO NOT: lib/data/feed_repository.dart + lib/ui/features/feed/feed_view.dart
✓ DO: lib/features/feed/data/firebase_post_repository.dart + lib/features/feed/presentation/feed_page.dart
```

Lý do: solo-dev module ownership (ADR-0004) — 1 dev own end-to-end 1 module folder.

## Riverpod-specific patterns (Pattern #4-7 auth.md)

```dart
// Repository provider
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => throw UnimplementedError(
  'wire FirebaseAuthRepository in main.dart',
);

// Controller (Notifier)
@riverpod
class LoginController extends _$LoginController {
  @override
  LoginState build() => const LoginState.idle();

  Future<void> signIn(String email, String password) async {
    state = const LoginState.loading();
    try {
      await ref.read(authRepositoryProvider).signInWithEmail(email, password);
      state = const LoginState.success();
    } on AppError catch (e) {
      state = LoginState.error(e);
    }
  }
}
```

## When to extract Use Case (Logic Layer)

Official skill says "optional". Meep guidance:
- KHÔNG extract use case nếu chỉ 1 controller dùng repository — controller đảm nhiệm.
- Extract use case khi 2+ controller share business rule (e.g., `CalculateStreakUseCase` dùng cả profile + streak).
- Use case place: `features/<module>/application/<name>_use_case.dart`.

## Error boundary (auth.md Pattern #2)

Repository impl tự map FirebaseException → AppError. Controller catch `AppError`. UI watch state. KHÔNG re-throw raw FirebaseException lên controller.

## Cite as authority

When auditing arch issues, cite both:
- `.claude/skills/flutter-apply-architecture-best-practices/SKILL.md` (official Flutter)
- `.claude/reference-architectures/auth.md` (Meep canonical)
- Meep adapter wins khi conflict.
