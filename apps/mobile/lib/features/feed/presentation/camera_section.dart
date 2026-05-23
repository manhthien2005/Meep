import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_proportions.dart';
import 'package:meep/features/feed/application/app_camera_controller.dart';
import 'package:meep/features/feed/application/camera_state.dart';
import 'package:meep/features/feed/presentation/capture_action_bar.dart';
import 'package:meep/features/feed/presentation/capture_preview_args.dart';
import 'package:meep/features/space/application/space_controller.dart';
import 'package:meep/features/space/presentation/widgets/space_context_badge.dart';
import 'package:meep/shared/widgets/app_dots_indicator.dart';
import 'package:meep/shared/widgets/app_photo_frame.dart';

class CameraSection extends ConsumerStatefulWidget {
  const CameraSection({super.key, required this.onGoToFeed});

  final VoidCallback onGoToFeed;

  @override
  ConsumerState<CameraSection> createState() => _CameraSectionState();
}

class _CameraSectionState extends ConsumerState<CameraSection> {
  // Min horizontal velocity (px/s) to count as a mode-switch swipe.
  static const double _swipeVelocityThreshold = 200;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appCameraControllerProvider.notifier).initialize();
    });
  }

  // Swipe right over the viewfinder → dual mode; swipe left → single.
  void _onViewfinderSwipe(double? velocity) {
    if (velocity == null) return;
    final notifier = ref.read(appCameraControllerProvider.notifier);
    if (velocity > _swipeVelocityThreshold) {
      notifier.setMode(CameraMode.single);
    } else if (velocity < -_swipeVelocityThreshold) {
      notifier.setMode(CameraMode.dual);
    }
  }

  Future<void> _onCapture() async {
    final path = await ref.read(appCameraControllerProvider.notifier).capture();
    if (!mounted || path == null) return;
    final camState = ref.read(appCameraControllerProvider);
    if (camState.mode == CameraMode.single) {
      unawaited(
        context.push(
          '/capture-preview',
          extra: CapturePreviewArgs.single(imagePath: path),
        ),
      );
      return;
    }
    if (camState.backPhotoPath != null && camState.frontPhotoPath != null) {
      unawaited(
        context.push(
          '/capture-preview',
          extra: CapturePreviewArgs.dual(
            backPhotoPath: camState.backPhotoPath!,
            frontPhotoPath: camState.frontPhotoPath!,
            activePrimaryLensIsFront: camState.activeLens == CameraLens.front,
          ),
        ),
      );
    }
  }

  Future<void> _onAlbumPick() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      unawaited(
        context.push(
          '/capture-preview',
          extra: CapturePreviewArgs.single(imagePath: image.path),
        ),
      );
    }
  }

  /// Parse 7-char hex `#RRGGBB` của Space colorHex. Null safe — null in,
  /// null out → CameraSection trả về default UI khi không có Space context.
  Color? _spaceAccent(String? hex) {
    if (hex == null) return null;
    try {
      final clean = hex.replaceFirst('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final camState = ref.watch(appCameraControllerProvider);
    // Watch Space context — null = "All friends" mặc định, non-null = Space
    // context. CameraSection re-render: viền + nút chụp + badge đổi theo
    // colorHex của Space hiện tại.
    final currentSpace = ref.watch(currentSpaceProvider);
    final accent = _spaceAccent(currentSpace?.colorHex);
    final screenW = MediaQuery.sizeOf(context).width;
    // Mirror _AudienceRow height: avatarSize + gap(4) + labelSize(avatarSize*0.4) + bottomPad(4)
    final historyRowH = AppProportions.audienceAvatarSize(screenW) * 1.4 + 8;

    return Column(
      children: [
        // Spacer above the photo, balanced by the spacer below the dots, so
        // the (photo + dots) cluster sits vertically centered in the space
        // between the top bar and the action bar.
        const Spacer(),
        // Badge "Đang gửi: [SpaceName]" — chỉ hiện khi currentSpace != null.
        // Render above frame để user scan rõ context trước khi chụp.
        if (currentSpace != null) ...const [
          SpaceContextBadge(),
          SizedBox(height: 8),
        ],
        GestureDetector(
          onHorizontalDragEnd: (d) => _onViewfinderSwipe(d.primaryVelocity),
          child: AppPhotoFrame(
            borderColor: accent,
            child: camState.mode == CameraMode.single
                ? _ViewfinderContent(
                    controller: ref
                        .read(appCameraControllerProvider.notifier)
                        .cameraController,
                    isInitialized: camState.isInitialized,
                    error: camState.error,
                  )
                : _DualViewfinderContent(
                    controller: ref
                        .read(appCameraControllerProvider.notifier)
                        .cameraController,
                    isInitialized: camState.isInitialized,
                    error: camState.error,
                    activeLens: camState.activeLens,
                    frontPhotoPath: camState.frontPhotoPath,
                    backPhotoPath: camState.backPhotoPath,
                    onTapFront: () => ref
                        .read(appCameraControllerProvider.notifier)
                        .setActiveLens(CameraLens.front),
                    onTapBack: () => ref
                        .read(appCameraControllerProvider.notifier)
                        .setActiveLens(CameraLens.back),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTapUp: (details) {
            final width = MediaQuery.sizeOf(context).width;
            final isRight = details.localPosition.dx > width / 2;
            ref
                .read(appCameraControllerProvider.notifier)
                .setMode(isRight ? CameraMode.dual : CameraMode.single);
          },
          child: AppDotsIndicator(
            count: 2,
            current: camState.mode == CameraMode.dual ? 1 : 0,
          ),
        ),
        // Spacers above and below the bar center it in the gap between
        // dots and history button.
        const Spacer(),
        CaptureActionBar(
          config: CameraBarConfig(
            onCapture: _onCapture,
            onAlbum: _onAlbumPick,
            onFlip: () =>
                ref.read(appCameraControllerProvider.notifier).toggleCamera(),
            isCapturing: camState.isCapturing,
            showFlip: camState.mode == CameraMode.single,
            captureRingColor: accent,
          ),
        ),
        const Spacer(),
        SizedBox(
          height: historyRowH,
          child: Center(child: _HistoryButton(onTap: widget.onGoToFeed)),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Dual-camera PiP viewfinder: back camera full-frame, front camera PiP top-right.
/// Tap PiP to swap active lens.
class _DualViewfinderContent extends StatelessWidget {
  const _DualViewfinderContent({
    required this.controller,
    required this.isInitialized,
    required this.error,
    required this.activeLens,
    required this.frontPhotoPath,
    required this.backPhotoPath,
    required this.onTapFront,
    required this.onTapBack,
  });

  final CameraController? controller;
  final bool isInitialized;
  final String? error;
  final CameraLens activeLens;
  final String? frontPhotoPath;
  final String? backPhotoPath;
  final VoidCallback onTapFront;
  final VoidCallback onTapBack;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Container(
        color: AppColors.bw800,
        alignment: Alignment.center,
        child:
            const Icon(Icons.no_photography, color: AppColors.bw500, size: 48),
      );
    }

    final primaryIsFront = activeLens == CameraLens.front;

    return LayoutBuilder(
      builder: (context, constraints) {
        final frameSize = constraints.maxWidth;
        final pipSize = AppProportions.pipSize(frameSize);
        final pipMargin = AppProportions.pipMargin(frameSize);

        return Stack(
          children: [
            // Primary (back by default) — full frame
            Positioned.fill(
              child: _DualSlot(
                lens: primaryIsFront ? CameraLens.front : CameraLens.back,
                isActive: true,
                controller: controller,
                isInitialized: isInitialized,
                frozenPath: primaryIsFront ? frontPhotoPath : backPhotoPath,
                onTap: primaryIsFront ? onTapFront : onTapBack,
                isPip: false,
              ),
            ),
            // Secondary (front by default) — PiP top-right
            Positioned(
              top: pipMargin,
              right: pipMargin,
              child: SizedBox(
                width: pipSize,
                height: pipSize,
                child: _DualSlot(
                  lens: primaryIsFront ? CameraLens.back : CameraLens.front,
                  isActive: false,
                  controller: controller,
                  isInitialized: isInitialized,
                  frozenPath: primaryIsFront ? backPhotoPath : frontPhotoPath,
                  onTap: primaryIsFront ? onTapBack : onTapFront,
                  isPip: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DualSlot extends StatelessWidget {
  const _DualSlot({
    required this.lens,
    required this.isActive,
    required this.controller,
    required this.isInitialized,
    required this.frozenPath,
    required this.onTap,
    this.isPip = false,
  });

  final CameraLens lens;
  final bool isActive;
  final CameraController? controller;
  final bool isInitialized;
  final String? frozenPath;
  final VoidCallback onTap;
  final bool isPip;

  @override
  Widget build(BuildContext context) {
    final child = isActive && isInitialized && controller != null
        ? _ViewfinderContent(
            controller: controller,
            isInitialized: isInitialized,
            error: null,
          )
        : frozenPath == null
            ? const ColoredBox(color: AppColors.bw900)
            : Image.file(File(frozenPath!), fit: BoxFit.cover);

    final cornerRadius = isPip ? AppProportions.pipCornerRadius : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cornerRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            // Label only on PiP slot
            if (isPip)
              Positioned(
                left: 8,
                top: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bw900.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lens == CameraLens.front ? 'Trước' : 'Sau',
                    style: const TextStyle(
                      color: AppColors.bw100,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ViewfinderContent extends StatelessWidget {
  const _ViewfinderContent({
    required this.controller,
    required this.isInitialized,
    required this.error,
  });

  final CameraController? controller;
  final bool isInitialized;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Container(
        color: AppColors.bw800,
        alignment: Alignment.center,
        child:
            const Icon(Icons.no_photography, color: AppColors.bw500, size: 48),
      );
    }
    if (!isInitialized || controller == null) {
      return const ColoredBox(color: AppColors.bw900);
    }
    // CameraPreview already wraps itself in the correct AspectRatio +
    // RotatedBox for the device orientation. We only need to scale it so the
    // (typically 3:4) preview fills the square frame without distortion —
    // matching how the captured photo is later shown with BoxFit.cover.
    final previewRatio = 1 / controller!.value.aspectRatio; // portrait ratio
    final coverScale = previewRatio < 1 ? 1 / previewRatio : previewRatio;
    return ClipRect(
      child: Transform.scale(
        scale: coverScale,
        child: Center(child: CameraPreview(controller!)),
      ),
    );
  }
}

class _HistoryButton extends StatelessWidget {
  const _HistoryButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bw700,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Lịch sử ▾',
            style: TextStyle(
              color: AppColors.bw100,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
