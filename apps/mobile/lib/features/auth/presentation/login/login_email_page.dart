import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/core/validators/auth_validators.dart';
import 'package:meep/features/auth/application/login_controller.dart';
import 'package:meep/shared/widgets/app_back_button.dart';
import 'package:meep/shared/widgets/app_google_button.dart';
import 'package:meep/shared/widgets/app_primary_button.dart';
import 'package:meep/shared/widgets/app_text_input.dart';
import 'package:meep/shared/widgets/or_divider.dart';

class LoginEmailPage extends ConsumerStatefulWidget {
  const LoginEmailPage({super.key});

  @override
  ConsumerState<LoginEmailPage> createState() => _LoginEmailPageState();
}

class _LoginEmailPageState extends ConsumerState<LoginEmailPage> {
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  bool get _canContinue => AuthValidators.isEmailValid(_emailCtrl.text);

  void _onContinue() {
    ref.read(loginControllerProvider.notifier).setEmail(_emailCtrl.text);
    context.push('/login/password', extra: _emailCtrl.text.trim());
  }

  Future<void> _onGoogle() async {
    await ref.read(loginControllerProvider.notifier).continueWithGoogle();
    if (!mounted) return;
    final state = ref.read(loginControllerProvider);
    if (state.isSuccess) {
      context.go('/home');
    }
    // needsProfile → router tự redirect đến /signup/name
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);

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
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    const OrDivider(),
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
