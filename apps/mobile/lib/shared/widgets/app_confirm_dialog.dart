import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';

/// Floating confirm modal (Popup) for destructive actions.
///
/// Figma pattern: bw800 fill, radius 30, hairline border, left-aligned
/// title/body, two pill buttons on bw700 where the destructive label is red.
///
/// Used by: unfriend `564:7131`, leave-space `564:9063`.
///
/// Returns `true` if confirmed, `false` if cancelled or dismissed.
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String cancelLabel,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => Dialog(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.mdSemiBold.copyWith(color: AppColors.bw100),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: AppTextStyles.smRegular.copyWith(color: AppColors.bw400),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ConfirmDialogButton(
                    label: cancelLabel,
                    textColor: AppColors.bw100,
                    onTap: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ConfirmDialogButton(
                    label: confirmLabel,
                    textColor: AppColors.error800,
                    onTap: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
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
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
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
      ),
    );
  }
}
