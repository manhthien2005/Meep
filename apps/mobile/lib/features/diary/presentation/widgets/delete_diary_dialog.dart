import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';

/// Confirmation dialog xác nhận xóa nhật ký.
///
/// Figma `769:5575` (Xóa nhật ký - Nhật ký). Card trắng cornerRadius 30,
/// title + message + 2 pill buttons. "Lưu" (cancel) / "Xoá" (destructive
/// Error/800 text).
///
/// `Navigator.pop(true)` = user xác nhận xóa; `false`/`null` = giữ lại.
class DeleteDiaryDialog extends StatelessWidget {
  const DeleteDiaryDialog({super.key});

  /// Hiện dialog, trả `true` nếu user chọn [Xoá].
  static Future<bool?> show(BuildContext context) => showDialog<bool>(
        context: context,
        barrierColor: const Color(0x80DEE5E6), // BW300 alpha — Figma scrim
        builder: (_) => const DeleteDiaryDialog(),
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
                  'Xóa nhật ký của bạn?',
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
                  'Nhật ký sẽ bị xóa hoàn toàn khỏi danh sách nhật ký hiện '
                  'tại của bạn',
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

            // 2 actions: Lưu (cancel) / Xoá (destructive)
            Row(
              children: [
                Expanded(
                  child: _PillButton(
                    label: 'Lưu',
                    textColor: AppColors.bw800, // #252627
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PillButton(
                    label: 'Xoá',
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
