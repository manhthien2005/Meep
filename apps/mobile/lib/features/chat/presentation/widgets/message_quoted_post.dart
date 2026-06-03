import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/shared/widgets/app_note_pill.dart';

/// Mini thumbnail card render phía trên 1 message reply post — pattern FB
/// story reply / Locket. Compact (max 200px wide) thay vì QuotedPhotoBlock
/// full 301x301 vì gắn per-message (có thể nhiều cards trong cùng thread).
///
/// Layout: ảnh vuông + caption pill (nếu có) overlay bottom — dùng cùng
/// `AppNotePill` shared widget với PostCard để consistent design system.
class MessageQuotedPost extends StatelessWidget {
  const MessageQuotedPost({
    super.key,
    required this.imageUrl,
    required this.isMine,
    this.caption,
  });

  final String imageUrl;
  final String? caption;

  /// True = align right (mine messages). False = align left (theirs).
  final bool isMine;

  /// Square thumbnail size — 1.5x baseline 180 = 270, đủ rõ post nhưng vẫn
  /// gọn so với full QuotedPhotoBlock (301).
  static const double _size = 270;

  /// Inset từ avatar column (40 avatar + 6 gap) cho align với bubble.
  static const double _theirsLeftInset = 46;

  @override
  Widget build(BuildContext context) {
    final card = Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(30),
          // Cached: nhiều messages reply cùng 1 post → tải 1 lần, các message
          // sau hiển thị instant. KHÔNG flash flicker khi cuộn thread dài.
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: _size,
            height: _size,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: _size,
              height: _size,
              color: AppColors.bw700,
            ),
            errorWidget: (_, __, ___) => Container(
              width: _size,
              height: _size,
              color: AppColors.bw700,
            ),
          ),
        ),
        if (caption != null && caption!.isNotEmpty)
          Positioned(
            bottom: 10,
            child: AppNotePill(text: caption!, readOnly: true),
          ),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(
        // Spacing dưới để gắn liền với bubble bên dưới (Locket pattern).
        bottom: 4,
        left: isMine ? 0 : _theirsLeftInset,
        right: isMine ? 0 : 0,
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: card,
      ),
    );
  }
}
