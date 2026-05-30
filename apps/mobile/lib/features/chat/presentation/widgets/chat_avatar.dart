import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/core/theme/hex_color.dart';

/// Ring thickness around inbox avatars (Figma "Ellipse 29").
const double _kRingWidth = 2;

/// Gap between the ring and the avatar image (Figma shows the dark bg between
/// the turquoise ring and the photo).
const double _kRingGap = 2;

/// Circular avatar used across chat surfaces (inbox tile, bubbles, members).
///
/// [ringColor] draws the Figma "Ellipse 29" ring with a small gap to the photo:
/// turquoise = unread, bw700 = read. Pass null (default) for a plain avatar with
/// no ring — used in the chat header where Figma shows a borderless circle.
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({super.key, this.imageUrl, this.size = 50, this.ringColor});

  final String? imageUrl;
  final double size;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final inset = ringColor != null ? (_kRingWidth + _kRingGap) : 0.0;
    final inner = size - inset * 2;
    final avatar = ClipOval(
      child: SizedBox(
        width: inner,
        height: inner,
        child: (imageUrl != null && imageUrl!.isNotEmpty)
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: AppColors.bw600),
              )
            : const ColoredBox(color: AppColors.bw600),
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
/// [ringColor] behaves like [ChatAvatar.ringColor].
class SpaceAvatar extends StatelessWidget {
  const SpaceAvatar({
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
