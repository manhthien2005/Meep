# Meep Adapter — flutter-add-integration-test

> Adapt official skill cho golden path Meep.

## Status (per inventory)

- `apps/mobile/integration_test/` folder **MISSING** trên branch develop.
- CLAUDE.md require: "Integration test for login + post + feed loop minimum".
- Audit `06_testing_ci_release` flag as **P0/P1 gap**.

## Required golden path E2E (M3 release gate)

### Test 1: Auth flow
`integration_test/auth_flow_test.dart`
1. Open app → LandingPage
2. Tap "Đăng nhập" → LoginPage
3. Enter email + password → submit
4. Wait pumpAndSettle
5. Expect HomePage / FeedPage visible
6. Tap menu → sign-out
7. Expect back at LandingPage

### Test 2: Post creation flow
`integration_test/post_creation_test.dart`
1. Sign-in (helper)
2. Tap camera icon
3. Mock permission grant
4. Capture (mock camera → fake image)
5. Enter caption (≤ 30 chars per domain rule)
6. Tap share → friend list multiselect
7. Tap "Gửi"
8. Expect upload progress
9. Expect navigation back to feed
10. Expect new post visible in own feed

### Test 3: Feed + reaction flow
`integration_test/feed_reaction_test.dart`
1. Sign-in
2. Wait feed load (with fake posts seeded)
3. Tap reaction button on first post
4. Select emoji
5. Expect reaction count increment
6. Tap own reaction → remove
7. Expect decrement

### Test 4: Friend request flow
`integration_test/friend_request_test.dart`
1. Sign-in as user A
2. Open FriendListPage
3. Search "user_b"
4. Tap "Gửi lời mời"
5. Sign-out, sign-in as user B
6. Open NotificationBanner / FriendRequestsPage
7. Tap accept
8. Expect friendship visible cả 2 chiều

## Setup (Meep)

```dart
// integration_test/_helpers.dart
Future<void> signInTestUser(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('email')), 'test@meep.dev');
  await tester.enterText(find.byKey(const Key('password')), 'TestPass123');
  await tester.tap(find.byKey(const Key('submit')));
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Use Firebase emulator
  setUpAll(() async {
    await Firebase.initializeApp();
    FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  });
}
```

## CI integration

Add to `.github/workflows/pr-check.yml`:
```yaml
- name: Run integration tests
  run: |
    cd apps/mobile
    flutter drive --driver=test_driver/integration_test.dart \
                  --target=integration_test/auth_flow_test.dart
```

## Cite as authority

- `.claude/skills/flutter-add-integration-test/SKILL.md` (setup reference)
- `CLAUDE.md` §Testing baseline ("Integration test for login + post + feed loop minimum")
- `apps/mobile/CLAUDE.md` §Testing
