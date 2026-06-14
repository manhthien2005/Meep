import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_proportions.dart';
import 'package:meep/core/theme/hex_color.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/public_profile.dart';
import 'package:meep/features/feed/application/post_controller.dart';
import 'package:meep/shared/models/post.dart';
import 'package:meep/features/feed/presentation/capture_action_bar.dart';
import 'package:meep/features/feed/presentation/capture_preview_args.dart';
import 'package:meep/features/feed/presentation/caption_preset_modal.dart';
import 'package:meep/features/friend/application/friend_controller.dart';
import 'package:meep/features/space/application/space_controller.dart';
import 'package:meep/features/space/data/space.dart';
import 'package:meep/shared/widgets/app_avatar.dart';
import 'package:meep/shared/widgets/app_dots_indicator.dart';
import 'package:meep/shared/widgets/app_note_pill.dart';
import 'package:meep/shared/widgets/app_photo_frame.dart';

part 'capture_preview_widgets.dart';

class CapturePreviewScreen extends ConsumerStatefulWidget {
  const CapturePreviewScreen({super.key, required this.args});

  final CapturePreviewArgs args;

  @override
  ConsumerState<CapturePreviewScreen> createState() =>
      _CapturePreviewScreenState();
}

class _CapturePreviewScreenState extends ConsumerState<CapturePreviewScreen> {
  // Swipe through 7 caption types in this order.
  static const _captionTypes = CaptionType.values;
  // Min horizontal velocity (px/s) to count as a swipe (filters jitter).
  static const double _swipeVelocityThreshold = 200;

  int _captionIndex = 0;
  bool _savedToGallery = false;
  bool _primaryIsFront = false;

  // Direction of the most recent caption swipe; 1 = next (slide in from right),
  // -1 = prev (slide in from left). Drives the slide transition direction.
  int _lastCaptionDir = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(postControllerProvider.notifier);
      if (widget.args.isDual) {
        notifier.setPendingDualImages(
          backPath: widget.args.backPhotoPath!,
          frontPath: widget.args.frontPhotoPath!,
        );
      } else {
        notifier.setPendingImage(widget.args.imagePath!);
      }
      notifier.setCaptionType(CaptionType.text);
    });
    _primaryIsFront = widget.args.activePrimaryLensIsFront;
  }

  void _swipeCaptionLeft() {
    _lastCaptionDir = 1;
    _changeCaptionIndex((_captionIndex + 1) % _captionTypes.length);
  }

  void _swipeCaptionRight() {
    _lastCaptionDir = -1;
    _changeCaptionIndex(
      (_captionIndex - 1 + _captionTypes.length) % _captionTypes.length,
    );
  }

  void _changeCaptionIndex(int idx) {
    setState(() => _captionIndex = idx);
    ref
        .read(postControllerProvider.notifier)
        .setCaptionType(_captionTypes[idx]);
  }

  Future<void> _saveToGallery() async {
    if (_savedToGallery) return;
    try {
      await Gal.putImage(widget.args.imagePath ?? widget.args.backPhotoPath!);
      if (!mounted) return;
      setState(() => _savedToGallery = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể lưu ảnh')),
      );
    }
  }

  Future<void> _send() async {
    final ok = await ref.read(postControllerProvider.notifier).submit();
    if (ok && mounted) context.go('/home');
  }

  void _showCaptionModal() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => CaptionPresetModal(
        onSelect: (type) {
          final idx = _captionTypes.indexOf(type);
          if (idx >= 0) _changeCaptionIndex(idx);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postState = ref.watch(postControllerProvider);
    final screenW = MediaQuery.sizeOf(context).width;
    final screenH = MediaQuery.sizeOf(context).height;
    final photoSize = AppProportions.photoSize(screenW, screenH);

    return Scaffold(
      backgroundColor: AppColors.bw900,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onDownload: _saveToGallery,
              savedToGallery: _savedToGallery,
            ),
            // Spacer above the photo, balanced by the spacer below the dots, so
            // the (photo + dots) cluster sits vertically centered between the
            // header and the action bar.
            const Spacer(),
            GestureDetector(
              onHorizontalDragEnd: (d) {
                final v = d.primaryVelocity;
                if (v == null) return;
                if (v < -_swipeVelocityThreshold) _swipeCaptionLeft();
                if (v > _swipeVelocityThreshold) _swipeCaptionRight();
              },
              child: GestureDetector(
                onTap: () {
                  if (!widget.args.isDual) return;
                  setState(() => _primaryIsFront = !_primaryIsFront);
                },
                child: AppPhotoFrame(
                  overlay: Padding(
                    padding: EdgeInsets.only(
                      bottom: AppProportions.pillBottomInPhoto(photoSize),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        // Rebuild a Tween per child so the incoming pill slides
                        // in from the swipe direction and the outgoing one
                        // slides out the opposite way — keeps the gesture and
                        // the visual motion aligned.
                        final captionKey =
                            ValueKey(_captionTypes[_captionIndex]);
                        final isIncoming = child.key == captionKey;
                        final beginX = isIncoming
                            ? _lastCaptionDir.toDouble()
                            : -_lastCaptionDir.toDouble();
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(beginX, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: AppNotePill(
                        key: ValueKey(_captionTypes[_captionIndex]),
                        text: postState.caption ?? '',
                        onChanged: (t) => ref
                            .read(postControllerProvider.notifier)
                            .setCaption(t),
                      ),
                    ),
                  ),
                  child: widget.args.isDual
                      ? _DualPreviewImage(
                          frontPath: widget.args.frontPhotoPath!,
                          backPath: widget.args.backPhotoPath!,
                          primaryIsFront: _primaryIsFront,
                        )
                      : Image.file(
                          File(widget.args.imagePath!),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
            SizedBox(height: AppProportions.dotsTopGap(screenW)),
            AppDotsIndicator(
              count: _captionTypes.length,
              current: _captionIndex,
              shrinkOuter: true,
            ),
            // Equal spacers above + below CaptureActionBar so nó căn giữa
            // giữa đáy photo (sau dots) và AudienceRow ở bottom.
            const Spacer(),
            CaptureActionBar(
              config: PreviewBarConfig(
                isUploading: postState.isUploading,
                canSend: !(postState.audienceType == AudienceType.select &&
                    postState.selectedUids.isEmpty &&
                    postState.selectedSpaceIds.isEmpty),
                onCancel: () => context.pop(),
                onSend: _send,
                onSparkles: _showCaptionModal,
              ),
            ),
            const Spacer(),
            if (postState.errorMessage != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      postState.errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // submit() idempotent (giữ pendingImagePath/bytes) → retry
                    // không bắt user chụp lại (UPLOAD-UX-001).
                    TextButton.icon(
                      onPressed: postState.isUploading ? null : _send,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Thử lại'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.turquoise500,
                      ),
                    ),
                  ],
                ),
              ),
            _AudienceRow(
              screenW: screenW,
              audienceType: postState.audienceType,
              selectedUids: postState.selectedUids,
              selectedSpaceIds: postState.selectedSpaceIds,
              onAudienceChanged: (type, uids) => ref
                  .read(postControllerProvider.notifier)
                  .setAudience(type, uids),
              onSpaceToggled: (spaceId) => ref
                  .read(postControllerProvider.notifier)
                  .toggleSpace(spaceId),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
