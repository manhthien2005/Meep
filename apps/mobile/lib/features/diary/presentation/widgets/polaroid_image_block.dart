import 'package:flutter/material.dart';

/// Polaroid inline image block — ảnh user trong khung Polaroid trang trí.
///
/// Figma: `769:4984` / `769:5118` (Polaroid Frame trong Canvas read).
/// Asset: `assets/frames/frame_polaroid.png` (598×721, có sẵn placeholder
/// xám ở center + textured lattice phía dưới — KHÔNG transparent center).
///
/// Layout: AspectRatio 277.63 : 339 = 0.819 (theo Figma). Frame asset
/// đặt làm background; ảnh user position vào "Picture Window" region
/// (top 4.53%, left 5.69%, width 88.6%, height 73.0%) đè lên vùng gray
/// placeholder của asset.
class PolaroidImageBlock extends StatelessWidget {
  const PolaroidImageBlock({super.key, required this.imageUrl});

  final String imageUrl;

  // Picture Window region trong frame (tỉ lệ theo Figma `769:5116`).
  static const _picLeft = 15.79 / 277.63; // 5.69%
  static const _picTop = 15.36 / 339; // 4.53%
  static const _picWidth = 246.02 / 277.63; // 88.6%
  static const _picHeight = 247.4 / 339; // 73.0%
  static const _aspect = 277.63 / 339;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _aspect,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            children: [
              // 1. Frame asset background (white border + textured lattice
              //    + gray placeholder ở center sẵn).
              Positioned.fill(
                child: Image.asset(
                  'assets/frames/frame_polaroid.png',
                  fit: BoxFit.fill,
                ),
              ),

              // 2. User image đè lên picture window — che vùng gray placeholder.
              Positioned(
                left: w * _picLeft,
                top: h * _picTop,
                width: w * _picWidth,
                height: h * _picHeight,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : const SizedBox.shrink(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
