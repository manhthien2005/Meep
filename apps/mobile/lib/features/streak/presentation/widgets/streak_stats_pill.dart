import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';

/// Pill stats bottom của StreakScreen — match Figma `269:1992`.
///
/// Layout: " N Khoảnh khắc | Xd chuỗi"
/// - Số (N / Xd): WHITE Nunito Bold 12
/// - Chữ (Khoảnh khắc / chuỗi): WHITE 48% alpha Nunito Bold 12
/// - Separator "|": Inter SemiBold 10 WHITE 48% alpha
/// - Container: bg `#5857546e`, cornerRadius 12, padding 8/11
class StreakStatsPill extends StatelessWidget {
  const StreakStatsPill({
    super.key,
    required this.totalMoments,
    required this.currentStreak,
  });

  final int totalMoments;
  final int currentStreak;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.bw100.withValues(alpha: 0.58);
    final numberStyle = AppTextStyles.xsSemiBold.copyWith(
      color: AppColors.bw100,
      fontWeight: FontWeight.w700,
    );
    final labelStyle = AppTextStyles.xsSemiBold.copyWith(
      color: muted,
      fontWeight: FontWeight.w700,
    );
    final sepStyle = AppTextStyles.xsSemiBold.copyWith(color: muted);

    return Semantics(
      label: '$totalMoments khoảnh khắc, chuỗi $currentStreak ngày',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bw800.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.bw700.withValues(alpha: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: RichText(
          text: TextSpan(
            style: numberStyle,
            children: [
              TextSpan(text: ' $totalMoments'),
              TextSpan(text: ' Khoảnh khắc ', style: labelStyle),
              TextSpan(text: '|', style: sepStyle),
              TextSpan(text: ' ${currentStreak}d'),
              TextSpan(text: ' chuỗi ', style: labelStyle),
            ],
          ),
        ),
      ),
    );
  }
}
