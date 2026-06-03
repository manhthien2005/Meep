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
    test('user huỷ Google Sign-In → OperationCancelledError (silent)',
        () async {
      final mockGoogle = MockGoogleSignIn();
      when(() => mockGoogle.signIn()).thenAnswer((_) async => null);
      final repoWithGoogle = FirebaseAuthRepository(
        auth: mockAuth,
        googleSignIn: mockGoogle,
      );
      await expectLater(
        repoWithGoogle.signInWithGoogle(),
        throwsA(isA<OperationCancelledError>()),
      );
    });
  });

  group('verifyPasswordResetCode', () {
    test('hoàn thành khi oobCode hợp lệ', () async {
      // MockFirebaseAuth có real impl — verify không throw
      await expectLater(
        repo.verifyPasswordResetCode(oobCode: 'valid-code-123'),
        completes,
      );
    });

    test('ném AppError khi oobCode hết hạn', () async {
      whenCalling(Invocation.method(#verifyPasswordResetCode, null))
          .on(mockAuth)
          .thenThrow(FirebaseAuthException(code: 'expired-action-code'));
      await expectLater(
        repo.verifyPasswordResetCode(oobCode: 'expired-code'),
        throwsA(isA<AppError>()),
      );
    });
  });

  group('confirmPasswordReset', () {
    test('hoàn thành với oobCode và mật khẩu hợp lệ', () async {
      // MockFirebaseAuth có real impl — verify không throw
      await expectLater(
        repo.confirmPasswordReset(
          oobCode: 'valid-code',
          newPassword: 'newPassword123',
        ),
        completes,
      );
    });

    test('ném AppError khi oobCode không hợp lệ', () async {
      whenCalling(Invocation.method(#confirmPasswordReset, null))
          .on(mockAuth)
          .thenThrow(FirebaseAuthException(code: 'invalid-action-code'));
      await expectLater(
        repo.confirmPasswordReset(
          oobCode: 'bad-code',
          newPassword: 'newPassword123',
        ),
        throwsA(isA<AppError>()),
      );
    });
  });

  group('revalidateSession', () {
    test('no user → no-op', () async {
      await expectLater(repo.revalidateSession(), completes);
      expect(repo.currentUid, isNull);
    });

    test('reload thành công → giữ session', () async {
      final authWithUser = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-1'),
        signedIn: true,
      );
      final repoWithUser = FirebaseAuthRepository(auth: authWithUser);
      await repoWithUser.revalidateSession();
      expect(repoWithUser.currentUid, 'uid-1');
    });

    test('reload throws user-not-found → signOut', () async {
      final mockUser = MockUser(uid: 'uid-deleted');
      final authWithUser = MockFirebaseAuth(
        mockUser: mockUser,
        signedIn: true,
      );
      whenCalling(Invocation.method(#reload, null))
          .on(mockUser)
          .thenThrow(FirebaseAuthException(code: 'user-not-found'));
      final repoWithUser = FirebaseAuthRepository(auth: authWithUser);
      await repoWithUser.revalidateSession();
      expect(repoWithUser.currentUid, isNull);
    });

    test('reload throws user-disabled → signOut', () async {
      final mockUser = MockUser(uid: 'uid-disabled');
      final authWithUser = MockFirebaseAuth(
        mockUser: mockUser,
        signedIn: true,
      );
      whenCalling(Invocation.method(#reload, null))
          .on(mockUser)
          .thenThrow(FirebaseAuthException(code: 'user-disabled'));
      final repoWithUser = FirebaseAuthRepository(auth: authWithUser);
      await repoWithUser.revalidateSession();
      expect(repoWithUser.currentUid, isNull);
    });

    test('reload throws user-token-expired → signOut', () async {
      final mockUser = MockUser(uid: 'uid-expired');
      final authWithUser = MockFirebaseAuth(
        mockUser: mockUser,
        signedIn: true,
      );
      whenCalling(Invocation.method(#reload, null))
          .on(mockUser)
          .thenThrow(FirebaseAuthException(code: 'user-token-expired'));
      final repoWithUser = FirebaseAuthRepository(auth: authWithUser);
      await repoWithUser.revalidateSession();
      expect(repoWithUser.currentUid, isNull);
    });

    test('reload throws network-request-failed → giữ session', () async {
      final mockUser = MockUser(uid: 'uid-offline');
      final authWithUser = MockFirebaseAuth(
        mockUser: mockUser,
        signedIn: true,
      );
      whenCalling(Invocation.method(#reload, null))
          .on(mockUser)
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
      final repoWithUser = FirebaseAuthRepository(auth: authWithUser);
      await repoWithUser.revalidateSession();
      expect(repoWithUser.currentUid, 'uid-offline');
    });
  });

  group('deleteCurrentUser', () {
    test('no-op khi chưa sign in', () async {
      await expectLater(repo.deleteCurrentUser(), completes);
    });

    test('xoá user khi đã sign in', () async {
      final authWithUser = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-to-delete'),
        signedIn: true,
      );
      final repoWithUser = FirebaseAuthRepository(auth: authWithUser);
      await expectLater(repoWithUser.deleteCurrentUser(), completes);
    });

    test('ném AppError khi Firebase từ chối xoá', () async {
      final mockUser = MockUser(uid: 'uid-1');
      final authWithUser = MockFirebaseAuth(
        mockUser: mockUser,
        signedIn: true,
      );
      whenCalling(Invocation.method(#delete, null))
          .on(mockUser)
          .thenThrow(FirebaseAuthException(code: 'requires-recent-login'));
      final repoWithUser = FirebaseAuthRepository(auth: authWithUser);
      await expectLater(
        repoWithUser.deleteCurrentUser(),
        throwsA(isA<AppError>()),
      );
    });
  });

  group('updateEmail', () {
    // mock_exceptions registers exceptions trong global map keyed by object;
    // dùng uid unique mỗi test để tránh collision giữa MockUser instances.
    FirebaseAuthRepository repoSignedIn(String uid, {MockUser? user}) {
      final mockUser = user ?? MockUser(uid: uid, email: 'old@example.com');
      final auth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      return FirebaseAuthRepository(auth: auth);
    }

    test('UnauthenticatedError khi chưa đăng nhập', () async {
      await expectLater(
        repo.updateEmail('new@example.com'),
        throwsA(isA<UnauthenticatedError>()),
      );
    });

    test('completes khi user signed in và Firebase trả OK', () async {
      await expectLater(
        repoSignedIn('uid-ok').updateEmail('new@example.com'),
        completes,
      );
    });

    test('UnauthenticatedError code "requires-recent-login" khi session cũ',
        () async {
      final user = MockUser(uid: 'uid-stale', email: 'old@example.com');
      whenCalling(Invocation.method(#verifyBeforeUpdateEmail, null))
          .on(user)
          .thenThrow(FirebaseAuthException(code: 'requires-recent-login'));
      Object? caught;
      try {
        await repoSignedIn('uid-stale', user: user)
            .updateEmail('new@example.com');
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<UnauthenticatedError>());
      expect((caught! as UnauthenticatedError).code, 'requires-recent-login');
    });

    test('ValidationError khi email đã được dùng', () async {
      final user = MockUser(uid: 'uid-taken', email: 'old@example.com');
      whenCalling(Invocation.method(#verifyBeforeUpdateEmail, null))
          .on(user)
          .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
      await expectLater(
        repoSignedIn('uid-taken', user: user).updateEmail('taken@example.com'),
        throwsA(isA<ValidationError>()),
      );
    });

    test('ValidationError khi email không hợp lệ', () async {
      final user = MockUser(uid: 'uid-invalid', email: 'old@example.com');
      whenCalling(Invocation.method(#verifyBeforeUpdateEmail, null))
          .on(user)
          .thenThrow(FirebaseAuthException(code: 'invalid-email'));
      await expectLater(
        repoSignedIn('uid-invalid', user: user).updateEmail('not-an-email'),
        throwsA(isA<ValidationError>()),
      );
    });

    test('NetworkError khi mất mạng', () async {
      final user = MockUser(uid: 'uid-net', email: 'old@example.com');
      whenCalling(Invocation.method(#verifyBeforeUpdateEmail, null))
          .on(user)
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
      await expectLater(
        repoSignedIn('uid-net', user: user).updateEmail('new@example.com'),
        throwsA(isA<NetworkError>()),
      );
    });
  });
}
