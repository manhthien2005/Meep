import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/shared/widgets/app_primary_button.dart';

/// Rationale dialog (NOTIF-UX-PERM-001) — giải thích lợi ích TRƯỚC khi request
/// POST_NOTIFICATIONS (Android 13+). Show lần đầu khi quyền chưa được cấp và
/// còn hỏi lại được. Trả `true` nếu user bấm "Cho phép".
class NotificationPermissionDialog extends StatelessWidget {
  const NotificationPermissionDialog({super.key});

  /// Show modal; returns true nếu user đồng ý cho phép.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x73000000),
      builder: (_) => const NotificationPermissionDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bw800,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bật thông báo',
              style: AppTextStyles.lgBold.copyWith(color: AppColors.bw100),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Cho phép Meep gửi thông báo để không bỏ lỡ ảnh và tim từ '
              'bạn bè.',
              style: AppTextStyles.smSemiBold.copyWith(color: AppColors.bw500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(
              label: 'Cho phép',
              showTrailingIcon: false,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Để sau',
                style:
                    AppTextStyles.smSemiBold.copyWith(color: AppColors.bw500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fallback banner (NOTIF-UX-PERM-001) — hiện khi quyền thông báo bị từ chối
/// vĩnh viễn (permanentlyDenied). Hệ thống không cho hỏi lại trong app nên chỉ
/// còn cách mở Cài đặt. Hiển thị qua Overlay (giống NotificationBanner).
class NotificationPermissionBanner extends StatelessWidget {
  const NotificationPermissionBanner({
    super.key,
    required this.onOpenSettings,
    required this.onDismiss,
  });

  /// Mở Cài đặt ứng dụng (NotificationController.openNotificationSettings).
  final VoidCallback onOpenSettings;

  /// Đóng banner cho phiên hiện tại.
  final VoidCallback onDismiss;

  static const _width = 364.0;

  @override
  Widget build(BuildContext context) {
    // Material wrapper — banner thường render trong Overlay (không có Material
    // ancestor) nên TextButton/IconButton cần lớp này.
    return Material(
      color: Colors.transparent,
      child: Container(
        width: _width,
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        decoration: BoxDecoration(
          color: AppColors.bw800,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông báo đang tắt',
                    style: AppTextStyles.smSemiBold
                        .copyWith(color: AppColors.bw100),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bật trong Cài đặt để nhận ảnh từ bạn bè.',
                    style: AppTextStyles.xsSemiBold
                        .copyWith(color: AppColors.bw500),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onOpenSettings,
              child: Text(
                'Mở Cài đặt',
                style: AppTextStyles.smSemiBold
                    .copyWith(color: AppColors.turquoise300),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18, color: AppColors.bw500),
              tooltip: 'Đóng',
            ),
          ],
        ),
      ),
    );
  }
}
