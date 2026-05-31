import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/shared/widgets/app_confirm_dialog.dart';

class DeleteAccountDialog {
  static Future<bool?> show(BuildContext context) async {
    // Step 1: Confirm intent using shared dialog
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Bạn có chắc muốn xoá tài khoản này không?',
      body: 'Tất cả dữ liệu sẽ bị xoá vĩnh viễn. Không thể phục hồi.',
      cancelLabel: 'Huỷ',
      confirmLabel: 'Xoá',
    );

    if (!confirmed) return false;

    // Step 2: Re-auth
    if (context.mounted) {
      return showDialog<bool>(
        context: context,
        builder: (_) => const _ReauthDialog(),
      );
    }
    return false;
  }
}

class _ReauthDialog extends StatefulWidget {
  const _ReauthDialog();

  @override
  State<_ReauthDialog> createState() => _ReauthDialogState();
}

class _ReauthDialogState extends State<_ReauthDialog> {
  final _passwordController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              'Vui lòng nhập mật khẩu để xác nhận',
              style: AppTextStyles.smRegular.copyWith(color: AppColors.bw400),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: AppTextStyles.mdRegular.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Mật khẩu',
                hintStyle:
                    AppTextStyles.mdRegular.copyWith(color: AppColors.bw500),
                filled: true,
                fillColor: const Color(0xFF3A3A3C),
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
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _ConfirmDialogButton(
                    label: 'Huỷ',
                    textColor: AppColors.bw100,
                    onTap: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ConfirmDialogButton(
                    label: 'Xác nhận',
                    textColor: AppColors.error800,
                    onTap: () {
                      // TODO(T6/NganTNK): reauthenticate + SettingsController.deleteAccount()
                      // On FirebaseAuthException(requires-recent-login):
                      //   setState(() => _errorText = 'Vui lòng xác thực lại để tiếp tục');
                      Navigator.pop(context, true);
                    },
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
  });

  final String label;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.bw700,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: AppTextStyles.smSemiBold.copyWith(color: textColor),
        ),
      ),
    );
  }
}
