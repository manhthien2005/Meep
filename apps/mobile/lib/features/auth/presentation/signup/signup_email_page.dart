import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/core/validators/auth_validators.dart';
import 'package:meep/features/auth/application/login_controller.dart';
import 'package:meep/features/auth/application/sign_up_controller.dart';
import 'package:meep/features/auth/application/sign_up_state.dart';
import 'package:meep/shared/widgets/app_back_button.dart';
import 'package:meep/shared/widgets/app_google_button.dart';
import 'package:meep/shared/widgets/app_primary_button.dart';
import 'package:meep/shared/widgets/app_text_input.dart';
import 'package:meep/shared/widgets/or_divider.dart';

class SignUpEmailPage extends ConsumerStatefulWidget {
  const SignUpEmailPage({super.key});

  @override
  ConsumerState<SignUpEmailPage> createState() => _SignUpEmailPageState();
}

class _SignUpEmailPageState extends ConsumerState<SignUpEmailPage> {
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Clear stale login error (từ login attempt trước) khi vào trang signup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(loginControllerProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  bool get _canContinue => AuthValidators.isEmailValid(_emailCtrl.text);

  Future<void> _onContinue() async {
    final ok = await ref
        .read(signUpControllerProvider.notifier)
        .checkEmailAvailable(_emailCtrl.text);
    if (!mounted || !ok) return;
    unawaited(context.push('/signup/password'));
  }

  Future<void> _onGoogle() async {
    await ref.read(loginControllerProvider.notifier).continueWithGoogle();
    if (!mounted) return;
    final loginState = ref.read(loginControllerProvider);
    if (loginState.isSuccess) {
      context.go('/home');
    }
    // needsProfile → router tự redirect đến /signup/name (không navigate thủ công)
    // error → hiện trong UI qua loginState.errorMessage
  }

  @override
  Widget build(BuildContext context) {
    final signUpState = ref.watch(signUpControllerProvider);
    final loginState = ref.watch(loginControllerProvider);
    final errorText =
        signUpState.step == SignUpStep.email ? signUpState.errorMessage : null;
    final googleError = loginState.errorMessage;
    final isBusy = signUpState.isLoading || loginState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.bw900,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(27, 49, 27, 0),
              child: AppBackButton(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 27),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Email của bạn là gì?',
                      style:
                          AppTextStyles.xlBold.copyWith(color: AppColors.bw100),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    AppTextInput(
                      inputType: AppTextInputType.email,
                      controller: _emailCtrl,
                      hint: 'Địa chỉ email',
                      errorText: errorText,
                      status: errorText != null
                          ? AppTextInputStatus.error
                          : AppTextInputStatus.normal,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    const OrDivider(),
                    const SizedBox(height: 24),
                    AppGoogleButton(
                      onPressed: isBusy ? null : () => unawaited(_onGoogle()),
                    ),
                    if (googleError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        googleError,
                        style: AppTextStyles.smSemiBold
                            .copyWith(color: AppColors.error700),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(27, 0, 27, 33),
              child: AppPrimaryButton(
                label: 'Tiếp tục',
                isLoading: signUpState.isLoading,
                onPressed: _canContinue ? _onContinue : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
