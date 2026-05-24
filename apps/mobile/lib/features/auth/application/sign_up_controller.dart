import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/auth/application/sign_up_state.dart';

part 'sign_up_controller.g.dart';

@riverpod
class SignUpController extends _$SignUpController {
  @override
  SignUpState build() => const SignUpState(
        step: SignUpStep.email,
        email: '',
        password: '',
        firstName: '',
        lastName: '',
        username: '',
        isCheckingUsername: false,
        isUsernameAvailable: false,
        isLoading: false,
      );

  // TODO(A/T5/KhoaLND): implement SignUpController — see docs/plans/2026-05-04-auth.md
}
