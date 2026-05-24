import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/auth/application/auth_controller.dart';
import 'package:meep/features/auth/application/sign_up_state.dart';
import 'package:meep/features/auth/data/user_profile.dart';

part 'sign_up_controller.g.dart';

@riverpod
class SignUpController extends _$SignUpController {
  Timer? _usernameDebounce;

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

  void setPassword(String password) {
    state = state.copyWith(
      password: password,
      step: SignUpStep.name,
      errorMessage: null,
    );
  }

  void setDisplayName(String displayName) {
    final name = displayName.trim();
    if (name.length < 2) {
      state = state.copyWith(
        errorMessage: 'Tên phải có ít nhất 2 ký tự',
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
    _usernameDebounce?.cancel();
    final lower = username.toLowerCase();
    state = state.copyWith(
      username: lower,
      isCheckingUsername: true,
      isUsernameAvailable: false,
    );
    try {
      final repo = ref.read(userRepositoryProvider);
      final available = await repo.isUsernameAvailable(lower);
      state = state.copyWith(
        isCheckingUsername: false,
        isUsernameAvailable: available,
      );
    } catch (_) {
      state = state.copyWith(isCheckingUsername: false);
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
      await userRepo.createProfile(
        UserProfile(
          uid: uid,
          email: state.email,
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
        errorMessage: e.toString(),
      );
    }
  }
}
