import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/application/password_reset_state.dart';

part 'password_reset_controller.g.dart';

@riverpod
class PasswordResetController extends _$PasswordResetController {
  @override
  PasswordResetState build() => const PasswordResetState(isLoading: false);

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void resetState() {
    state = const PasswordResetState(isLoading: false);
  }

  Future<void> sendResetEmail({required String email}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(
            email: email,
          );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = _afterFailure(e);
    }
  }

  Future<void> confirmReset({
    required String oobCode,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final auth = ref.read(authRepositoryProvider);
      final email = await auth.verifyPasswordResetCode(oobCode: oobCode);
      await auth.confirmPasswordReset(
        oobCode: oobCode,
        newPassword: newPassword,
      );
      // Auto-sign-in — đổi mật khẩu = đã xác thực email ownership
      await auth.signInWithEmail(email: email, password: newPassword);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = _afterFailure(e);
    }
  }

  PasswordResetState _afterFailure(Object e) {
    final err = AppError.fromUnknown(e);
    return state.copyWith(
      isLoading: false,
      errorMessage: err is OperationCancelledError ? null : err.message,
    );
  }
}
