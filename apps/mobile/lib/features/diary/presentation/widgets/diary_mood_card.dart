import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/features/diary/data/diary_entry.dart';

/// Diary card cho **Grid view** trong DiaryListScreen.
///
/// Figma: `656:1831` → "Diary Mood" component instance.
/// Spec: `docs/specs/2026-05-23-diary.md` §`DiaryMoodCard`.
///
/// Layout (150.5×182px):
/// - Cover image (120×120, BoxFit.contain) — giữ shape gốc của mood asset
/// - Title (Nunito Bold 20px white, center)
/// - Date (Nunito SemiBold 14px BW600, center)
class DiaryMoodCard extends StatelessWidget {
  const DiaryMoodCard({
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

  static const _cardWidth = 150.5;
  static const _imageSize = 120.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title, $date',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: _cardWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cover image — giữ shape gốc của asset (mood đã có shape sẵn)
              SizedBox(
                width: _imageSize,
                height: _imageSize,
                child: Image.asset(
                  'assets/icons/bg_${mood.name}.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 9),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bw100, // #F9FCFC
                  height: 28 / 20,
                ),
              ),
              const SizedBox(height: 4),

              // Date
              Text(
                date,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.bw600, // #656C6D
                  height: 18 / 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
