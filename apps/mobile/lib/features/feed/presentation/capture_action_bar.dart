import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_proportions.dart';
import 'package:meep/shared/widgets/app_camera_button.dart';
import 'package:meep/shared/widgets/app_circle_icon_button.dart';

sealed class CaptureBarConfig {
  const CaptureBarConfig();
}

final class CameraBarConfig extends CaptureBarConfig {
  const CameraBarConfig({
    required this.onCapture,
    required this.onAlbum,
    required this.onFlip,
    required this.isCapturing,
    this.showFlip = true,
    this.captureRingColor,
  });

  final VoidCallback onCapture;
  final VoidCallback onAlbum;
  final VoidCallback onFlip;
  final bool isCapturing;
  final bool showFlip;

  /// Override viền nút chụp khi user trong Space context (pass
  /// `space.colorHex`). Null = default turquoise500.
  final Color? captureRingColor;
}

final class PreviewBarConfig extends CaptureBarConfig {
  const PreviewBarConfig({
    required this.onCancel,
    required this.onSend,
    required this.onSparkles,
    required this.isUploading,
    required this.canSend,
  });

  final VoidCallback onCancel;
  final VoidCallback onSend;
  final VoidCallback onSparkles;
  final bool isUploading;
  final bool canSend;
}

/// Single action bar used by both the camera screen and the capture preview
/// screen. Renders capture controls or send controls depending on [config].
/// Fixed 6 px horizontal padding matches the photo frame inset.
class CaptureActionBar extends StatelessWidget {
  const CaptureActionBar({super.key, required this.config});

  final CaptureBarConfig config;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final sideSize = AppProportions.sideIconSize(screenW);
    final centerSize = AppProportions.captureOuter(screenW);
    final gap = AppProportions.captureRowGap(screenW);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: switch (config) {
          CameraBarConfig(
            :final onCapture,
            :final onAlbum,
            :final onFlip,
            :final isCapturing,
            :final showFlip,
            :final captureRingColor,
          ) =>
            [
              _SideBtn(
                icon: Icons.image_outlined,
                size: sideSize,
                onTap: onAlbum,
              ),
              SizedBox(width: gap),
              AppCameraButton(
                size: centerSize,
                onPressed: isCapturing ? null : onCapture,
                ringColor: captureRingColor,
              ),
              SizedBox(width: gap),
              showFlip
                  ? _SideBtn(
                      icon: Icons.flip_camera_android_outlined,
                      size: sideSize,
                      onTap: onFlip,
                    )
                  : SizedBox(width: sideSize, height: sideSize),
            ],
          PreviewBarConfig(
            :final onCancel,
            :final onSend,
            :final onSparkles,
            :final isUploading,
            :final canSend,
          ) =>
            [
              AppCircleIconButton(
                icon: Icons.close,
                size: sideSize,
                onPressed: isUploading ? null : onCancel,
                transparentBackground: true,
                iconScale: 0.66,
              ),
              SizedBox(width: gap),
              AppCircleIconButton(
                icon: Icons.send,
                size: centerSize,
                onPressed: (isUploading || !canSend) ? null : onSend,
                backgroundColor:
                    canSend ? AppColors.turquoise500 : AppColors.bw700,
                iconColor: canSend ? AppColors.bw900 : AppColors.bw100,
                isLoading: isUploading,
              ),
              SizedBox(width: gap),
              AppCircleIconButton(
                icon: Icons.auto_awesome,
                size: sideSize,
                onPressed: onSparkles,
                transparentBackground: true,
                iconScale: 0.66,
              ),
            ],
        },
      ),
    );
  }
}

class _SideBtn extends StatelessWidget {
  const _SideBtn({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, color: AppColors.bw100, size: size * 1.17),
      ),
    );
  }
}
