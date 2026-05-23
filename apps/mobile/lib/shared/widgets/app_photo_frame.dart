import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_proportions.dart';

/// Square photo frame with rounded corners — 1:1 aspect, the visual unit
/// shared across camera viewfinder, captured-photo preview, friend post card,
/// own post card. Caller supplies the actual content via `child` (e.g.
/// `CameraPreview`, `Image.file`, `CachedNetworkImage`).
///
/// Figma: 400×400 with cornerRadius 50 on a 412 frame.
/// Size is computed internally from MediaQuery.
class AppPhotoFrame extends StatelessWidget {
  const AppPhotoFrame({
    super.key,
    required this.child,
    this.cornerRadius = 50,
    this.overlay,
    this.borderColor,
    this.borderWidth = 3,
  });

  final Widget child;
  final double cornerRadius;

  /// Optional overlay rendered above the photo with bottom-center alignment
  /// (e.g. note pill).
  final Widget? overlay;

  /// Optional accent border — render khi user trong Space context (set
  /// `space.colorHex`). Null = no border (default).
  final Color? borderColor;

  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context);
    final size = AppProportions.photoSize(s.width, s.height);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            decoration: borderColor == null
                ? null
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(cornerRadius),
                    border: Border.all(color: borderColor!, width: borderWidth),
                  ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(cornerRadius),
              child: SizedBox(
                width: size,
                height: size,
                child: ColoredBox(color: AppColors.bw900, child: child),
              ),
            ),
          ),
          if (overlay != null) overlay!,
        ],
      ),
    );
  }
}
