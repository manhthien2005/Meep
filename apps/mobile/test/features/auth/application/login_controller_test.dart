import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/application/login_controller.dart';
import 'package:meep/features/auth/data/firebase_auth_repository.dart';
import 'package:meep/features/auth/data/firebase_user_repository.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:mocktail/mocktail.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

/// Fake that always signs in successfully.
MockGoogleSignIn makeMockGoogleSignIn({
  String accessToken = 'fake-access-token',
  String? idToken = 'fake-id-token',
}) {
  final mock = MockGoogleSignIn();
  final account = MockGoogleSignInAccount();
  final auth = MockGoogleSignInAuthentication();

  when(() => mock.signIn()).thenAnswer((_) async => account);
  when(() => account.authentication).thenAnswer((_) async => auth);
  when(() => auth.accessToken).thenReturn(accessToken);
  when(() => auth.idToken).thenReturn(idToken);
  return mock;
}

// ── Container factory ──────────────────────────────────────────────────────

ProviderContainer makeContainer({
  MockFirebaseAuth? auth,
  GoogleSignIn? googleSignIn,
  FakeFirebaseFirestore? firestore,
}) {
  final mockAuth = auth ?? MockFirebaseAuth();
  final fakeFirestore = firestore ?? FakeFirebaseFirestore();
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FirebaseAuthRepository(
          auth: mockAuth,
          googleSignIn: googleSignIn,
        ),
      ),
      userRepositoryProvider.overrideWithValue(
        FirebaseUserRepository(firestore: fakeFirestore),
      ),
    ],
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('LoginController — initial state', () {
    test('email/password trống, isLoading=false', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final state = container.read(loginControllerProvider);
      expect(state.email, '');
      expect(state.password, '');
      expect(state.isLoading, false);
      expect(state.isSuccess, false);
    });
  });

  group('LoginController — setEmail/setPassword', () {
    test('setEmail cập nhật state', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(loginControllerProvider.notifier).setEmail('a@b.com');
      expect(container.read(loginControllerProvider).email, 'a@b.com');
    });

    test('setPassword cập nhật state', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(loginControllerProvider.notifier).setPassword('pass1234');
      expect(container.read(loginControllerProvider).password, 'pass1234');
    });
  });

  group('LoginController — signIn', () {
    test('signIn thành công → isSuccess=true', () async {
      final mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-alice', email: 'alice@example.com'),
      );
      final container = makeContainer(auth: mockAuth);
      addTearDown(container.dispose);
      final ctrl = container.read(loginControllerProvider.notifier);
      ctrl.setEmail('alice@example.com');
      ctrl.setPassword('pass1234');
      await ctrl.signIn();
      expect(container.read(loginControllerProvider).isSuccess, true);
      expect(container.read(loginControllerProvider).errorMessage, isNull);
    });

    test('signIn sai mật khẩu → isSuccess=false + errorMessage', () async {
      final mockAuth = MockFirebaseAuth();
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(mockAuth)
          .thenThrow(FirebaseAuthException(code: 'wrong-password'));
      final container = makeContainer(auth: mockAuth);
      addTearDown(container.dispose);
      final ctrl = container.read(loginControllerProvider.notifier);
      ctrl.setEmail('a@b.com');
      ctrl.setPassword('wrong');
      await ctrl.signIn();
      final state = container.read(loginControllerProvider);
      expect(state.isSuccess, false);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNotNull);
    });

    test('signIn email không tồn tại → errorMessage tiếng Việt', () async {
      final mockAuth = MockFirebaseAuth();
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(mockAuth)
          .thenThrow(FirebaseAuthException(code: 'user-not-found'));
      final container = makeContainer(auth: mockAuth);
      addTearDown(container.dispose);
      final ctrl = container.read(loginControllerProvider.notifier);
      ctrl.setEmail('ghost@example.com');
      ctrl.setPassword('pass');
      await ctrl.signIn();
      expect(
        container.read(loginControllerProvider).errorMessage,
        contains('tài khoản'),
      );
    });
  });

  group('LoginController — continueWithGoogle', () {
    test('user mới (chưa có profile) → needsProfile=true', () async {
      final mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-new', email: 'new@gmail.com'),
      );
      final container = makeContainer(
        auth: mockAuth,
        googleSignIn: makeMockGoogleSignIn(),
      );
      addTearDown(container.dispose);
      await container
          .read(loginControllerProvider.notifier)
          .continueWithGoogle();
      final state = container.read(loginControllerProvider);
      expect(state.needsProfile, true);
      expect(state.isSuccess, false);
    });

    test('user cũ (có profile) → isSuccess=true', () async {
      final mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-existing', email: 'existing@gmail.com'),
        signedIn: true,
      );
      final fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore.doc('users/uid-existing').set(
            UserProfile(
              uid: 'uid-existing',
              email: 'existing@gmail.com',
              displayName: 'Existing',
              username: 'existing',
              createdAt: DateTime(2026, 1, 1),
              updatedAt: DateTime(2026, 1, 1),
            ).toJson(),
          );
      final container = makeContainer(
        auth: mockAuth,
        googleSignIn: makeMockGoogleSignIn(),
        firestore: fakeFirestore,
      );
      addTearDown(container.dispose);
      await container
          .read(loginControllerProvider.notifier)
          .continueWithGoogle();
      expect(container.read(loginControllerProvider).isSuccess, true);
    });
  });
}
