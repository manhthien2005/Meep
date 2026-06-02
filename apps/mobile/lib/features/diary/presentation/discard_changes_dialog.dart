import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';

/// Confirmation dialog hiện khi user tap [←] back trong Canvas create mode
/// (có thay đổi chưa lưu).
///
/// Figma pattern: theo Delete Dialog `769:5575` — popup card trắng,
/// 2 buttons pill. Spec: "Bỏ nhật ký này?" + [Bỏ] / [Tiếp tục viết].
///
/// `Navigator.pop` trả `true` = user xác nhận bỏ; `false`/`null` = tiếp tục.
class DiscardChangesDialog extends StatelessWidget {
  const DiscardChangesDialog({super.key});

  /// Hiện dialog, trả `true` nếu user chọn [Bỏ] (discard).
  static Future<bool?> show(BuildContext context) => showDialog<bool>(
        context: context,
        barrierColor: const Color(0x80DEE5E6), // BW300 với alpha — Figma scrim
        builder: (_) => const DiscardChangesDialog(),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 68),
      child: Container(
        padding: const EdgeInsets.fromLTRB(25, 20, 25, 20),
        decoration: BoxDecoration(
          color: AppColors.bw100, // #F9FCFC
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.bw300), // #DEE5E6
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title + message
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bỏ nhật ký này?',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.bw900, // #050F10
                    height: 22 / 16,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Nội dung bạn đã viết sẽ không được lưu lại.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.bw700, // #394041
                    height: 18 / 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2 actions: Tiếp tục viết (default) / Bỏ (destructive)
            Row(
              children: [
                Expanded(
                  child: _PillButton(
                    label: 'Tiếp tục viết',
                    textColor: AppColors.bw800, // #252627
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PillButton(
                    label: 'Bỏ',
                    textColor: AppColors.error800, // #E43700
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

/// Pill button — text-only, nền BW200, bo góc 30. Figma `769:5887` / `769:5889`.
class _PillButton extends StatelessWidget {
  const _PillButton({
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
      label: label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 39,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.bw200, // #EEF2F3
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
              height: 18 / 14,
            ),
          ),
        ),
      ),
    );
  }
}
