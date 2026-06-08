import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';

/// Error state cho feed (home PageView + grid view). Render message + nút
/// "Thử lại" gọi [onRetry] (caller invalidate provider để re-subscribe stream).
///
/// Feed-local — cross-module 12-site shared `AppErrorView` (STATE-UX-ERROR-001)
/// nằm ngoài scope PR này.
class FeedErrorView extends StatelessWidget {
  const FeedErrorView({
    super.key,
    required this.onRetry,
    this.message = 'Không tải được feed. Kiểm tra kết nối.',
  });

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.bw500,
              size: 44,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: AppColors.bw400, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Thử lại'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.turquoise500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
