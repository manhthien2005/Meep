import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/core/theme/hex_color.dart';
import 'package:meep/features/space/data/space.dart';

/// Hàng cuộn ngang quick-access các Space trong SettingsSheet.
///
/// Render real Space data — iconEmoji + colorHex từ Space model. Tap card
/// → `onEditSpace(space)` để leader/creator chỉnh sửa. Card cuối là
/// `_CreateSpaceCard` luôn hiển thị → `onCreateSpace`.
///
/// Permission filter cho edit thực hiện ở caller (SettingsSheet) —
/// SpaceQuickRow chỉ là dumb widget render list.
class SpaceQuickRow extends StatelessWidget {
  const SpaceQuickRow({
    super.key,
    required this.spaces,
    this.isLoading = false,
    this.onEditSpace,
    this.onCreateSpace,
  });

  /// Danh sách Space user thuộc về — từ `spaceControllerProvider(uid).spaces`.
  final List<Space> spaces;

  /// True khi controller chưa emit lần đầu — render shimmer placeholder.
  final bool isLoading;

  /// Tap card Space → callback với Space model. Caller filter creator-only
  /// trước khi mở SpaceEditSheet.
  final ValueChanged<Space>? onEditSpace;

  /// Tap card "Tạo" → callback. Hiện wire qua rootContext pattern ở
  /// SettingsSheet để mở SpaceCreateSheet.
  final VoidCallback? onCreateSpace;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.favorite_border, size: 20, color: Colors.white),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Space',
              style: AppTextStyles.baseBold.copyWith(color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 115,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (isLoading && spaces.isEmpty) ...[
                const _SpaceCardShimmer(),
                const SizedBox(width: AppSpacing.md),
                const _SpaceCardShimmer(),
                const SizedBox(width: AppSpacing.md),
              ],
              for (final space in spaces) ...[
                _SpaceCard(
                  space: space,
                  onTap: () => onEditSpace?.call(space),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              _CreateSpaceCard(onTap: onCreateSpace),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpaceCard extends StatelessWidget {
  const _SpaceCard({required this.space, required this.onTap});

  final Space space;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Toàn card tappable: pill "Sửa" thuần visual indicator. Card 115x115 đã
    // vượt yêu cầu touch target 48x48.
    return Semantics(
      button: true,
      label: 'Sửa Space ${space.name}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 115,
          height: 115,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.bw700,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: AppColors.bw600.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon circle theo colorHex + iconEmoji thực tế của Space.
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: hexToColor(space.colorHex),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  space.iconEmoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              Text(
                space.name,
                style: AppTextStyles.xsSemiBold.copyWith(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bw600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Sửa',
                  style: AppTextStyles.xsSemiBold.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpaceCardShimmer extends StatelessWidget {
  const _SpaceCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 115,
      height: 115,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bw700,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.bw600.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: AppColors.bw600,
              borderRadius: BorderRadius.circular(21.5),
            ),
          ),
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.bw600,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(
            width: 36,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.bw600,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateSpaceCard extends StatelessWidget {
  const _CreateSpaceCard({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tạo Space',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 115,
          height: 115,
          decoration: BoxDecoration(
            color: AppColors.bw700,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: AppColors.bw600.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: AppColors.turquoise500.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.turquoise500, width: 2),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.turquoise500,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tạo',
                style: AppTextStyles.xsSemiBold.copyWith(
                  color: AppColors.turquoise500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
