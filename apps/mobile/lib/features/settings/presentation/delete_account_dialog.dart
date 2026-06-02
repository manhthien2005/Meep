import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/settings/application/settings_controller.dart';
import 'package:meep/shared/widgets/app_confirm_dialog.dart';

/// 2-step delete account flow (Figma `572:4605` → reauth inline).
///
/// Step 1: confirm intent qua [showAppConfirmDialog].
/// Step 2: [_ReauthDialog] — reauth + cascade delete. Provider detection:
///   - `password` → email + password field
///   - `google.com` → trigger Google account picker (no password field)
///
/// On reauth success → `SettingsController.deleteAccount()` → CF cascade.
/// Khi CF xóa Auth account, client `authStateChanges` emit null → router
/// auth listener auto-redirect `/intro` (xem `main.dart` + `app_router`).
///
/// Dialog returns:
/// - `true` → account deleted, navigation đã trigger
/// - `false` → user cancelled (step 1 hoặc step 2 huỷ)
/// - `null` → step 2 barrierDismissible=false, không xảy ra
class DeleteAccountDialog {
  static Future<bool?> show(BuildContext context) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Bạn có chắc muốn xoá tài khoản này không?',
      body: 'Tất cả dữ liệu sẽ bị xoá vĩnh viễn. Không thể phục hồi.',
      cancelLabel: 'Huỷ',
      confirmLabel: 'Xoá',
    );

    if (!confirmed) return false;
    if (!context.mounted) return false;

    return showDialog<bool>(
      context: context,
      // Prevent auto-dismiss on tap outside — match plan acceptance:
      // requires-recent-login + reauth errors phải giữ dialog mở để user fix.
      barrierDismissible: false,
      builder: (_) => const _ReauthDialog(),
    );
  }
}

class _ReauthDialog extends ConsumerStatefulWidget {
  const _ReauthDialog();

  @override
  ConsumerState<_ReauthDialog> createState() => _ReauthDialogState();
}

class _ReauthDialogState extends ConsumerState<_ReauthDialog> {
  final _passwordController = TextEditingController();
  String? _errorText;
  bool _isProcessing = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isGoogleUser =>
      ref.read(authRepositoryProvider).currentProviderId == 'google.com';

  Future<void> _onConfirm() async {
    if (_isProcessing) return;

    final isGoogle = _isGoogleUser;

    if (!isGoogle && _passwordController.text.isEmpty) {
      setState(() => _errorText = 'Vui lòng nhập mật khẩu');
      return;
    }

    setState(() {
      _errorText = null;
      _isProcessing = true;
    });

    final auth = ref.read(authRepositoryProvider);
    try {
      if (isGoogle) {
        await auth.reauthenticateWithGoogle();
      } else {
        await auth.reauthenticateWithPassword(_passwordController.text);
      }
    } on OperationCancelledError {
      // User dismissed Google picker — keep dialog open silently.
      if (mounted) setState(() => _isProcessing = false);
      return;
    } catch (e) {
      if (!mounted) return;
      final err = AppError.fromUnknown(e);
      setState(() {
        _errorText = err.message;
        _isProcessing = false;
      });
      return;
    }

    if (!mounted) return;

    // Reauth success → trigger cascade delete.
    await ref.read(settingsControllerProvider.notifier).deleteAccount();

    if (!mounted) return;

    final settings = ref.read(settingsControllerProvider);
    if (settings.errorMessage != null) {
      setState(() {
        _errorText = settings.errorMessage;
        _isProcessing = false;
      });
      return;
    }

    // Success — close dialog. Router auth listener (main.dart watchUid)
    // sẽ navigate /intro khi authStateChanges emit null sau CF deleteUser.
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isGoogle = _isGoogleUser;

    return Dialog(
      backgroundColor: AppColors.bw800,
      insetPadding: const EdgeInsets.symmetric(horizontal: 64),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: AppColors.bw600.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Xác thực lại',
              style: AppTextStyles.lgBold.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isGoogle
                  ? 'Chạm xác nhận để xác thực lại với Google'
                  : 'Vui lòng nhập mật khẩu để xác nhận',
              style: AppTextStyles.smRegular.copyWith(color: AppColors.bw400),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (!isGoogle)
              TextField(
                controller: _passwordController,
                obscureText: true,
                enabled: !_isProcessing,
                style: AppTextStyles.mdRegular.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Mật khẩu',
                  hintStyle:
                      AppTextStyles.mdRegular.copyWith(color: AppColors.bw500),
                  filled: true,
                  fillColor: AppColors.bw700,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  errorText: _errorText,
                  errorStyle: AppTextStyles.xsRegular.copyWith(
                    color: AppColors.error500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: AppColors.turquoise500),
                  ),
                ),
              ),
            if (isGoogle && _errorText != null) ...[
              Text(
                _errorText!,
                style: AppTextStyles.xsRegular.copyWith(
                  color: AppColors.error500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _ConfirmDialogButton(
                    label: 'Huỷ',
                    textColor: AppColors.bw100,
                    enabled: !_isProcessing,
                    onTap: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ConfirmDialogButton(
                    label: _isProcessing ? 'Đang xử lý...' : 'Xác nhận',
                    textColor: AppColors.error800,
                    enabled: !_isProcessing,
                    onTap: _onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmDialogButton extends StatelessWidget {
  const _ConfirmDialogButton({
    required this.label,
    required this.textColor,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final Color textColor;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.bw700
                : AppColors.bw700.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            style: AppTextStyles.smSemiBold.copyWith(
              color: enabled ? textColor : textColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
