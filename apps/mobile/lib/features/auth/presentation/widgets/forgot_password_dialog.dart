import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_radii.dart';
import 'package:meep/core/theme/app_text_styles.dart';

/// "Đặt lại mật khẩu?" confirmation dialog.
///
/// Returns `true` qua `Navigator.pop` khi user xác nhận "Đặt lại",
/// `false` khi "Huỷ" / `null` khi tap ngoài (do barrier).
///
/// Caller dùng: `await showDialog<bool>(... builder: (_) => const ForgotPasswordDialog())`.
class ForgotPasswordDialog extends StatelessWidget {
  const ForgotPasswordDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bw800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        side: BorderSide(color: AppColors.bw600.withValues(alpha: 0.5)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đặt lại mật khẩu?',
              style: AppTextStyles.mdSemiBold.copyWith(color: AppColors.bw100),
            ),
            const SizedBox(height: 10),
            Text(
              'Bạn sẽ nhận được một email kèm theo hướng dẫn để đặt lại mật khẩu của mình.',
              style: AppTextStyles.smRegular.copyWith(color: AppColors.bw400),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: 'Huỷ',
                    textColor: AppColors.bw100,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _DialogButton(
                    label: 'Đặt lại',
                    textColor: AppColors.error800,
                    onTap: () => Navigator.of(context).pop(true),
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

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.bw700,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.smSemiBold.copyWith(color: textColor),
          ),
        ),
      ),
    );
  }
}
