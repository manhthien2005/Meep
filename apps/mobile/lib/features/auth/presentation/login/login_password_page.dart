import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_radii.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/auth/application/login_controller.dart';
import 'package:meep/features/auth/application/password_reset_controller.dart';
import 'package:meep/features/auth/presentation/widgets/forgot_password_dialog.dart';
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
  Timer? _cooldownTimer;
  bool _emailSent = false;
  int _cooldownSeconds = 0;
  // Local — không watch từ controller để tránh markNeedsBuild trên defunct element
  // khi router redirect dispose page trước khi signIn() future trả về.
  bool _isSignInSuccess = false;

  @override
  void initState() {
    super.initState();
    // Clear stale result từ ResetPasswordPage (dùng chung loginControllerProvider)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(loginControllerProvider.notifier).resetResult();
    });
  }

  @override
  void dispose() {
    _pwCtrl.dispose();
    _successTimer?.cancel();
    _cooldownTimer?.cancel();
    // KHÔNG đụng `ref` trong dispose — router redirect có thể tear down element
    // trước khi dispose chạy → "Cannot use ref after the widget was disposed".
    // State cleanup được handle bởi: (1) clear-on-keystroke trong AppTextInput
    // và (2) resetResult() trong initState lần re-enter page.
    super.dispose();
  }

  bool get _canContinue => _pwCtrl.text.isNotEmpty;

  Future<void> _onContinue() async {
    ref.read(loginControllerProvider.notifier).setPassword(_pwCtrl.text);
    await ref.read(loginControllerProvider.notifier).signIn();
    if (!mounted) return;
    if (ref.read(loginControllerProvider).isSuccess) {
      setState(() => _isSignInSuccess = true);
      // Router sẽ tự redirect khi profile stream resolve. Timer là backup.
      _successTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) context.go('/home');
      });
    }
  }

  Future<void> _onForgotPassword() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x73000000),
      builder: (_) => const ForgotPasswordDialog(),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(passwordResetControllerProvider.notifier)
        .sendResetEmail(email: widget.email);
    if (!mounted) return;
    _startCooldown();
    setState(() => _emailSent = true);
  }

  Future<void> _onResend() async {
    await ref
        .read(passwordResetControllerProvider.notifier)
        .sendResetEmail(email: widget.email);
    if (!mounted) return;
    _startCooldown();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _cooldownSeconds--);
      if (_cooldownSeconds <= 0) t.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Chỉ watch isLoading + errorMessage — không watch isSuccess (local state)
    final state = ref.watch(
      loginControllerProvider.select(
        (s) => (isLoading: s.isLoading, errorMessage: s.errorMessage),
      ),
    );
    final isSuccess = _isSignInSuccess;

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
                    const SizedBox(height: 20),
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
                      onChanged: (_) {
                        if (ref.read(loginControllerProvider).errorMessage !=
                            null) {
                          ref
                              .read(loginControllerProvider.notifier)
                              .clearError();
                        }
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.center,
                      child: _emailSent
                          ? const _EmailSentPill()
                          : _ForgotPasswordButton(
                              onTap: _cooldownSeconds > 0
                                  ? null
                                  : _onForgotPassword,
                            ),
                    ),
                    if (_emailSent) ...[
                      const SizedBox(height: 12),
                      _ResendText(
                        cooldownSeconds: _cooldownSeconds,
                        onResend: _cooldownSeconds > 0 ? null : _onResend,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(27, 0, 27, 33),
              child: isSuccess
                  ? const _LoginSuccessButton()
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

// ── "Bạn đã quên mật khẩu?" pill (clickable) ─────────────────────────────────

class _ForgotPasswordButton extends StatelessWidget {
  const _ForgotPasswordButton({required this.onTap});

  final VoidCallback? onTap;

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

// ── "Email đặt lại mật khẩu đã được gửi đi!" pill (static) ──────────────────

class _EmailSentPill extends StatelessWidget {
  const _EmailSentPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.bw700,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        'Email đặt lại mật khẩu đã được gửi đi!',
        style: AppTextStyles.smSemiBold.copyWith(color: AppColors.bw100),
      ),
    );
  }
}

// ── "Bạn chưa nhận được email? Gửi lại" resend text ─────────────────────────

class _ResendText extends StatelessWidget {
  const _ResendText({required this.cooldownSeconds, this.onResend});

  final int cooldownSeconds;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final canResend = onResend != null;
    return GestureDetector(
      onTap: onResend,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Bạn chưa nhận được email? ',
              style: AppTextStyles.smSemiBold.copyWith(color: AppColors.bw500),
            ),
            TextSpan(
              text: canResend ? 'Gửi lại' : 'Gửi lại sau ${cooldownSeconds}s.',
              style: AppTextStyles.smSemiBold.copyWith(
                color: canResend ? AppColors.bw100 : AppColors.bw500,
                decoration: canResend ? TextDecoration.underline : null,
                decorationColor: AppColors.bw100,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── "Bạn đã sẵn sàng" login success button ───────────────────────────────────

class _LoginSuccessButton extends StatelessWidget {
  const _LoginSuccessButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.turquoise300,
        borderRadius: BorderRadius.circular(AppRadii.pill),
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
          SvgPicture.asset(
            'assets/icons/ic_circle_check_big.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              AppColors.turquoise800,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}
