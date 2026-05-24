import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/auth/data/firebase_auth_repository.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:mocktail/mocktail.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

void main() {
  late MockFirebaseAuth mockAuth;
  late FirebaseAuthRepository repo;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    repo = FirebaseAuthRepository(auth: mockAuth);
  });

  group('watchUid', () {
    test('emits null khi chưa sign in', () async {
      final uid = await repo.watchUid().first;
      expect(uid, isNull);
    });

    test('emits uid sau khi sign in', () async {
      mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-alice', email: 'alice@example.com'),
        signedIn: true,
      );
      repo = FirebaseAuthRepository(auth: mockAuth);
      final uid = await repo.watchUid().first;
      expect(uid, 'uid-alice');
    });
  });

  group('currentUid', () {
    test('null khi chưa sign in', () {
      expect(repo.currentUid, isNull);
    });

    test('trả uid khi đã sign in', () {
      mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-bob'),
        signedIn: true,
      );
      repo = FirebaseAuthRepository(auth: mockAuth);
      expect(repo.currentUid, 'uid-bob');
    });
  });

  group('signUpWithEmail', () {
    test('thành công với email và password hợp lệ', () async {
      await expectLater(
        repo.signUpWithEmail(email: 'new@example.com', password: 'password123'),
        completes,
      );
    });

    test('ném ValidationError khi email đã tồn tại', () async {
      whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
          .on(mockAuth)
          .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
      await expectLater(
        repo.signUpWithEmail(email: 'taken@example.com', password: 'pass123'),
        throwsA(isA<ValidationError>()),
      );
    });

    test('ValidationError message tiếng Việt — email đã dùng', () async {
      whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
          .on(mockAuth)
          .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
      Object? caught;
      try {
        await repo.signUpWithEmail(
          email: 'taken@example.com',
          password: 'pass123',
        );
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<ValidationError>());
      expect((caught as ValidationError).message, contains('đã được sử dụng'));
    });

    test('ném ValidationError khi password yếu', () async {
      whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
          .on(mockAuth)
          .thenThrow(FirebaseAuthException(code: 'weak-password'));
      await expectLater(
        repo.signUpWithEmail(email: 'a@b.com', password: '123'),
        throwsA(isA<ValidationError>()),
      );
    });
  });

  group('signInWithEmail', () {
    test('thành công với creds đúng', () async {
      mockAuth = MockFirebaseAuth(mockUser: MockUser(uid: 'uid-1'));
      repo = FirebaseAuthRepository(auth: mockAuth);
      await expectLater(
        repo.signInWithEmail(email: 'alice@example.com', password: 'correct'),
        completes,
      );
    });

    test('ném UnauthenticatedError khi sai mật khẩu', () async {
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(mockAuth)
          .thenThrow(FirebaseAuthException(code: 'wrong-password'));
      await expectLater(
        repo.signInWithEmail(email: 'a@b.com', password: 'wrong'),
        throwsA(isA<UnauthenticatedError>()),
      );
    });

    test('UnauthenticatedError message tiếng Việt — sai mật khẩu', () async {
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(mockAuth)
          .thenThrow(FirebaseAuthException(code: 'wrong-password'));
      Object? caught;
      try {
        await repo.signInWithEmail(email: 'a@b.com', password: 'wrong');
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<UnauthenticatedError>());
      expect((caught as UnauthenticatedError).message, contains('Mật khẩu'));
    });

    test('ném UnauthenticatedError khi email không tồn tại', () async {
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(mockAuth)
          .thenThrow(FirebaseAuthException(code: 'user-not-found'));
      await expectLater(
        repo.signInWithEmail(email: 'ghost@example.com', password: 'pass'),
        throwsA(isA<UnauthenticatedError>()),
      );
    });
  });

  group('signOut', () {
    test('clear session sau khi sign out', () async {
      mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-1'),
        signedIn: true,
      );
      repo = FirebaseAuthRepository(auth: mockAuth);
      await repo.signOut();
      expect(repo.currentUid, isNull);
    });
  });

  group('sendPasswordResetEmail', () {
    test('hoàn thành (Firebase luôn success kể cả email không tồn tại)',
        () async {
      await expectLater(
        repo.sendPasswordResetEmail(email: 'anyone@example.com'),
        completes,
      );
    });
  });

  group('signInWithGoogle', () {
    test('user huỷ Google Sign-In → UnauthenticatedError', () async {
      final mockGoogle = MockGoogleSignIn();
      when(() => mockGoogle.signIn()).thenAnswer((_) async => null);
      final repoWithGoogle = FirebaseAuthRepository(
        auth: mockAuth,
        googleSignIn: mockGoogle,
      );
      await expectLater(
        repoWithGoogle.signInWithGoogle(),
        throwsA(isA<UnauthenticatedError>()),
      );
    });
  });
}
