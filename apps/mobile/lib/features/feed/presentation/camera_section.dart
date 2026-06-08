import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_proportions.dart';
import 'package:meep/features/feed/application/app_camera_controller.dart';
import 'package:meep/features/feed/application/camera_state.dart';
import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/features/feed/presentation/capture_action_bar.dart';
import 'package:meep/features/feed/presentation/capture_preview_args.dart';
import 'package:meep/features/feed/presentation/widgets/camera_permission_fallback.dart';
import 'package:meep/shared/widgets/app_dots_indicator.dart';
import 'package:meep/shared/widgets/app_photo_frame.dart';

class CameraSection extends ConsumerStatefulWidget {
  const CameraSection({super.key, required this.onGoToFeed});

  final VoidCallback onGoToFeed;

  @override
  ConsumerState<CameraSection> createState() => _CameraSectionState();
}

class _CameraSectionState extends ConsumerState<CameraSection> {
  // Pages: 0 = single mode, 1 = dual mode. Drives the horizontal PageView
  // inside the viewfinder so the user can swipe through modes one-to-one with
  // their finger — mirrors the vertical PageView that drives camera ↔ feed in
  // HomeScreen.
  late final PageController _modePageController;

  // Snapshot of the live zoomLevel at the moment a pinch starts, so each
  // onScaleUpdate can multiply against the stable base instead of compounding.
  double _baseZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _modePageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appCameraControllerProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _modePageController.dispose();
    super.dispose();
  }

  void _onModePageChanged(int page) {
    final mode = page == 0 ? CameraMode.single : CameraMode.dual;
    ref.read(appCameraControllerProvider.notifier).setMode(mode);
  }

  /// Animate the viewfinder PageView to match the requested mode. Called from
  /// taps on the dots indicator below — without this the dots feel dead since
  /// state changes alone don't move the PageView.
  void _animateToMode(CameraMode mode) {
    final target = mode == CameraMode.dual ? 1 : 0;
    if (!_modePageController.hasClients) return;
    if (_modePageController.page?.round() == target) return;
    _modePageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _onCapture() async {
    final notifier = ref.read(appCameraControllerProvider.notifier);
    final path = await notifier.capture();
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
      // Drop the frozen back/front photos so coming back to the camera page
      // shows a live viewfinder instead of the previous capture.
      unawaited(notifier.clearDualPhotos());
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

  @override
  Widget build(BuildContext context) {
    final camState = ref.watch(appCameraControllerProvider);
    final screenW = MediaQuery.sizeOf(context).width;
    // Mirror _AudienceRow height: avatarSize + gap(4) + labelSize(avatarSize*0.4) + bottomPad(4)
    final historyRowH = AppProportions.audienceAvatarSize(screenW) * 1.4 + 8;

    // Listen for external mode changes (e.g. dots tap, programmatic
    // setMode) so the PageView animates to match. PageView's own onPageChanged
    // already calls setMode, so the listener no-ops when the page is already
    // in sync.
    ref.listen<CameraMode>(
      appCameraControllerProvider.select((s) => s.mode),
      (_, next) => _animateToMode(next),
    );

    return Column(
      children: [
        // Spacer above the photo, balanced by the spacer below the dots, so
        // the (photo + dots) cluster sits vertically centered in the space
        // between the top bar and the action bar.
        const Spacer(),
        _ViewfinderArea(
          camState: camState,
          borderColor: null,
          modePageController: _modePageController,
          onModePageChanged: _onModePageChanged,
          onPinchStart: () => _baseZoom = camState.zoomLevel,
          onPinchUpdate: (scale) => ref
              .read(appCameraControllerProvider.notifier)
              .setZoom(_baseZoom * scale),
          onToggleFlash: () =>
              ref.read(appCameraControllerProvider.notifier).toggleFlash(),
          onSetActiveLens: (lens) => ref
              .read(appCameraControllerProvider.notifier)
              .setActiveLens(lens),
          cameraController:
              ref.read(appCameraControllerProvider.notifier).cameraController,
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTapUp: (details) {
            final width = MediaQuery.sizeOf(context).width;
            final isRight = details.localPosition.dx > width / 2;
            _animateToMode(isRight ? CameraMode.dual : CameraMode.single);
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
            captureRingColor: null,
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

/// Holds the photo frame, the slide animation between single/dual viewfinders,
/// the pinch-zoom gesture, and the flash button overlay. Extracted so the main
/// build() in [_CameraSectionState] stays readable.
class _ViewfinderArea extends StatelessWidget {
  const _ViewfinderArea({
    required this.camState,
    required this.borderColor,
    required this.modePageController,
    required this.onModePageChanged,
    required this.onPinchStart,
    required this.onPinchUpdate,
    required this.onToggleFlash,
    required this.onSetActiveLens,
    required this.cameraController,
  });

  final CameraState camState;
  final Color? borderColor;
  final PageController modePageController;
  final ValueChanged<int> onModePageChanged;
  final VoidCallback onPinchStart;
  final ValueChanged<double> onPinchUpdate;
  final VoidCallback onToggleFlash;
  final ValueChanged<CameraLens> onSetActiveLens;
  final CameraController? cameraController;

  /// Flash hardware lives on the back lens. In single mode that means hide the
  /// button entirely whenever the front camera is active. In dual mode the
  /// back lens is always part of the capture, so the button stays visible.
  bool get _showFlashButton {
    if (camState.mode == CameraMode.single) return !camState.isFrontCamera;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Both pages stay in the tree at all times so the PageView can render
    // both halves while the user drags between them. Only the page whose
    // mode is currently live receives the camera controller; the other one
    // renders the (typically very brief) black-while-reinitializing state.
    final singlePage = _ViewfinderContent(
      controller: camState.mode == CameraMode.single ? cameraController : null,
      isInitialized:
          camState.mode == CameraMode.single && camState.isInitialized,
      error: camState.error,
      isFrontCamera: camState.isFrontCamera,
    );
    final dualPage = _DualViewfinderContent(
      controller: camState.mode == CameraMode.dual ? cameraController : null,
      isInitialized: camState.mode == CameraMode.dual && camState.isInitialized,
      error: camState.error,
      activeLens: camState.activeLens,
      frontPhotoPath: camState.frontPhotoPath,
      backPhotoPath: camState.backPhotoPath,
      onTapFront: () => onSetActiveLens(CameraLens.front),
      onTapBack: () => onSetActiveLens(CameraLens.back),
    );

    return Stack(
      children: [
        AppPhotoFrame(
          borderColor: borderColor,
          // RawGestureDetector lets pinch-zoom (Scale recognizer) co-exist
          // with the inner PageView's horizontal drag — the PageView's drag
          // wins single-finger horizontal swipes (mode switch), Scale wins
          // 2-finger pinches. The empty vertical drag claim wins arena over
          // the parent vertical PageView (camera ↔ feed) so vertical pinches
          // don't flip the page.
          child: RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            gestures: <Type, GestureRecognizerFactory>{
              VerticalDragGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                      VerticalDragGestureRecognizer>(
                () => VerticalDragGestureRecognizer(),
                (r) {
                  r.onStart = (_) {};
                  r.onUpdate = (_) {};
                  r.onEnd = (_) {};
                },
              ),
              ScaleGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
                () => ScaleGestureRecognizer(),
                (r) {
                  r.onStart = (_) => onPinchStart();
                  r.onUpdate = (d) {
                    if (d.pointerCount < 2) return;
                    onPinchUpdate(d.scale);
                  };
                },
              ),
            },
            child: PageView(
              controller: modePageController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              onPageChanged: onModePageChanged,
              children: [singlePage, dualPage],
            ),
          ),
        ),
        if (_showFlashButton)
          Positioned(
            top: 12,
            right: 12,
            child: _FlashButton(
              enabled: camState.flashEnabled,
              onTap: onToggleFlash,
            ),
          ),
      ],
    );
  }
}

class _FlashButton extends StatelessWidget {
  const _FlashButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: enabled ? 'Tắt flash' : 'Bật flash',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.bw900.withValues(alpha: 0.45),
            shape: BoxShape.circle,
          ),
          child: Icon(
            enabled ? Icons.bolt : Icons.bolt_outlined,
            color: enabled ? AppColors.turquoise500 : AppColors.bw100,
            size: 22,
          ),
        ),
      ),
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
      return const CameraPermissionFallback();
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
            isFrontCamera: lens == CameraLens.front,
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
    this.isFrontCamera = false,
  });

  final CameraController? controller;
  final bool isInitialized;
  final String? error;

  /// Mặc định preview Android đã gương mặt cho cam trước (selfie-mirror) —
  /// giữ nguyên hành vi đó. File chụp ra được flip ngang ở
  /// [AppCameraController.capture] để khớp với preview, nên KHÔNG cần
  /// Transform un-mirror ở đây nữa.
  final bool isFrontCamera;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return const CameraPermissionFallback();
    }
    if (!isInitialized || controller == null) {
      return const ColoredBox(color: AppColors.bw900);
    }
    final previewRatio = 1 / controller!.value.aspectRatio;
    final coverScale = previewRatio < 1 ? 1 / previewRatio : previewRatio;
    return ClipRect(
      child: Transform.scale(
        scale: coverScale,
        child: Center(child: CameraPreview(controller!)),
      ),
    );
  }
}

class _HistoryButton extends ConsumerWidget {
  const _HistoryButton({required this.onTap});

  final VoidCallback onTap;

  static const double _thumbSize = 26;
  static const double _thumbRadius = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Feed is sorted createdAt desc by watchFeed(), so posts.first is the
    // newest visible post — own or friend. Empty feed falls back to a flat
    // bw700 tile.
    final thumbUrl =
        ref.watch(feedControllerProvider(filter: FeedFilter.all)).whenOrNull(
              data: (s) => s.posts.isEmpty ? null : s.posts.first.coverImageUrl,
            );

    final thumb = SizedBox(
      width: _thumbSize,
      height: _thumbSize,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_thumbRadius),
        child: thumbUrl == null || thumbUrl.isEmpty
            ? const ColoredBox(color: AppColors.bw700)
            : CachedNetworkImage(
                imageUrl: thumbUrl,
                fit: BoxFit.cover,
                // Thumb render ở 26px — decode bitmap đúng kích thước hiển thị
                // thay vì full 1080px (IMG-PERF-001).
                memCacheWidth:
                    (_thumbSize * MediaQuery.devicePixelRatioOf(context))
                        .round(),
                placeholder: (_, __) =>
                    const ColoredBox(color: AppColors.bw700),
                errorWidget: (_, __, ___) =>
                    const ColoredBox(color: AppColors.bw700),
              ),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          thumb,
          const SizedBox(width: 6),
          const Text(
            'Lịch sử',
            style: TextStyle(
              color: AppColors.bw100,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.bw100,
            size: 22,
          ),
        ],
      ),
    );
  }
}
