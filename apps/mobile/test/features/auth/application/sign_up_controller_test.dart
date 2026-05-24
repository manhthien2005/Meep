import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/auth/application/auth_controller.dart';
import 'package:meep/features/auth/application/sign_up_controller.dart';
import 'package:meep/features/auth/application/sign_up_state.dart';
import 'package:meep/features/auth/data/firebase_auth_repository.dart';
import 'package:meep/features/auth/data/firebase_user_repository.dart';

ProviderContainer makeContainer({
  MockFirebaseAuth? auth,
  FakeFirebaseFirestore? firestore,
}) {
  final mockAuth = auth ?? MockFirebaseAuth();
  final fakeFirestore = firestore ?? FakeFirebaseFirestore();
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FirebaseAuthRepository(auth: mockAuth),
      ),
      userRepositoryProvider.overrideWithValue(
        FirebaseUserRepository(firestore: fakeFirestore),
      ),
    ],
  );
}

void main() {
  group('SignUpController — step navigation', () {
    test('initial state: step=email, tất cả trống', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final state = container.read(signUpControllerProvider);
      expect(state.step, SignUpStep.email);
      expect(state.email, '');
      expect(state.isLoading, false);
    });

    test('setEmail → advance to password step', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(signUpControllerProvider.notifier).setEmail('a@b.com');
      final state = container.read(signUpControllerProvider);
      expect(state.email, 'a@b.com');
      expect(state.step, SignUpStep.password);
    });

    test('setPassword → advance to name step', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final ctrl = container.read(signUpControllerProvider.notifier);
      ctrl.setEmail('a@b.com');
      ctrl.setPassword('pass1234');
      final state = container.read(signUpControllerProvider);
      expect(state.password, 'pass1234');
      expect(state.step, SignUpStep.name);
    });

    test('setDisplayName → advance to username step', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final ctrl = container.read(signUpControllerProvider.notifier);
      ctrl.setEmail('a@b.com');
      ctrl.setPassword('pass1234');
      ctrl.setDisplayName('Alice Nguyen');
      final state = container.read(signUpControllerProvider);
      expect(state.displayName, 'Alice Nguyen');
      expect(state.step, SignUpStep.username);
    });

    test('setDisplayName < 2 chars → errorMessage, step stays', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final ctrl = container.read(signUpControllerProvider.notifier);
      ctrl.setEmail('a@b.com');
      ctrl.setPassword('pass1234');
      ctrl.setDisplayName('A');
      final state = container.read(signUpControllerProvider);
      expect(state.step, SignUpStep.name);
      expect(state.errorMessage, isNotNull);
    });
  });

  group('SignUpController — checkUsername', () {
    test('username available → isUsernameAvailable=true', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container
          .read(signUpControllerProvider.notifier)
          .checkUsername('alice');
      final state = container.read(signUpControllerProvider);
      expect(state.isUsernameAvailable, true);
      expect(state.isCheckingUsername, false);
    });

    test('username taken → isUsernameAvailable=false', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore.doc('usernames/alice').set({'uid': 'someone-else'});
      final container = makeContainer(firestore: fakeFirestore);
      addTearDown(container.dispose);
      await container
          .read(signUpControllerProvider.notifier)
          .checkUsername('alice');
      expect(
        container.read(signUpControllerProvider).isUsernameAvailable,
        false,
      );
    });
  });

  group('SignUpController — createAccount (email flow)', () {
    test('createAccount thành công → isLoading=false, no error', () async {
      final container = makeContainer(
        auth: MockFirebaseAuth(mockUser: MockUser(uid: 'uid-new')),
      );
      addTearDown(container.dispose);
      final ctrl = container.read(signUpControllerProvider.notifier);
      ctrl.setEmail('new@example.com');
      ctrl.setPassword('pass1234');
      ctrl.setDisplayName('New User');
      container.read(signUpControllerProvider.notifier).state =
          container.read(signUpControllerProvider).copyWith(
                username: 'newuser',
                isUsernameAvailable: true,
              );
      await ctrl.createAccount();
      final state = container.read(signUpControllerProvider);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
    });

    test('createAccount với username chưa available → errorMessage', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      final ctrl = container.read(signUpControllerProvider.notifier);
      ctrl.setEmail('a@b.com');
      ctrl.setPassword('pass1234');
      ctrl.setDisplayName('Alice');
      // username NOT available
      await ctrl.createAccount();
      expect(
        container.read(signUpControllerProvider).errorMessage,
        isNotNull,
      );
    });
  });
}
