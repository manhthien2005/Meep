import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_proportions.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/feed/application/post_controller.dart';
import 'package:meep/features/feed/data/post.dart';
import 'package:meep/features/feed/presentation/capture_action_bar.dart';
import 'package:meep/features/feed/presentation/capture_preview_args.dart';
import 'package:meep/features/feed/presentation/caption_preset_modal.dart';
import 'package:meep/features/friend/application/friend_controller.dart';
import 'package:meep/shared/widgets/app_avatar.dart';
import 'package:meep/shared/widgets/app_dots_indicator.dart';
import 'package:meep/shared/widgets/app_note_pill.dart';
import 'package:meep/shared/widgets/app_photo_frame.dart';

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

  void _swipeCaptionLeft() =>
      _changeCaptionIndex((_captionIndex + 1) % _captionTypes.length);

  void _swipeCaptionRight() => _changeCaptionIndex(
        (_captionIndex - 1 + _captionTypes.length) % _captionTypes.length,
      );

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
                    child: AppNotePill(
                      text: postState.caption ?? '',
                      onChanged: (t) => ref
                          .read(postControllerProvider.notifier)
                          .setCaption(t),
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
            // Spacers above and below the bar center it in the gap between
            // dots and audience row.
            const Spacer(),
            CaptureActionBar(
              config: PreviewBarConfig(
                isUploading: postState.isUploading,
                canSend: !(postState.audienceType == AudienceType.select &&
                    postState.selectedUids.isEmpty),
                onCancel: () => context.pop(),
                onSend: _send,
                onSparkles: _showCaptionModal,
              ),
            ),
            if (postState.errorMessage != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  postState.errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            Flexible(
              child: _AudienceRow(
                screenW: screenW,
                audienceType: postState.audienceType,
                selectedUids: postState.selectedUids,
                onAudienceChanged: (type, uids) => ref
                    .read(postControllerProvider.notifier)
                    .setAudience(type, uids),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onDownload, required this.savedToGallery});

  final VoidCallback onDownload;
  final bool savedToGallery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 24),
          const Spacer(),
          const Text(
            'Gửi đến...',
            style: TextStyle(
              color: AppColors.bw100,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              fontFamily: 'Nunito',
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onDownload,
            child: Icon(
              savedToGallery ? Icons.check : Icons.download_outlined,
              color: savedToGallery ? AppColors.turquoise500 : AppColors.bw100,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _AudienceRow extends ConsumerWidget {
  const _AudienceRow({
    required this.screenW,
    required this.audienceType,
    required this.selectedUids,
    required this.onAudienceChanged,
  });

  final double screenW;
  final AudienceType audienceType;
  final List<String> selectedUids;
  final void Function(AudienceType, List<String>) onAudienceChanged;

  // Figma: Buttons frame x=73 on 412 → left edge of X button
  static const double _leftPaddingRatio = 73 / 412;

  /// Toggle a friend in the selected list. Empty result flips back to
  /// AudienceType.all so the user doesn't need an explicit "deselect" gesture.
  void _toggleFriend(String friendUid) {
    final next = selectedUids.contains(friendUid)
        ? selectedUids.where((u) => u != friendUid).toList()
        : [...selectedUids, friendUid];
    if (next.isEmpty) {
      onAudienceChanged(AudienceType.all, const []);
    } else {
      onAudienceChanged(AudienceType.select, next);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leftPad = screenW * _leftPaddingRatio;
    final avatarSize = AppProportions.audienceAvatarSize(screenW);
    final labelSize = avatarSize * 0.43; // keep below overflow threshold
    final isAll = audienceType == AudienceType.all;

    final currentUid = ref.watch(currentUidProvider).valueOrNull;
    // Avoid throwing UnimplementedError when auth not ready — just render
    // the "Tất cả" tile until the uid resolves.
    final friends = currentUid == null
        ? const <UserProfile>[]
        : ref.watch(
            friendControllerProvider(currentUid).select((s) => s.friends),
          );

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: avatarSize + 4 + labelSize * 1.35 + 2,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.only(left: leftPad, right: 20),
          children: [
            _AllAudienceTile(
              isSelected: isAll,
              avatarSize: avatarSize,
              labelSize: labelSize,
              onTap: () => onAudienceChanged(AudienceType.all, const []),
            ),
            for (final friend in friends) ...[
              const SizedBox(width: 12),
              _FriendAudienceTile(
                friend: friend,
                isSelected: selectedUids.contains(friend.uid),
                avatarSize: avatarSize,
                labelSize: labelSize,
                onTap: () => _toggleFriend(friend.uid),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Tất cả" tile — selected by default, picks AudienceType.all.
class _AllAudienceTile extends StatelessWidget {
  const _AllAudienceTile({
    required this.isSelected,
    required this.avatarSize,
    required this.labelSize,
    required this.onTap,
  });

  final bool isSelected;
  final double avatarSize;
  final double labelSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isSelected ? AppColors.turquoise500 : AppColors.bw100;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.turquoise500 : AppColors.bw600,
                width: 1.5,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF394041),
              ),
              child: Icon(
                Icons.group_outlined,
                color: accent,
                size: avatarSize * 0.45,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tất cả',
            style: TextStyle(
              color: accent,
              fontSize: labelSize,
              fontWeight: FontWeight.w800,
              fontFamily: 'Nunito',
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Friend avatar tile — tap to add/remove this uid from the recipient list.
class _FriendAudienceTile extends StatelessWidget {
  const _FriendAudienceTile({
    required this.friend,
    required this.isSelected,
    required this.avatarSize,
    required this.labelSize,
    required this.onTap,
  });

  final UserProfile friend;
  final bool isSelected;
  final double avatarSize;
  final double labelSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isSelected ? AppColors.turquoise500 : AppColors.bw100;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppAvatar(
            imageUrl: friend.avatarUrl,
            size: avatarSize,
            ringColor: isSelected ? AppColors.turquoise500 : null,
            fallbackText: friend.displayName.isNotEmpty
                ? friend.displayName[0].toUpperCase()
                : null,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: avatarSize + 8,
            child: Text(
              friend.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accent,
                fontSize: labelSize,
                fontWeight: FontWeight.w800,
                fontFamily: 'Nunito',
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DualPreviewImage extends StatelessWidget {
  const _DualPreviewImage({
    required this.frontPath,
    required this.backPath,
    required this.primaryIsFront,
  });

  final String frontPath;
  final String backPath;
  final bool primaryIsFront;

  @override
  Widget build(BuildContext context) {
    final primary = primaryIsFront ? frontPath : backPath;
    final secondary = primaryIsFront ? backPath : frontPath;

    return LayoutBuilder(
      builder: (context, constraints) {
        final frameSize = constraints.maxWidth;
        final pipSize = AppProportions.pipSize(frameSize);
        final pipMargin = AppProportions.pipMargin(frameSize);

        return Stack(
          children: [
            // Primary (back camera by default) — full frame
            Positioned.fill(
              child: Image.file(
                File(primary),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            // Secondary (front camera by default) — PiP top-right
            Positioned(
              top: pipMargin,
              right: pipMargin,
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppProportions.pipCornerRadius),
                child: SizedBox(
                  width: pipSize,
                  height: pipSize,
                  child: Image.file(
                    File(secondary),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
