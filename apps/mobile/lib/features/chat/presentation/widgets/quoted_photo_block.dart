import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/chat/presentation/chat_time_format.dart';

/// The originating post shown at the top of a 1-1 thread that started from a
/// feed reply — square photo + caption pill + timestamp. Figma `564:6942`.
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
                child: Image.network(
                  imageUrl,
                  width: 301,
                  height: 301,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 301,
                    height: 301,
                    color: AppColors.bw700,
                  ),
                ),
              ),
              if (caption != null && caption!.isNotEmpty)
                Positioned(
                  bottom: 15,
                  child: _CaptionPill(caption: caption!),
                ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

class _CaptionPill extends StatelessWidget {
  const _CaptionPill({required this.caption});

  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x66394041),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.text_fields, size: 18, color: AppColors.bw100),
          const SizedBox(width: 6),
          Text(
            caption,
            style: AppTextStyles.smSemiBold.copyWith(color: AppColors.bw100),
          ),
        ],
      ),
    );
  }
}
