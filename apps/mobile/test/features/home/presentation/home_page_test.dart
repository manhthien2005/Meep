import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/home/presentation/home_page.dart';

UserProfile _profile({
  String uid = 'uid-alice',
  String email = 'alice@example.com',
  String displayName = 'Alice',
}) =>
    UserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      username: 'alice',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

Widget _harness({required Stream<UserProfile?> profileStream}) {
  return ProviderScope(
    overrides: [
      currentUserProfileProvider.overrideWith((ref) => profileStream),
    ],
    child: const MaterialApp(home: HomePage()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // H1 regression — HomePage previously read `FirebaseAuth.instance.currentUser`
  // directly (impossible to override in tests, vi phạm contract-first rule).
  // After the fix it reads via `currentUserProfileProvider`, which these tests
  // exercise by overriding with a stream of fake profiles.

  group('HomePage', () {
    testWidgets('shows TODO placeholder text', (tester) async {
      await tester.pumpWidget(
        _harness(profileStream: Stream.value(_profile())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home — TODO'), findsOneWidget);
    });

    testWidgets(
      'renders email from currentUserProfileProvider when profile loaded',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            profileStream: Stream.value(_profile(email: 'bob@example.com')),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('bob@example.com'), findsOneWidget);
      },
    );

    testWidgets('renders no email row when profile is null (signed-out)',
        (tester) async {
      await tester.pumpWidget(
        _harness(profileStream: Stream<UserProfile?>.value(null)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home — TODO'), findsOneWidget);
      // No email-looking text rendered.
      expect(find.textContaining('@'), findsNothing);
    });

    testWidgets('renders nothing for email row while profile is loading',
        (tester) async {
      // Empty stream → AsyncLoading. `maybeWhen.orElse` returns SizedBox.shrink
      // so we expect no email-looking text on screen.
      await tester.pumpWidget(
        _harness(profileStream: const Stream<UserProfile?>.empty()),
      );
      await tester.pump();

      expect(find.text('Home — TODO'), findsOneWidget);
      expect(find.textContaining('@'), findsNothing);
    });

    testWidgets('shows "Sign out (dev)" button in debug build', (tester) async {
      // kDebugMode is true under `flutter test` — assertion holds without
      // toggling a flag. In a release build the button is compile-stripped.
      await tester.pumpWidget(
        _harness(profileStream: Stream.value(_profile())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign out (dev)'), findsOneWidget);
    });
  });
}
