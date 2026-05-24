import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/auth/application/auth_controller.dart';
import 'package:meep/features/auth/application/login_controller.dart';
import 'package:meep/features/auth/application/sign_up_controller.dart';
import 'package:meep/features/auth/application/sign_up_state.dart';
import 'package:meep/shared/widgets/app_back_button.dart';
import 'package:meep/shared/widgets/app_google_button.dart';
import 'package:meep/shared/widgets/app_primary_button.dart';
import 'package:meep/shared/widgets/app_text_input.dart';

class SignUpEmailPage extends ConsumerStatefulWidget {
  const SignUpEmailPage({super.key});

  @override
  ConsumerState<SignUpEmailPage> createState() => _SignUpEmailPageState();
}

class _SignUpEmailPageState extends ConsumerState<SignUpEmailPage> {
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  bool get _canContinue => _emailCtrl.text.trim().contains('@');

  void _onContinue() {
    ref.read(signUpControllerProvider.notifier).setEmail(_emailCtrl.text);
    context.push('/signup/password');
  }

  Future<void> _onGoogle() async {
    await ref.read(loginControllerProvider.notifier).continueWithGoogle();
    if (!mounted) return;
    final loginState = ref.read(loginControllerProvider);
    if (loginState.isSuccess) {
      context.go('/home');
    } else if (loginState.needsProfile) {
      final googleEmail = ref.read(authRepositoryProvider).currentEmail ?? '';
      ref
          .read(signUpControllerProvider.notifier)
          .prefillFromGoogle(googleEmail);
      unawaited(context.push('/signup/name'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signUpControllerProvider);
    final errorText =
        state.step == SignUpStep.email ? state.errorMessage : null;

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
                    _Divider(),
                    const SizedBox(height: 24),
                    AppGoogleButton(
                      onPressed:
                          state.isLoading ? null : () => unawaited(_onGoogle()),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(27, 0, 27, 33),
              child: AppPrimaryButton(
                label: 'Tiếp tục',
                isLoading: state.isLoading,
                onPressed: _canContinue ? _onContinue : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.bw600, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'hoặc',
            style: AppTextStyles.smSemiBold.copyWith(color: AppColors.bw600),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.bw600, thickness: 1)),
      ],
    );
  }
}
