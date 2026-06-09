import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_proportions.dart';
import 'package:meep/shared/models/post.dart';
import 'package:meep/shared/widgets/dual_post_image.dart';

class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    super.key,
    required this.photos,
    this.posts,
    required this.onTap,
  }) : assert(posts == null || posts.length == photos.length);

  final List<String> photos;
  final List<Post>? posts;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có ảnh nào',
          style: TextStyle(color: AppColors.bw500),
        ),
      );
    }
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) => _PhotoItem(
        url: photos[index],
        post: posts?[index],
        onTap: () => onTap(index),
      ),
    );
  }
}

class _PhotoItem extends StatelessWidget {
  const _PhotoItem({
    required this.url,
    required this.onTap,
    this.post,
  });

  final String url;
  final VoidCallback onTap;
  final Post? post;

  @override
  Widget build(BuildContext context) {
    final cacheW = (MediaQuery.sizeOf(context).width /
            AppProportions.gridColumns *
            MediaQuery.devicePixelRatioOf(context))
        .round();
    return Semantics(
      button: true,
      label: 'Xem ảnh',
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: post?.isDualCamera == true
              ? DualPostImage(
                  backImageUrl: post?.backImageUrl ?? '',
                  frontImageUrl: post?.frontImageUrl ?? '',
                  enableSwapOnTap: false,
                  memCacheWidth: cacheW,
                  memCacheHeight: cacheW,
                )
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColors.bw700),
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(color: AppColors.bw800),
                ),
        ),
      ),
    );
  }
}
