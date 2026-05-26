import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_radii.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/core/validators/auth_validators.dart';
import 'package:meep/features/auth/application/password_reset_controller.dart';
import 'package:meep/shared/widgets/app_back_button.dart';
import 'package:meep/shared/widgets/app_primary_button.dart';
import 'package:meep/shared/widgets/app_text_input.dart';

/// Màn hình đặt lại mật khẩu — user mở từ deep link trong email reset.
/// [oobCode] là mã xác thực từ query param `?oobCode=xxx` của deep link.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, required this.oobCode});

  final String oobCode;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _pwCtrl = TextEditingController();
  final _pwFocus = FocusNode();
  // Local state — không dùng loginControllerProvider.isSuccess để tránh state leak
  bool _isResetSuccess = false;

  @override
  void dispose() {
    _pwCtrl.dispose();
    _pwFocus.dispose();
    ref.read(passwordResetControllerProvider.notifier).resetState();
    super.dispose();
  }

  bool get _canSave => AuthValidators.isPasswordValid(_pwCtrl.text);

  Future<void> _onSave() async {
    await ref.read(passwordResetControllerProvider.notifier).confirmReset(
          oobCode: widget.oobCode,
          newPassword: _pwCtrl.text,
        );
    if (!mounted) return;
    final controllerState = ref.read(passwordResetControllerProvider);
    if (controllerState.errorMessage == null && !controllerState.isLoading) {
      setState(() => _isResetSuccess = true);
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordResetControllerProvider);

    // Input status: dùng _isResetSuccess (local) thay state.isSuccess
    AppTextInputStatus inputStatus;
    if (_isResetSuccess) {
      inputStatus = AppTextInputStatus.success;
    } else if (state.errorMessage != null) {
      inputStatus = AppTextInputStatus.error;
    } else if (_canSave) {
      inputStatus = AppTextInputStatus.success;
    } else {
      inputStatus = AppTextInputStatus.normal;
    }

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
                      'Đặt lại mật khẩu của bạn',
                      style:
                          AppTextStyles.xlBold.copyWith(color: AppColors.bw100),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Mật khẩu tối thiểu 8 ký tự.',
                      style: AppTextStyles.xsRegular
                          .copyWith(color: AppColors.bw600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    AppTextInput(
                      inputType: AppTextInputType.password,
                      controller: _pwCtrl,
                      focusNode: _pwFocus,
                      hint: 'Mật khẩu mới',
                      errorText: state.errorMessage,
                      status: inputStatus,
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_isResetSuccess) ...[
                      const SizedBox(height: 20),
                      const _PasswordChangedPill(),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(37, 0, 37, 33),
              child: _isResetSuccess
                  ? _PasswordSavedButton(
                      onTap: () => context.go('/login/email'),
                    )
                  : AppPrimaryButton(
                      label: 'Lưu mật khẩu',
                      isLoading: state.isLoading,
                      onPressed:
                          (_canSave && !_isResetSuccess) ? _onSave : null,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── "Bây giờ bạn có thể đăng nhập bằng mật khẩu mới." pill ──────────────────

class _PasswordChangedPill extends StatelessWidget {
  const _PasswordChangedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.bw700,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        'Bây giờ bạn có thể đăng nhập bằng mật khẩu mới.',
        style: AppTextStyles.smSemiBold.copyWith(color: AppColors.bw100),
      ),
    );
  }
}

// ── "Đã thay đổi mật khẩu" success button ────────────────────────────────────

class _PasswordSavedButton extends StatelessWidget {
  const _PasswordSavedButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Đã thay đổi mật khẩu',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.turquoise300,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Đã thay đổi mật khẩu',
                style: AppTextStyles.mdBold
                    .copyWith(color: AppColors.turquoise800),
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
        ),
      ),
    );
  }
}
