import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/core/validators/auth_validators.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/application/sign_up_state.dart';
import 'package:meep/features/auth/data/user_profile.dart';

part 'sign_up_controller.g.dart';

@riverpod
class SignUpController extends _$SignUpController {
  @override
  SignUpState build() => const SignUpState(
        step: SignUpStep.email,
        email: '',
        password: '',
        displayName: '',
        username: '',
        isGoogleSignIn: false,
        isCheckingUsername: false,
        isUsernameAvailable: false,
        isLoading: false,
      );

  void setEmail(String email) {
    state = state.copyWith(
      email: email.trim(),
      step: SignUpStep.password,
      errorMessage: null,
    );
  }

  /// Kiểm tra email chưa được đăng ký, rồi advance step → password.
  /// Trả về true nếu email available và step đã advance.
  Future<bool> checkEmailAvailable(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final available =
          await ref.read(authRepositoryProvider).isEmailAvailable(email.trim());
      if (!available) {
        state = state.copyWith(
          isLoading: false,
          step: SignUpStep.email,
          errorMessage: 'Email này đã được đăng ký. Thử đăng nhập?',
        );
        return false;
      }
      state = state.copyWith(
        email: email.trim(),
        step: SignUpStep.password,
        isLoading: false,
        errorMessage: null,
      );
      return true;
    } on AppError catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể kiểm tra email, thử lại',
      );
      return false;
    }
  }

  void setPassword(String password) {
    state = state.copyWith(
      password: password,
      step: SignUpStep.name,
      errorMessage: null,
    );
  }

  void setDisplayName(String displayName) {
    final name = displayName.trim();
    if (!AuthValidators.isDisplayNameValid(name)) {
      state = state.copyWith(
        errorMessage:
            'Tên phải có ít nhất ${AuthValidators.displayNameMinLength} ký tự',
      );
      return;
    }
    state = state.copyWith(
      displayName: name,
      step: SignUpStep.username,
      errorMessage: null,
    );
  }

  // Pre-fill displayName from Google (shown as editable on name step)
  void prefillFromGoogle(String displayName) {
    state = state.copyWith(
      displayName: displayName.trim(),
      isGoogleSignIn: true,
      step: SignUpStep.name,
      errorMessage: null,
    );
  }

  Future<void> checkUsername(String username) async {
    final lower = username.toLowerCase().trim();

    // Validate format trước khi gọi API — luôn set username để UI biết đã check
    if (!AuthValidators.isUsernameFormatValid(lower)) {
      state = state.copyWith(
        username: lower,
        isCheckingUsername: false,
        isUsernameAvailable: false,
        errorMessage: 'Tên người dùng không hợp lệ.',
      );
      return;
    }

    state = state.copyWith(
      username: lower,
      isCheckingUsername: true,
      isUsernameAvailable: false,
      errorMessage: null,
    );
    try {
      final repo = ref.read(userRepositoryProvider);
      final available = await repo.isUsernameAvailable(lower);
      state = state.copyWith(
        isCheckingUsername: false,
        isUsernameAvailable: available,
        errorMessage: available
            ? null
            : 'Tên người dùng này đã tồn tại. Vui lòng chọn tên khác.',
      );
    } catch (e) {
      state = state.copyWith(
        isCheckingUsername: false,
        isUsernameAvailable: false,
        errorMessage: 'Không thể kiểm tra tên người dùng, thử lại',
      );
    }
  }

  Future<void> createAccount() async {
    if (!state.isUsernameAvailable) {
      state = state.copyWith(
        errorMessage: 'Chọn username trước khi tạo tài khoản',
      );
      return;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      if (!state.isGoogleSignIn) {
        await authRepo.signUpWithEmail(
          email: state.email,
          password: state.password,
        );
      }

      final uid = authRepo.currentUid!;
      final email =
          state.isGoogleSignIn ? (authRepo.currentEmail ?? '') : state.email;
      await userRepo.createProfile(
        UserProfile(
          uid: uid,
          email: email,
          displayName: state.displayName,
          username: state.username,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // Rollback: remove Firebase Auth account if Firestore write failed
      if (!state.isGoogleSignIn) {
        try {
          await ref.read(authRepositoryProvider).deleteCurrentUser();
        } catch (_) {}
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is AppError ? e.message : 'Đã có lỗi xảy ra',
      );
    }
  }
}
