import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/core/theme/hex_color.dart';

/// Ring thickness around avatars.
const double _kRingWidth = 2;

/// Gap between the ring and the avatar image.
const double _kRingGap = 2;

/// Circular avatar for user profile pictures.
///
/// [ringColor] draws an optional ring with a small gap to the photo.
/// Pass null (default) for a plain avatar with no ring.
///
/// [fallbackText] shows when [imageUrl] is null/empty — typically the user's
/// first initial. If null, shows a solid gray circle.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.size = 50,
    this.ringColor,
    this.fallbackText,
  });

  final String? imageUrl;
  final double size;
  final Color? ringColor;
  final String? fallbackText;

  @override
  Widget build(BuildContext context) {
    final inset = ringColor != null ? (_kRingWidth + _kRingGap) : 0.0;
    final inner = size - inset * 2;
    final avatar = ClipOval(
      child: Container(
        width: inner,
        height: inner,
        decoration: BoxDecoration(
          color: AppColors.bw700,
          shape: BoxShape.circle,
          image: (imageUrl != null && imageUrl!.isNotEmpty)
              ? DecorationImage(
                  image: NetworkImage(imageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: (imageUrl == null || imageUrl!.isEmpty) && fallbackText != null
            ? Center(
                child: Text(
                  fallbackText!,
                  style: AppTextStyles.mdBold.copyWith(
                    color: AppColors.bw100,
                  ),
                ),
              )
            : null,
      ),
    );

    if (ringColor == null) return avatar;

    // Ring (outer) → dark gap → avatar: two nested circles create the gap.
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: ringColor),
      padding: const EdgeInsets.all(_kRingWidth),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bw900,
        ),
        padding: const EdgeInsets.all(_kRingGap),
        child: avatar,
      ),
    );
  }
}

/// Avatar showing a Space's emoji on its themed color (group conversations).
/// [ringColor] behaves like [AppAvatar.ringColor].
class AppSpaceAvatar extends StatelessWidget {
  const AppSpaceAvatar({
    super.key,
    required this.emoji,
    required this.colorHex,
    this.size = 50,
    this.ringColor,
  });

  final String emoji;
  final String colorHex;
  final double size;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final inset = ringColor != null ? (_kRingWidth + _kRingGap) : 0.0;
    final inner = size - inset * 2;
    final disc = Container(
      width: inner,
      height: inner,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hexToColor(colorHex),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: AppTextStyles.mdBold),
    );

    if (ringColor == null) return disc;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: ringColor),
      padding: const EdgeInsets.all(_kRingWidth),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bw900,
        ),
        padding: const EdgeInsets.all(_kRingGap),
        child: disc,
      ),
    );
  }
}
