import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/auth/application/login_controller.dart';
import 'package:meep/shared/widgets/app_back_button.dart';
import 'package:meep/shared/widgets/app_primary_button.dart';
import 'package:meep/shared/widgets/app_text_input.dart';

class LoginPasswordPage extends ConsumerStatefulWidget {
  const LoginPasswordPage({super.key, required this.email});

  final String email;

  @override
  ConsumerState<LoginPasswordPage> createState() => _LoginPasswordPageState();
}

class _LoginPasswordPageState extends ConsumerState<LoginPasswordPage> {
  final _pwCtrl = TextEditingController();
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();
    ref.read(loginControllerProvider.notifier).setEmail(widget.email);
  }

  @override
  void dispose() {
    _pwCtrl.dispose();
    _successTimer?.cancel();
    super.dispose();
  }

  bool get _canContinue => _pwCtrl.text.isNotEmpty;

  Future<void> _onContinue() async {
    ref.read(loginControllerProvider.notifier).setPassword(_pwCtrl.text);
    await ref.read(loginControllerProvider.notifier).signIn();
    if (!mounted) return;
    if (ref.read(loginControllerProvider).isSuccess) {
      _successTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) context.go('/home');
      });
    }
  }

  Future<void> _onForgotPassword() async {
    await ref.read(loginControllerProvider.notifier).sendPasswordReset();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã gửi email đặt lại mật khẩu',
          style: AppTextStyles.smSemiBold.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.bw700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final isSuccess = state.isSuccess;

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
                      'Điền mật khẩu của bạn',
                      style:
                          AppTextStyles.xlBold.copyWith(color: AppColors.bw100),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    AppTextInput(
                      inputType: AppTextInputType.password,
                      controller: _pwCtrl,
                      hint: 'Mật khẩu',
                      errorText: isSuccess ? null : state.errorMessage,
                      status: isSuccess
                          ? AppTextInputStatus.success
                          : (state.errorMessage != null
                              ? AppTextInputStatus.error
                              : AppTextInputStatus.normal),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.center,
                      child: _ForgotPasswordButton(onTap: _onForgotPassword),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(27, 0, 27, 33),
              child: isSuccess
                  ? _SuccessButton()
                  : AppPrimaryButton(
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

class _ForgotPasswordButton extends StatelessWidget {
  const _ForgotPasswordButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Quên mật khẩu',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.bw700,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Text(
            'Bạn đã quên mật khẩu?',
            style: AppTextStyles.smSemiBold.copyWith(color: AppColors.bw100),
          ),
        ),
      ),
    );
  }
}

class _SuccessButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.turquoise300,
        borderRadius: BorderRadius.circular(30),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Bạn đã sẵn sàng',
            style: AppTextStyles.mdBold.copyWith(color: AppColors.turquoise800),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.check_circle_outline,
            size: 24,
            color: AppColors.turquoise800,
          ),
        ],
      ),
    );
  }
}
