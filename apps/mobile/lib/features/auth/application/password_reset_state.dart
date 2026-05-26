import 'package:freezed_annotation/freezed_annotation.dart';

part 'password_reset_state.freezed.dart';

@freezed
class PasswordResetState with _$PasswordResetState {
  const factory PasswordResetState({
    required bool isLoading,
    String? errorMessage,
  }) = _PasswordResetState;
}
