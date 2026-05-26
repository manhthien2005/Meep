import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/application/password_reset_controller.dart';
import 'package:meep/features/auth/data/firebase_auth_repository.dart';
import 'package:meep/features/auth/data/firebase_user_repository.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

ProviderContainer makeContainer({MockFirebaseAuth? auth}) {
  final mockAuth = auth ?? MockFirebaseAuth();
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FirebaseAuthRepository(auth: mockAuth),
      ),
      userRepositoryProvider.overrideWithValue(
        FirebaseUserRepository(firestore: FakeFirebaseFirestore()),
      ),
    ],
  );
}

void main() {
  group('PasswordResetController — initial state', () {
    test('isLoading=false, errorMessage=null', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final state = container.read(passwordResetControllerProvider);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
    });
  });

  group('PasswordResetController — resetState / clearError', () {
    test('resetState trả về trạng thái sạch', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(passwordResetControllerProvider.notifier).resetState();
      final state = container.read(passwordResetControllerProvider);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
    });
  });

  group('PasswordResetController — sendResetEmail', () {
    test('gửi email thành công — isLoading=false sau khi xong', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container
          .read(passwordResetControllerProvider.notifier)
          .sendResetEmail(email: 'anyone@example.com');
      final state = container.read(passwordResetControllerProvider);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
    });

    test('lỗi mạng → errorMessage không null', () async {
      final mockAuth = MockFirebaseAuth();
      whenCalling(Invocation.method(#sendPasswordResetEmail, null))
          .on(mockAuth)
          .thenThrow(
            FirebaseAuthException(code: 'network-request-failed'),
          );
      final container = makeContainer(auth: mockAuth);
      addTearDown(container.dispose);
      await container
          .read(passwordResetControllerProvider.notifier)
          .sendResetEmail(email: 'user@example.com');
      expect(
        container.read(passwordResetControllerProvider).errorMessage,
        isNotNull,
      );
    });
  });

  group('PasswordResetController — confirmReset', () {
    test('hoàn thành khi mock trả về hợp lệ', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await expectLater(
        container.read(passwordResetControllerProvider.notifier).confirmReset(
              oobCode: 'valid-code',
              newPassword: 'newPassword123',
            ),
        completes,
      );
      expect(
        container.read(passwordResetControllerProvider).isLoading,
        false,
      );
    });

    test('oobCode không hợp lệ → errorMessage không null', () async {
      final mockAuth = MockFirebaseAuth();
      whenCalling(Invocation.method(#verifyPasswordResetCode, null))
          .on(mockAuth)
          .thenThrow(FirebaseAuthException(code: 'invalid-action-code'));
      final container = makeContainer(auth: mockAuth);
      addTearDown(container.dispose);
      await container
          .read(passwordResetControllerProvider.notifier)
          .confirmReset(oobCode: 'bad-code', newPassword: 'newPw123');
      expect(
        container.read(passwordResetControllerProvider).errorMessage,
        isNotNull,
      );
    });
  });
}
