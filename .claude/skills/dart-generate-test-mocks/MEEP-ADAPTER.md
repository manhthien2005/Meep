# Meep Adapter — dart-generate-test-mocks

> Adapt official mockito skill cho Meep — but **prefer mocktail** as default.

## Meep preference: mocktail > mockito

Reasons:
1. **No build_runner step** — mocktail uses runtime instantiation, không cần codegen extra.
2. **Riverpod-friendly** — easier override pattern `overrideWithValue(MockRepo())`.
3. **Better null safety** — mockito requires `@GenerateMocks` annotations.

```dart
// mocktail (preferred)
class MockAuthRepository extends Mock implements AuthRepository {}

// usage
when(() => mockRepo.signInWithEmail(any(), any())).thenAnswer((_) async {});
verify(() => mockRepo.signInWithEmail('a@b.com', 'pass')).called(1);
```

## When mockito is OK

- Mocking class với **many methods + complex stubs** — `@GenerateMocks` save boilerplate.
- Project already standardized on mockito (Meep currently không có pattern fix; pick once).
- Need `MockFirebaseFirestore` from `firebase_auth_mocks` package — wraps mockito.

## Meep mock conventions

### Mock Firebase services
- **DON'T mock Firestore directly.** Use `FakeFirebaseFirestore` from `fake_cloud_firestore` (CLAUDE.md explicit preference).
- **DON'T mock FirebaseAuth directly.** Use `MockFirebaseAuth` from `firebase_auth_mocks`.
- **DO mock repository interfaces** — own code boundary.

### Mock external dependencies
- Mock `AuthRepository`, `PostRepository`, etc. (own contracts)
- Mock `ImagePicker`, `Camera`, `GeoLocator` plugins via abstraction layer
- Mock FCM via `FakeFirebaseMessaging` (community package) hoặc adapter

## Anti-pattern: mock-only test (CLAUDE.md §Test quality)

❌ DON'T:
```dart
test('controller calls repo', () async {
  await controller.signIn('a', 'b');
  verify(() => mockRepo.signInWithEmail('a', 'b')).called(1);
  // ← no business outcome assertion
});
```

✅ DO:
```dart
test('signIn success transitions state', () async {
  when(() => mockRepo.signInWithEmail(any(), any())).thenAnswer((_) async {});
  await controller.signIn('a', 'b');
  expect(controller.state, isA<LoginStateSuccess>()); // ← outcome verified
});
```

## Cite as authority

- `.claude/skills/dart-generate-test-mocks/SKILL.md` (mockito reference)
- `apps/mobile/CLAUDE.md` §Testing (prefer fake_cloud_firestore over mocks)
- `apps/mobile/CLAUDE.md` §Test quality anti-pattern
