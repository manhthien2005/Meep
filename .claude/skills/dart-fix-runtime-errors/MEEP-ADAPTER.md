# Meep Adapter — dart-fix-runtime-errors

> Adapt official runtime error skill cho Meep.

## Meep runtime error sources

### 1. Flutter app crashes
- Source: Crashlytics dashboard (prod) or `flutter run` console (dev).
- Common types:
  - `LateInitializationError` — late field accessed before set
  - `Null check operator used on a null value` — bad `!` cast
  - `RangeError` — list index out of bounds
  - `setState() called after dispose()` — async after dispose anti-pattern (CLAUDE.md §Common gotchas)
  - `FirebaseException` not mapped → leaked from repository

### 2. AppError propagation
- Repository throws `AppError` (Pattern #2/#3 auth.md)
- Controller catches → state.error
- Widget displays Vietnamese message
- **Runtime error here = Pattern violation.** Ex: raw `Exception` leaked instead of `AppError`.

### 3. Riverpod error
- `ProviderException`: thrown by `ref.read(provider)` when provider build fails
- Common cause: missing `ProviderScope.overrides` in `main.dart` for stub providers (Pattern #1 Skeleton rule)

### 4. Native Kotlin widget crash
- Source: Android logcat (`adb logcat`)
- Common: `WidgetSyncWorker` failed token fetch → silent retry forever
- Fix: bounded retry + backoff

## MCP-driven workflow (if Dart MCP connected)

```
1. mcp__dart__get_runtime_errors      → fetch active stack trace
2. mcp__dart__hover (at error file:line) → understand the type involved
3. Read suspicious file
4. Edit fix
5. mcp__dart__hot_reload              → apply
6. mcp__dart__get_runtime_errors (clearRuntimeErrors: true) → verify gone
```

## Verification after fix

| Fix type | Verify command |
|---|---|
| Widget render error | `mcp__dart__hot_reload` + visual check |
| Repository error mapping | Add test in `test/features/<module>/data/` (cite `dart-add-unit-test` adapter) |
| Riverpod scope bug | Add `ProviderContainer` test (cite `dart-add-unit-test` adapter) |
| Native widget crash | Kotlin unit test `apps/mobile/android/app/src/test/kotlin/` |

## Don't fix the symptom (CLAUDE.md banned pattern)

❌ DON'T:
```dart
try { riskyOp(); } catch (_) {} // silent swallow
```

✅ DO:
```dart
try {
  riskyOp();
} on FirebaseException catch (e) {
  throw _mapXxxError(e); // typed AppError với Vietnamese msg
}
```

## Cite as authority

- `.claude/skills/dart-fix-runtime-errors/SKILL.md`
- `.claude/reference-architectures/auth.md` Pattern #2 (error mapping) + #3 (AppError sealed)
- `apps/mobile/CLAUDE.md` §Error model
