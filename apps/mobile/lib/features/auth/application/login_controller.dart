import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/auth/application/auth_controller.dart';
import 'package:meep/features/auth/application/login_state.dart';
import 'package:meep/features/auth/application/sign_up_controller.dart';
import 'package:meep/core/error/app_error.dart';

part 'login_controller.g.dart';

@riverpod
class LoginController extends _$LoginController {
  @override
  LoginState build() => const LoginState(
        email: '',
        password: '',
        isLoading: false,
      );

  void setEmail(String email) {
    state = state.copyWith(email: email.trim(), errorMessage: null);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Reset kết quả login/reset về trạng thái ban đầu — tránh state leak giữa pages.
  void resetResult() {
    state = state.copyWith(
      isSuccess: false,
      isLoading: false,
      errorMessage: null,
      needsProfile: false,
    );
  }

  void setPassword(String password) {
    state = state.copyWith(password: password, errorMessage: null);
  }

  Future<void> signIn() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(authRepositoryProvider).signInWithEmail(
            email: state.email,
            password: state.password,
          );
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on AppError catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state =
          state.copyWith(isLoading: false, errorMessage: 'Đã có lỗi xảy ra');
    }
  }

  /// Google Sign-In — same entry point for both login and signup screens.
  ///
  /// - User mới (no /users/{uid}) → prefill SignUpController + `needsProfile = true`
  ///   → router redirect tự chuyển về /signup/name (không navigate thủ công)
  /// - User cũ → `isSuccess = true` → UI navigate /home
  Future<void> continueWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      final uid = ref.read(authRepositoryProvider).currentUid!;
      final profile = await ref.read(userRepositoryProvider).getProfile(uid);
      if (profile == null) {
        // Pre-fill tên Google trước khi router redirect đến /signup/name
        final auth = ref.read(authRepositoryProvider);
        final displayName = auth.currentDisplayName ?? auth.currentEmail ?? '';
        ref
            .read(signUpControllerProvider.notifier)
            .prefillFromGoogle(displayName);
        state = state.copyWith(isLoading: false, needsProfile: true);
      } else {
        state = state.copyWith(isLoading: false, isSuccess: true);
      }
    } on AppError catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state =
          state.copyWith(isLoading: false, errorMessage: 'Đã có lỗi xảy ra');
    }
  }

  Future<void> sendPasswordReset() async {
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(
            email: state.email,
          );
    } on AppError catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }

  Future<void> confirmPasswordReset({
    required String oobCode,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final auth = ref.read(authRepositoryProvider);
      // Lấy email từ oobCode để auto-sign-in sau reset
      final email = await auth.verifyPasswordResetCode(oobCode: oobCode);
      await auth.confirmPasswordReset(
        oobCode: oobCode,
        newPassword: newPassword,
      );
      // Auto-sign-in — đổi mật khẩu = đã xác thực email ownership
      await auth.signInWithEmail(email: email, password: newPassword);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on AppError catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state =
          state.copyWith(isLoading: false, errorMessage: 'Đã có lỗi xảy ra');
    }
  }
}
