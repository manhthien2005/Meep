import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/chat/presentation/chat_time_format.dart';
import 'package:meep/shared/widgets/app_note_pill.dart';

/// The originating post shown at the top of a 1-1 thread that started from a
/// feed reply — square photo + caption pill + timestamp. Figma `564:6942`.
///
/// Caption pill dùng `AppNotePill` shared (readOnly) để khớp design system
/// với PostCard caption — không tự viết container.
class QuotedPhotoBlock extends StatelessWidget {
  const QuotedPhotoBlock({
    super.key,
    required this.imageUrl,
    required this.createdAt,
    this.caption,
  });

  final String imageUrl;
  final DateTime createdAt;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          formatQuotedPhotoTimestamp(createdAt),
          style: AppTextStyles.xsSemiBold.copyWith(color: AppColors.bw500),
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerLeft,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 301,
                  height: 301,
                  fit: BoxFit.cover,
                  // Cache hit (most cases) = instant render; cache miss =
                  // grey placeholder thay vì spinner để giảm flicker.
                  placeholder: (_, __) => Container(
                    width: 301,
                    height: 301,
                    color: AppColors.bw700,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 301,
                    height: 301,
                    color: AppColors.bw700,
                  ),
                ),
              ),
              if (caption != null && caption!.isNotEmpty)
                Positioned(
                  bottom: 15,
                  child: AppNotePill(text: caption!, readOnly: true),
                ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
