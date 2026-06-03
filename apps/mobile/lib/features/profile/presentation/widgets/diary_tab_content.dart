import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';

/// Diary tab trong ProfileScreen.
///
/// M2 (issue #114): empty state — chưa wire `DiaryRepository.getPublicEntries`
/// vì Diary module T1 (`FirebaseDiaryRepository`) chưa done. Tab vẫn tappable
/// (không grayed out) theo spec.
///
/// M3: TODO khi Diary T1 merged — wire `DiaryRepository.getPublicEntries(uid)`
/// → `DiaryMoodCard` grid, tap card → `DiaryCanvasScreen(mode: read)`.
class DiaryTabContent extends StatelessWidget {
  const DiaryTabContent({super.key, this.itemCount});

  /// Reserved cho M3 wire — giới hạn số entry hiển thị. Hiện không dùng (M2
  /// empty state).
  final int? itemCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: AppColors.bw500.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có nhật ký công khai',
              style: AppTextStyles.mdSemiBold.copyWith(color: AppColors.bw300),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Nhật ký công khai sẽ hiển thị ở đây khi bạn (hoặc bạn bè) chia sẻ.',
              style: AppTextStyles.smRegular.copyWith(color: AppColors.bw500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
