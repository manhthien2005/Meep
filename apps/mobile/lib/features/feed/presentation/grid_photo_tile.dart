import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_proportions.dart';
import 'package:meep/shared/models/post.dart';
import 'package:meep/shared/widgets/dual_post_image.dart';

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
    // Decode bitmap ~ kích thước tile (screenW / số cột) thay vì full 1080px —
    // grid 3-cột render ảnh ~120px, tránh giữ 4.6MB/bitmap (IMG-PERF-001).
    final cacheW = (MediaQuery.sizeOf(context).width /
            AppProportions.gridColumns *
            MediaQuery.devicePixelRatioOf(context))
        .round();
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cornerRadius),
          child: post.isDualCamera
              ? DualPostImage(
                  backImageUrl: post.backImageUrl ?? '',
                  frontImageUrl: post.frontImageUrl ?? '',
                  enableSwapOnTap: false,
                  memCacheWidth: cacheW,
                  memCacheHeight: cacheW,
                )
              : CachedNetworkImage(
                  imageUrl: post.coverImageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: cacheW,
                  memCacheHeight: cacheW,
                  placeholder: (_, __) =>
                      const ColoredBox(color: AppColors.bw800),
                  errorWidget: (_, __, ___) =>
                      const ColoredBox(color: AppColors.bw800),
                ),
        ),
      ),
    );
  }
}
