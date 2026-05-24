import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/auth/application/auth_controller.dart';
import 'package:meep/features/auth/application/login_state.dart';
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
  /// - User mới (no /users/{uid}) → `needsProfile = true` → router pushes /signup/name
  /// - User cũ → `isSuccess = true` → router pushes /home
  Future<void> continueWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      final uid = ref.read(authRepositoryProvider).currentUid!;
      final profile = await ref.read(userRepositoryProvider).getProfile(uid);
      if (profile == null) {
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
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(email: state.email);
    } on AppError catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }
}
