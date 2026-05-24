import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/auth/application/login_state.dart';

part 'login_controller.g.dart';

@riverpod
class LoginController extends _$LoginController {
  @override
  LoginState build() =>
      const LoginState(email: '', password: '', isLoading: false);

  // TODO(A/T6/KhoaLND): implement LoginController — see docs/plans/2026-05-04-auth.md
}
