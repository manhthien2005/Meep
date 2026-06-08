import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_proportions.dart';
import 'package:meep/shared/models/post.dart';
import 'package:meep/shared/widgets/app_note_pill.dart';
import 'package:meep/shared/widgets/app_photo_frame.dart';

/// Full-width post card showing photo + optional note overlay.
/// Used by feed (friend + own variants), profile gallery detail, grid detail.
///
/// Card sizes itself off MediaQuery so it works in both Sliver
/// (feed) and constrained (grid detail sheet) contexts. Caller supplies
/// `footer` widget below the photo (author row / "Bạn · ngày" / activity bar).
class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    this.footer,
    this.onLongPress,
    this.borderColor,
  });

  final Post post;
  final Widget? footer;
  final VoidCallback? onLongPress;

  /// Viền ngoài AppPhotoFrame. Null = không viền (mặc định). Feed truyền
  /// space.colorHex của post.spaceId để PostCard visualize Space context
  /// (giống camera page Space accent trước đây).
  final Color? borderColor;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  // Dual mode: which lens occupies the primary (large) slot. Back-first
  // matches capture order; tap swaps to front.
  bool _primaryIsFront = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final s = MediaQuery.sizeOf(context);
    final photoSize = AppProportions.photoSize(s.width, s.height);
    final hasCaption = (post.caption ?? '').trim().isNotEmpty;

    return Column(
      // Center so the square photo (screenW - 12) sits between equal 6px
      // gutters on both sides instead of sticking to the left edge.
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onLongPress: widget.onLongPress,
          onTap: post.isDualCamera
              ? () => setState(() => _primaryIsFront = !_primaryIsFront)
              : null,
          child: AppPhotoFrame(
            borderColor: widget.borderColor,
            overlay: hasCaption
                ? Padding(
                    padding: EdgeInsets.only(
                      bottom: AppProportions.pillBottomInPhoto(photoSize),
                    ),
                    child: AppNotePill(
                      text: post.caption!,
                      readOnly: true,
                    ),
                  )
                : null,
            child: post.isDualCamera
                ? _DualPostImage(
                    backImageUrl: post.backImageUrl ?? '',
                    frontImageUrl: post.frontImageUrl ?? '',
                    primaryIsFront: _primaryIsFront,
                  )
                : CachedNetworkImage(
                    imageUrl: post.coverImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const ColoredBox(color: AppColors.bw800),
                    errorWidget: (_, __, ___) => const ColoredBox(
                      color: AppColors.bw800,
                      child: Icon(Icons.broken_image, color: AppColors.bw600),
                    ),
                  ),
          ),
        ),
        if (widget.footer != null) ...[
          // 1% of screen height (~9px on a 917-tall device) per product spec —
          // header pill sits just under the photo without crowding it.
          SizedBox(height: s.height * 0.01),
          widget.footer!,
        ],
      ],
    );
  }
}

/// Dual-camera PiP layout for the feed: back camera full-frame as background,
/// front camera small overlay at top-right. Tap swaps which lens is primary.
/// Mirrors the capture preview so the feed matches what the author saw.
class _DualPostImage extends StatelessWidget {
  const _DualPostImage({
    required this.backImageUrl,
    required this.frontImageUrl,
    required this.primaryIsFront,
  });

  final String backImageUrl;
  final String frontImageUrl;
  final bool primaryIsFront;

  @override
  Widget build(BuildContext context) {
    final primary = primaryIsFront ? frontImageUrl : backImageUrl;
    final secondary = primaryIsFront ? backImageUrl : frontImageUrl;

    return LayoutBuilder(
      builder: (context, constraints) {
        final frameSize = constraints.maxWidth;
        final pipSize = AppProportions.pipSize(frameSize);
        final pipMargin = AppProportions.pipMargin(frameSize);

        return Stack(
          children: [
            // Primary (back camera by default) — full frame
            Positioned.fill(
              child: _NetworkImage(url: primary),
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
                  child: _NetworkImage(url: secondary),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NetworkImage extends StatelessWidget {
  const _NetworkImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (_, __) => const ColoredBox(color: AppColors.bw800),
      errorWidget: (_, __, ___) => const ColoredBox(
        color: AppColors.bw800,
        child: Icon(Icons.broken_image, color: AppColors.bw600),
      ),
    );
  }
}
