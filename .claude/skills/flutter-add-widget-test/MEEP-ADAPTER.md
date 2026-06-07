# Meep Adapter — flutter-add-widget-test

> Adapt official Flutter widget test skill cho Meep convention.

## Meep test stack (apps/mobile/CLAUDE.md §Testing)

- `flutter_test` (base)
- `fake_cloud_firestore` (prefer over MockFirestore — CLAUDE.md explicit)
- `firebase_auth_mocks`
- `mocktail` (prefer over mockito for Riverpod-friendly API)

## Riverpod widget test pattern

```dart
testWidgets('LoginPage shows error on wrong password', (tester) async {
  final fakeAuth = MockFirebaseAuth(); // firebase_auth_mocks

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FirebaseAuthRepository(fakeAuth, FakeFirebaseFirestore()),
        ),
      ],
      child: const MaterialApp(home: LoginPage()),
    ),
  );

  await tester.enterText(find.byKey(const Key('email')), 'wrong@a.com');
  await tester.enterText(find.byKey(const Key('password')), 'wrong');
  await tester.tap(find.byKey(const Key('submit')));
  await tester.pumpAndSettle();

  expect(find.text('Mật khẩu không đúng'), findsOneWidget); // Pattern #10 VN msg
});
```

## Meep widget test requirements

| Critical screen | Required cases |
|---|---|
| LoginPage | empty form / invalid email / wrong creds / network error / loading state / success |
| FeedPage | empty / loading / error / has-data with pagination / pull-to-refresh |
| CameraPage | permission granted / denied / caption length cap / upload success / upload fail retry |
| FriendListPage | empty / pending request / search empty / friend item tap |
| ProfilePage | own profile vs friend profile / edit mode / save success/fail |
| SettingsSheet | block confirm / delete account multi-step / sign-out |
| NotificationBanner | foreground tap → route / dismiss |

## Mirror convention (apps/mobile/CLAUDE.md)

`lib/features/feed/presentation/feed_page.dart` ↔ `test/features/feed/presentation/feed_page_test.dart`.

## Test what matters (CLAUDE.md anti-pattern)

❌ DON'T:
```dart
expect(find.byType(MyWidget), findsOneWidget); // tautology
verify(mock.someMethod()).called(1); // mock-only assertion
```

✅ DO:
```dart
expect(find.text('Mật khẩu không đúng'), findsOneWidget); // user sees this
expect(controller.state, isA<LoginStateError>()); // state transitioned
```

## Cite as authority

- `.claude/skills/flutter-add-widget-test/SKILL.md` (WidgetTester reference)
- `apps/mobile/CLAUDE.md` §Testing (Meep-specific)
- `.claude/reference-architectures/auth.md` Pattern #8 test stratification
