import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/features/feed/application/app_camera_controller.dart';
import 'package:meep/features/feed/application/camera_state.dart';

/// Fallback hiển thị trong viewfinder khi camera init lỗi (CAMERA-UX-001).
///
/// - permission denied → message + "Thử lại" + "Mở Cài đặt" (openAppSettings).
/// - lỗi khác (no hardware, init fail) → message + "Thử lại".
///
/// Thay cho ô đen + icon gạch chân cũ — user biết phải làm gì để post được
/// (Tier 0 golden path). Message tiếng Việt lấy thẳng từ controller state.
class CameraPermissionFallback extends ConsumerWidget {
  const CameraPermissionFallback({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appCameraControllerProvider);
    final isDenied = state.permissionState == CameraPermissionState.denied;
    final message = state.error ?? 'Không thể khởi động máy ảnh';

    return Container(
      color: AppColors.bw800,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography, color: AppColors.bw500, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.bw100,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () =>
                    ref.read(appCameraControllerProvider.notifier).retry(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Thử lại'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.bw100,
                ),
              ),
              if (isDenied) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: openAppSettings,
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: const Text('Mở Cài đặt'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.turquoise500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
