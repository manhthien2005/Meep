# /test — Test-Driven Development

> "Tests are proof, not afterthought."

Use when:
- Adding tests for existing code (legacy, prototype).
- Writing a regression test for a bug fix.
- Auditing coverage and adding tests for gaps.

> **For new features you're coding:** use `/build` (TDD cycle is included).

## Pre-flight

Identify scope: which file/function/feature needs tests?

```bash
flutter test --coverage   # check current coverage
```

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

## Pattern by case

### A. Tests for existing code (none yet)

1. Read the code — understand current behavior.
2. List behaviors to test: happy path, edge case, error path.
3. For each behavior:
   - Write test → run → confirm FAIL (if code has bug) or PASS (if correct).
   - **If PASSES immediately:** characterization test — locking in current behavior. OK, but doesn't prove correctness.
   - **If FAILS:** bug discovered → use `/debug`.

### B. Regression test for a bug fix

1. Write failing test that reproduces bug.
2. Verify FAIL.
3. Fix code → verify PASS.
4. **Revert fix → verify FAIL again** (proof the test actually catches the bug).
5. Restore fix → verify PASS.
6. Commit.

```bash
git commit -m "fix(<scope>): <mô tả> + regression test for #<issue>"
```

### C. Coverage audit

```bash
flutter test --coverage
```

Prioritize:
- 🔴 Critical: auth, security rules — must have tests.
- 🟡 Important: feature core (post, friend, feed).
- 🟢 Nice-to-have: utilities, formatters, theme.

## Test types for Meep

### Unit (Dart)

```dart
void main() {
  group('PostRepository', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late FirestorePostRepository repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u1'));
      repo = FirestorePostRepository(firestore: firestore, auth: auth);
    });

    test('createPost throws when caption empty', () async {
      expect(
        () => repo.createPost(caption: '', imageUrl: 'x.jpg'),
        throwsA(isA<ValidationError>()),
      );
    });
  });
}
```

### Widget (Flutter)

```dart
testWidgets('FeedPage shows loading then posts', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        postRepositoryProvider.overrideWithValue(FakePostRepository()),
      ],
      child: const MaterialApp(home: FeedPage()),
    ),
  );
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  await tester.pumpAndSettle();
  expect(find.byType(PostCard), findsNWidgets(3));
});
```

### Firestore rules

```bash
firebase emulators:exec --only firestore "npm run test:rules"
```

```ts
test('user cannot read non-friend post', async () => {
  const u1 = env.authenticatedContext('u1').firestore();
  await assertFails(u1.collection('posts').doc('post-of-u2').get());
});
```

## Naming rules

✅ Good: `'rejects post with empty caption'`, `'returns 401 when token expired'`

❌ Bad: `'test1'`, `'works'`, `'happy path'`, or has "and" (split into 2 tests).

## Coverage targets

| Layer | Target |
|---|---|
| Business logic (controllers, services, rules) | ≥ 80% |
| Data layer (repositories) | ≥ 70% |
| UI widgets | ≥ 50% |

## Verify before declaring done

```bash
flutter test && flutter analyze
# or
npm test && npm run lint
```

Read the output. 0 fail. 0 warn. Then claim "tests done".

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Mocks instead of real impl | Use `fake_cloud_firestore`, in-memory fakes |
| Testing internals (private methods) | Test inputs/outputs only — public API |
| Shared state across tests | `setUp` resets state |
| `Future.delayed(2s)` for async | `pumpAndSettle()`, `expectLater(future, completes)` |
| Test name with "and" | Split into 2 tests |
| `.skip()` failing tests | Fix or delete. No middle ground. |
