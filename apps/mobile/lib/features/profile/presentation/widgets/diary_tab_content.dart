import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/diary/data/diary_entry.dart';
import 'package:meep/features/diary/presentation/widgets/diary_mood_card.dart';
import 'package:meep/features/profile/application/profile_diary_entries_provider.dart';

/// Diary tab trong ProfileScreen.
///
/// Hiển thị các public diary entries của profile owner. Own profile vẫn chỉ
/// hiện public entries ở tab này; danh sách đầy đủ nằm ở Diary module.
class DiaryTabContent extends ConsumerWidget {
  const DiaryTabContent({
    super.key,
    required this.uid,
    this.ownerActionsEnabled = true,
    this.itemCount,
  });

  final String uid;
  final bool ownerActionsEnabled;
  final int? itemCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(profileDiaryEntriesProvider(uid)).when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.bw100),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Không tải được nhật ký. Thử lại sau.',
                style: AppTextStyles.smRegular.copyWith(color: AppColors.bw500),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (entries) {
            final visibleEntries = itemCount == null
                ? entries
                : entries.take(itemCount!).toList(growable: false);
            if (visibleEntries.isEmpty) return const _EmptyDiaryState();
            return _DiaryGrid(
              entries: visibleEntries,
              ownerActionsEnabled: ownerActionsEnabled,
            );
          },
        );
  }
}

class _DiaryGrid extends StatelessWidget {
  const _DiaryGrid({
    required this.entries,
    required this.ownerActionsEnabled,
  });

  final List<DiaryEntry> entries;
  final bool ownerActionsEnabled;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(39, 0, 39, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 32,
        crossAxisSpacing: 32,
        childAspectRatio: 150.5 / 186,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return DiaryMoodCard(
          title: entry.moodCaption,
          date: _formatShortDate(entry.createdAt),
          mood: entry.moodTemplate,
          onTap: () => context.push(
            '/diary/${entry.entryId}',
            extra: <String, Object>{
              'ownerActionsEnabled': ownerActionsEnabled,
            },
          ),
        );
      },
    );
  }

  static String _formatShortDate(DateTime date) =>
      '${date.day} tháng ${date.month}';
}

class _EmptyDiaryState extends StatelessWidget {
  const _EmptyDiaryState();

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
