import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/application/email_verification_gate.dart';
import 'package:meep/shared/widgets/app_primary_button.dart';

/// Màn xác minh email (AUTH-SEC-002 hard gate). Email/password user chưa verify
/// bị router giữ ở đây. Firebase không có realtime listener cho `emailVerified`
/// → poll `reloadUser()` mỗi 4s + nút "Tôi đã xác minh". Khi verify xong,
/// `emailVerificationGateProvider` đổi false → `_RouterNotifier` notify →
/// router rời màn về /home.
class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  static const _pollInterval = Duration(seconds: 4);
  static const _resendCooldown = 60;

  Timer? _pollTimer;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  bool _isChecking = false;
  String? _resendError;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
    // Check ngay 1 lần — case user verify trên web ngay trước khi mở màn này.
    WidgetsBinding.instance.addPostFrameCallback((_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    // KHÔNG đụng ref trong dispose — router teardown có thể đã dispose element.
    super.dispose();
  }

  /// Reload + re-check. Nếu đã verify, gate flip → router tự điều hướng /home.
  Future<void> _poll() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    await ref.read(emailVerificationGateProvider.notifier).refresh();
    if (!mounted) return;
    setState(() => _isChecking = false);
  }

  Future<void> _onResend() async {
    setState(() => _resendError = null);
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (!mounted) return;
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      setState(() => _resendError = AppError.fromUnknown(e).message);
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = _resendCooldown);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _cooldownSeconds--);
      if (_cooldownSeconds <= 0) t.cancel();
    });
  }

  Future<void> _onSignOut() async {
    // uid → null → router redirect /intro. Gate recompute → false.
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.read(authRepositoryProvider).currentEmail ?? '';
    final canResend = _cooldownSeconds <= 0;

    return Scaffold(
      backgroundColor: AppColors.bw900,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 27),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                'Xác minh email của bạn',
                style: AppTextStyles.xlBold.copyWith(color: AppColors.bw100),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                email.isEmpty
                    ? 'Chúng tôi đã gửi email xác minh. Mở email và bấm vào '
                        'liên kết để tiếp tục.'
                    : 'Chúng tôi đã gửi email xác minh tới $email. Mở email '
                        'và bấm vào liên kết để tiếp tục.',
                style:
                    AppTextStyles.smSemiBold.copyWith(color: AppColors.bw500),
                textAlign: TextAlign.center,
              ),
              if (_resendError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _resendError!,
                  style: AppTextStyles.smSemiBold
                      .copyWith(color: AppColors.error400),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              GestureDetector(
                onTap: canResend ? _onResend : null,
                child: Text(
                  canResend
                      ? 'Chưa nhận được email? Gửi lại'
                      : 'Gửi lại sau ${_cooldownSeconds}s.',
                  style: AppTextStyles.smSemiBold.copyWith(
                    color: canResend ? AppColors.bw100 : AppColors.bw500,
                    decoration: canResend ? TextDecoration.underline : null,
                    decorationColor: AppColors.bw100,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              AppPrimaryButton(
                label: 'Tôi đã xác minh',
                isLoading: _isChecking,
                onPressed: _isChecking ? null : _poll,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _onSignOut,
                child: Text(
                  'Đổi tài khoản',
                  style:
                      AppTextStyles.smSemiBold.copyWith(color: AppColors.bw500),
                ),
              ),
              const SizedBox(height: 21),
            ],
          ),
        ),
      ),
    );
  }
}
