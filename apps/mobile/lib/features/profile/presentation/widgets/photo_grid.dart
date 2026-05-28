import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';

class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    super.key,
    required this.photos,
    required this.onTap,
  });

  final List<String> photos;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Center(
        child: Text(
          'Chưa có ảnh nào',
          style: const TextStyle(color: AppColors.bw500),
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
        onTap: () => onTap(index),
      ),
    );
  }
}

class _PhotoItem extends StatelessWidget {
  const _PhotoItem({required this.url, required this.onTap});

  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Xem ảnh',
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: AppColors.bw700),
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : Container(color: AppColors.bw800),
          ),
        ),
      ),
    );
  }
}
