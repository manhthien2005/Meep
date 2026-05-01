import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/features/auth/application/auth_controller.dart';
import 'package:meep/features/auth/data/auth_repository.dart';
import 'package:meep/features/auth/presentation/login_page.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({String? uid}) : _uid = uid;

  String? _uid;

  @override
  String? get currentUid => _uid;

  @override
  Stream<String?> watchUid() => Stream.value(_uid);

  @override
  Future<void> signInWithEmail({required String email, required String password}) async {
    _uid = 'test-uid';
  }

  @override
  Future<void> signInWithApple() async => _uid = 'test-uid';

  @override
  Future<void> signInWithGoogle() async => _uid = 'test-uid';

  @override
  Future<void> signOut() async => _uid = null;
}

void main() {
  group('LoginPage', () {
    testWidgets('shows the sign-in CTA when not signed in', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          ],
          child: const MaterialApp(home: LoginPage()),
        ),
      );

      expect(find.text('Welcome to Meep'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('hides the CTA when already signed in', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider
                .overrideWithValue(_FakeAuthRepository(uid: 'existing-uid')),
          ],
          child: const MaterialApp(home: LoginPage()),
        ),
      );

      // Allow the StreamProvider to emit.
      await tester.pump();

      expect(find.text('Sign in'), findsNothing);
      expect(find.text('Signed in — TODO: navigate to feed'), findsOneWidget);
    });
  });
}
