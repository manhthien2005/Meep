import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_state.freezed.dart';

@freezed
class LoginState with _$LoginState {
  const factory LoginState({
    required String email,
    required String password,
    required bool isLoading,
    @Default(false) bool isSuccess,
    @Default(false) bool needsProfile,
    String? errorMessage,
  }) = _LoginState;
}
