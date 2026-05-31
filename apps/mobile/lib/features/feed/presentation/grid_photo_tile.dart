import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/features/feed/data/post.dart';

/// Single tile in feed grid view (`580:2883`). 1:1 aspect, light corner radius.
/// Tap → caller opens detail sheet.
class GridPhotoTile extends StatelessWidget {
  const GridPhotoTile({
    super.key,
    required this.post,
    required this.onTap,
    this.cornerRadius = 12,
  });

  final Post post;
  final VoidCallback onTap;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cornerRadius),
          child: CachedNetworkImage(
            imageUrl: post.coverImageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => const ColoredBox(color: AppColors.bw800),
            errorWidget: (_, __, ___) =>
                const ColoredBox(color: AppColors.bw800),
          ),
        ),
      ),
    );
  }
}
