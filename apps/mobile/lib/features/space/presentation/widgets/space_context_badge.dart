import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/core/theme/hex_color.dart';
import 'package:meep/features/space/application/space_controller.dart';

/// Pill nhỏ "Đang gửi: [SpaceName]" hiện trên Camera khi user đang ở Space
/// context. Watch [currentSpaceProvider] — render `SizedBox.shrink()` khi
/// null (All friends mặc định).
///
/// Background dùng `space.colorHex` làm accent — match viền Camera mà
/// CameraSection set theo currentSpace.
class SpaceContextBadge extends ConsumerWidget {
  const SpaceContextBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(currentSpaceProvider);
    if (space == null) return const SizedBox.shrink();

    final accent = tryHexToColor(space.colorHex) ?? AppColors.turquoise500;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bw900.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            space.iconEmoji,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 6),
          Text(
            'Đang gửi: ${space.name}',
            style: AppTextStyles.smSemiBold.copyWith(color: AppColors.bw100),
          ),
        ],
      ),
    );
  }
}
