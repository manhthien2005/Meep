import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_up_state.freezed.dart';

enum SignUpStep { email, password, name, username }

@freezed
class SignUpState with _$SignUpState {
  const factory SignUpState({
    required SignUpStep step,
    required String email,
    required String password,
    required String displayName,
    required String username,
    required bool isGoogleSignIn,
    required bool isCheckingUsername,
    required bool isUsernameAvailable,
    required bool isLoading,
    String? errorMessage,
  }) = _SignUpState;
}
