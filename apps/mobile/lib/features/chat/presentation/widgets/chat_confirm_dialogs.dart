import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/shared/widgets/app_bottom_sheet.dart';
import 'package:meep/shared/widgets/app_confirm_dialog.dart';

/// "Xóa bạn" (unfriend) confirm popup. Figma `564:7131` — buttons Huỷ / Xoá.
Future<bool> showUnfriendDialog(BuildContext context, String name) {
  return showAppConfirmDialog(
    context,
    title: 'Xóa $name khỏi Meep của bạn?',
    body: 'Các bạn sẽ không còn có thể gửi ảnh cho nhau trên Meep. '
        'Lịch sử của bạn sẽ có thể phục hồi nếu các bạn thêm lại nhau.',
    cancelLabel: 'Huỷ',
    confirmLabel: 'Xoá',
  );
}

/// "Rời khỏi Space" confirm popup. Figma `564:9063` — buttons Hủy / Rời khỏi.
Future<bool> showLeaveSpaceDialog(BuildContext context) {
  return showAppConfirmDialog(
    context,
    title: 'Rời khỏi Space của bạn?',
    body: 'Cuộc trò chuyện sẽ được lưu trữ và bạn sẽ không còn có thể nhận '
        'được tin nhắn nào của bạn bè trên Space.',
    cancelLabel: 'Hủy',
    confirmLabel: 'Rời khỏi',
  );
}

/// "Chặn" (block) confirm — Figma `564:7080` is a BOTTOM SHEET (AppBottomSheet),
/// primary "Chặn" button on turquoise, secondary "Bỏ qua" on bw700.
Future<bool> showBlockSheet(BuildContext context, String name) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => AppBottomSheet(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(39, 24, 39, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block, size: 28, color: AppColors.bw100),
              const SizedBox(height: 20),
              Text(
                'Chặn $name?',
                textAlign: TextAlign.center,
                style: AppTextStyles.baseBold.copyWith(color: AppColors.bw100),
              ),
              const SizedBox(height: 14),
              Text(
                'Họ sẽ không thể nhắn tin cho bạn, xem các khoảnh khắc của bạn '
                'hoặc gửi lời mời kết bạn. Hai người vẫn có thể được thêm vào '
                'cùng một nhóm, nhưng sẽ không thể xem tin nhắn hoặc khoảnh '
                'khắc của nhau.',
                textAlign: TextAlign.center,
                style: AppTextStyles.smMedium.copyWith(color: AppColors.bw100),
              ),
              const SizedBox(height: 14),
              Text(
                'Họ sẽ không được thông báo rằng mình đã bị chặn',
                textAlign: TextAlign.center,
                style: AppTextStyles.smMedium.copyWith(color: AppColors.bw100),
              ),
              const SizedBox(height: 24),
              _SheetButton(
                label: 'Chặn',
                background: AppColors.turquoise600,
                textColor: AppColors.turquoise900,
                onTap: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 12),
              _SheetButton(
                label: 'Bỏ qua',
                background: AppColors.bw700,
                textColor: AppColors.bw100,
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.background,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color background;
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
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            style: AppTextStyles.mdBold.copyWith(color: textColor),
          ),
        ),
      ),
    );
  }
}
