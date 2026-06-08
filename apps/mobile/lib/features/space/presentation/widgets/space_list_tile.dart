import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/core/theme/hex_color.dart';
import 'package:meep/features/space/data/space.dart';

/// Single row trong [SpaceContextBottomSheet] — Space icon (emoji + color
/// background) + name + memberCount + selected check.
///
/// `space` null → "All friends" tile (icon + "Tất cả bạn bè").
class SpaceListTile extends StatelessWidget {
  const SpaceListTile({
    super.key,
    this.space,
    required this.isSelected,
    required this.onTap,
  });

  /// `null` = "All friends" row. Non-null = Space context row.
  final Space? space;

  /// True khi tile đại diện cho `currentSpaceProvider` hiện tại.
  final bool isSelected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAllFriends = space == null;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _Icon(space: space),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAllFriends ? 'Tất cả bạn bè' : space!.name,
                    style:
                        AppTextStyles.mdBold.copyWith(color: AppColors.bw100),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isAllFriends) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${space!.memberCount} thành viên',
                      style: AppTextStyles.smRegular
                          .copyWith(color: AppColors.bw400),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.turquoise500,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon({required this.space});

  final Space? space;

  @override
  Widget build(BuildContext context) {
    if (space == null) {
      return Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bw700,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.groups_rounded,
          color: AppColors.bw100,
          size: 22,
        ),
      );
    }

    final color = tryHexToColor(space!.colorHex) ?? AppColors.bw700;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      alignment: Alignment.center,
      child: Text(
        space!.iconEmoji,
        style: const TextStyle(fontSize: 20),
      ),
    );
  }
}
