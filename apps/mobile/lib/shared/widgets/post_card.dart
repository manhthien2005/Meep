import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_proportions.dart';
import 'package:meep/shared/models/post.dart';
import 'package:meep/shared/widgets/app_note_pill.dart';
import 'package:meep/shared/widgets/app_photo_frame.dart';
import 'package:meep/shared/widgets/dual_post_image.dart';

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
                ? DualPostImage(
                    key: ValueKey('post-card-dual-${post.postId}'),
                    backImageUrl: post.backImageUrl ?? '',
                    frontImageUrl: post.frontImageUrl ?? '',
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
