import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/features/diary/data/diary_entry.dart';

/// Diary card cho **List view** trong DiaryListScreen.
///
/// Figma: `769:5917` → "Results" row instance (382×85px).
/// Layout horizontal:
/// - Cover image (66×66, left, BoxFit.contain — giữ shape gốc) + 18px gap
/// - Title (Nunito Bold 18px white, left)
/// - Date (Nunito Regular 12px BW500, left)
class DiaryListCard extends StatelessWidget {
  const DiaryListCard({
    super.key,
    required this.title,
    required this.date,
    required this.mood,
    this.onTap,
  });

  final String title;
  final String date;
  final MoodTemplate mood;
  final VoidCallback? onTap;

  static const _imageSize = 66.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title, $date',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              // Cover image — giữ shape gốc của mood asset
              SizedBox(
                width: _imageSize,
                height: _imageSize,
                child: Image.asset(
                  'assets/icons/bg_${mood.name}.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 18),

              // Title + date — căn trái, stack dọc
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.bw100, // #F9FCFC
                        height: 24 / 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.bw500, // #8D999B
                        height: 16 / 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
