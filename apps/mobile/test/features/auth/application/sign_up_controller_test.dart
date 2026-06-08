import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/application/sign_up_controller.dart';
import 'package:meep/features/auth/application/sign_up_state.dart';
import 'package:meep/features/auth/data/auth_repository.dart';
import 'package:meep/features/auth/data/firebase_auth_repository.dart';
import 'package:meep/features/auth/data/firebase_user_repository.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/auth/data/user_repository.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

class _FakeUserProfile extends Fake implements UserProfile {}

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

  group('SignUpController — createAccount (Google flow)', () {
    test('isGoogleSignIn=true → KHÔNG gọi signUpWithEmail, chỉ createProfile',
        () async {
      // Mock Google user đã sign-in qua Firebase Auth (currentUser set)
      final mockAuth = MockFirebaseAuth(
        mockUser: MockUser(
          uid: 'uid-google-new',
          email: 'newuser@gmail.com',
          displayName: 'Google User',
        ),
        signedIn: true,
      );
      // Nếu createUserWithEmailAndPassword bị gọi → test fail
      whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
          .on(mockAuth)
          .thenThrow(
            Exception('signUpWithEmail không được gọi trong Google flow'),
          );
      final fakeFirestore = FakeFirebaseFirestore();
      final container = makeContainer(auth: mockAuth, firestore: fakeFirestore);
      addTearDown(container.dispose);

      // Simulate prefillFromGoogle + setDisplayName + checkUsername
      final ctrl = container.read(signUpControllerProvider.notifier);
      ctrl.prefillFromGoogle('Google User');
      ctrl.setDisplayName('Google User');
      await ctrl.checkUsername('googleuser');
      expect(
        container.read(signUpControllerProvider).isUsernameAvailable,
        true,
      );

      await ctrl.createAccount();
      final state = container.read(signUpControllerProvider);
      expect(state.errorMessage, isNull);
      expect(state.isLoading, false);

      // Verify Firestore profile created với email lấy từ Firebase Auth user
      final userDoc = await fakeFirestore.doc('users/uid-google-new').get();
      expect(userDoc.exists, isTrue);
      expect(userDoc.data()?['email'], 'newuser@gmail.com');
      expect(userDoc.data()?['displayName'], 'Google User');
    });

    test(
        'isGoogleSignIn=false + email/password trống (state corrupted) → fail rõ ràng, không leak Pigeon error',
        () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      final ctrl = container.read(signUpControllerProvider.notifier);
      // Bypass step machine: simulate state.isGoogleSignIn=false nhưng creds trống
      container.read(signUpControllerProvider.notifier).state =
          container.read(signUpControllerProvider).copyWith(
                username: 'someuser',
                isUsernameAvailable: true,
                isGoogleSignIn: false,
                // email và password vẫn ''
              );
      await ctrl.createAccount();
      final state = container.read(signUpControllerProvider);
      expect(state.errorMessage, contains('Thiếu thông tin'));
      expect(state.isLoading, false);
    });
  });

  group('SignUpController — checkEmailAvailable', () {
    test('email chưa đăng ký → trả true + step=password', () async {
      // MockFirebaseAuth.fetchSignInMethodsForEmail trả [] (chưa đăng ký)
      final container = makeContainer();
      addTearDown(container.dispose);
      final ok = await container
          .read(signUpControllerProvider.notifier)
          .checkEmailAvailable('new@example.com');
      expect(ok, true);
      expect(
        container.read(signUpControllerProvider).step,
        SignUpStep.password,
      );
      expect(container.read(signUpControllerProvider).email, 'new@example.com');
    });

    test('Firebase lỗi khi check → trả false + errorMessage', () async {
      final mockAuth = MockFirebaseAuth();
      whenCalling(Invocation.method(#fetchSignInMethodsForEmail, null))
          .on(mockAuth)
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
      final container = makeContainer(auth: mockAuth);
      addTearDown(container.dispose);
      final ok = await container
          .read(signUpControllerProvider.notifier)
          .checkEmailAvailable('test@example.com');
      expect(ok, false);
      expect(
        container.read(signUpControllerProvider).errorMessage,
        isNotNull,
      );
    });
  });

  group('SignUpController — email verification (AUTH-SEC-002)', () {
    late _MockAuthRepository authRepo;
    late _MockUserRepository userRepo;

    setUpAll(() => registerFallbackValue(_FakeUserProfile()));

    setUp(() {
      authRepo = _MockAuthRepository();
      userRepo = _MockUserRepository();
      when(() => authRepo.currentUid).thenReturn('uid-new');
      when(() => authRepo.currentEmail).thenReturn('new@example.com');
      when(
        () => authRepo.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});
      when(() => authRepo.signInWithGoogle()).thenAnswer((_) async {});
      when(() => authRepo.sendEmailVerification()).thenAnswer((_) async {});
      when(() => userRepo.createProfile(any())).thenAnswer((_) async {});
    });

    ProviderContainer mockContainer() {
      final c = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          userRepositoryProvider.overrideWithValue(userRepo),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('email signup → sendEmailVerification được gọi', () async {
      final c = mockContainer();
      final ctrl = c.read(signUpControllerProvider.notifier);
      ctrl.setEmail('new@example.com');
      ctrl.setPassword('pass1234');
      ctrl.setDisplayName('New User');
      ctrl.state = c.read(signUpControllerProvider).copyWith(
            username: 'newuser',
            isUsernameAvailable: true,
          );

      await ctrl.createAccount();

      expect(c.read(signUpControllerProvider).errorMessage, isNull);
      verify(() => authRepo.sendEmailVerification()).called(1);
    });

    test('Google signup → KHÔNG gọi sendEmailVerification', () async {
      final c = mockContainer();
      final ctrl = c.read(signUpControllerProvider.notifier);
      ctrl.prefillFromGoogle('Google User');
      ctrl.setDisplayName('Google User');
      ctrl.state = c.read(signUpControllerProvider).copyWith(
            username: 'googleuser',
            isUsernameAvailable: true,
          );

      await ctrl.createAccount();

      expect(c.read(signUpControllerProvider).errorMessage, isNull);
      verifyNever(() => authRepo.sendEmailVerification());
    });

    test('sendEmailVerification fail → KHÔNG rollback, account vẫn tạo',
        () async {
      when(() => authRepo.sendEmailVerification())
          .thenThrow(Exception('too-many-requests'));
      final c = mockContainer();
      final ctrl = c.read(signUpControllerProvider.notifier);
      ctrl.setEmail('new@example.com');
      ctrl.setPassword('pass1234');
      ctrl.setDisplayName('New User');
      ctrl.state = c.read(signUpControllerProvider).copyWith(
            username: 'newuser',
            isUsernameAvailable: true,
          );

      await ctrl.createAccount();

      // Profile created, no fatal error, no Auth-user rollback.
      verify(() => userRepo.createProfile(any())).called(1);
      expect(c.read(signUpControllerProvider).errorMessage, isNull);
      expect(c.read(signUpControllerProvider).isLoading, isFalse);
      verifyNever(() => authRepo.deleteCurrentUser());
    });
  });
}
