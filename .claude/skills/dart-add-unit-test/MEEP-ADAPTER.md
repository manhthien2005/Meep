# Meep Adapter — dart-add-unit-test

> Adapt official Dart unit test skill cho Meep repository/controller layer.

## Meep test priorities (apps/mobile/CLAUDE.md coverage targets)

| Layer | Target | Tool |
|---|---|---|
| Business logic (controllers, services) | ≥ 80% | flutter_test + mocktail |
| Data (repositories) | ≥ 70% | flutter_test + fake_cloud_firestore + firebase_auth_mocks |
| Functions (TS) | (not in this skill — use vitest) | — |

## Repository test pattern (Pattern #8 auth.md)

```dart
group('FirebaseAuthRepository', () {
  late MockFirebaseAuth fakeAuth;
  late FakeFirebaseFirestore fakeStore;
  late FirebaseAuthRepository repo;

  setUp(() {
    fakeAuth = MockFirebaseAuth();
    fakeStore = FakeFirebaseFirestore();
    repo = FirebaseAuthRepository(fakeAuth, fakeStore);
  });

  test('signInWithEmail success → returns void', () async {
    await expectLater(
      repo.signInWithEmail('a@b.com', 'pass'),
      completes,
    );
  });

  test('signInWithEmail wrong creds → throws UnauthenticatedError VN msg', () async {
    fakeAuth.mockUser = null;
    await expectLater(
      repo.signInWithEmail('a@b.com', 'wrong'),
      throwsA(isA<UnauthenticatedError>()
        .having((e) => e.message, 'message', contains('Mật khẩu'))),
    );
  });

  test('signInWithEmail network error → throws NetworkError', () async {
    // simulate FirebaseAuthException(code: 'network-request-failed')
    fakeAuth.throwExceptionOnSignIn = FirebaseAuthException(
      code: 'network-request-failed',
    );
    await expectLater(
      repo.signInWithEmail('a@b.com', 'pass'),
      throwsA(isA<NetworkError>()),
    );
  });
});
```

## Controller test pattern

```dart
group('LoginController', () {
  late ProviderContainer container;
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
    );
  });

  tearDown(() => container.dispose());

  test('signIn happy → state transitions loading → success', () async {
    when(() => mockRepo.signInWithEmail(any(), any())).thenAnswer((_) async {});

    final controller = container.read(loginControllerProvider.notifier);
    final future = controller.signIn('a@b.com', 'pass');

    expect(container.read(loginControllerProvider), isA<LoginStateLoading>());
    await future;
    expect(container.read(loginControllerProvider), isA<LoginStateSuccess>());
  });
});
```

## Mirror file convention (apps/mobile/CLAUDE.md)

`lib/features/feed/data/firebase_post_repository.dart`
↔ `test/features/feed/data/firebase_post_repository_test.dart`

## When test must run

- `flutter test --coverage` part of CI gate
- Pre-PR self-run command: `flutter test test/features/<module>/`

## Cite as authority

- `.claude/skills/dart-add-unit-test/SKILL.md`
- `CLAUDE.md` §Testing baseline
- `apps/mobile/CLAUDE.md` §Testing
- `.claude/reference-architectures/auth.md` Pattern #8
