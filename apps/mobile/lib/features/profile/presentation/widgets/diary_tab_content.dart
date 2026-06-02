import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/diary/data/diary_entry.dart' show MoodTemplate;
import 'package:meep/features/diary/presentation/widgets/diary_mood_card.dart';

// MOCK DATA — xóa khi DiaryRepository.getPublicEntries(uid) được wire (TODO T8)
class _DiaryEntry {
  const _DiaryEntry({
    required this.title,
    required this.dateLabel,
    required this.mood,
  });

  final String title;
  final String dateLabel;
  final MoodTemplate mood;
}

const _kMockEntries = <_DiaryEntry>[
  _DiaryEntry(
    title: 'Happy!',
    dateLabel: '22 tháng 5',
    mood: MoodTemplate.happy,
  ),
  _DiaryEntry(
    title: 'Tired',
    dateLabel: '20 tháng 5',
    mood: MoodTemplate.tired,
  ),
  _DiaryEntry(
    title: 'Title nhật ký',
    dateLabel: '19 tháng 5',
    mood: MoodTemplate.bored,
  ),
  _DiaryEntry(
    title: 'Đà lạt',
    dateLabel: '18 tháng 5',
    mood: MoodTemplate.happy,
  ),
  _DiaryEntry(
    title: 'Thư giãn',
    dateLabel: '17 tháng 5',
    mood: MoodTemplate.shy,
  ),
  _DiaryEntry(
    title: 'Bồn chồn',
    dateLabel: '15 tháng 5',
    mood: MoodTemplate.sad,
  ),
];

class DiaryTabContent extends StatefulWidget {
  const DiaryTabContent({super.key, this.itemCount});

  /// Giới hạn số lượng entry hiển thị. Null = hiển thị tất cả.
  final int? itemCount;

  @override
  State<DiaryTabContent> createState() => _DiaryTabContentState();
}

class _DiaryTabContentState extends State<DiaryTabContent> {
  bool _isGrid = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DiaryHeader(
          isGrid: _isGrid,
          onToggle: () => setState(() => _isGrid = !_isGrid),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _isGrid
              ? _DiaryGrid(itemCount: widget.itemCount)
              : _DiaryList(itemCount: widget.itemCount),
        ),
      ],
    );
  }
}

// ─── Header row: "Tất cả" + toggle ───────────────────────────────────────────

class _DiaryHeader extends StatelessWidget {
  const _DiaryHeader({required this.isGrid, required this.onToggle});

  final bool isGrid;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            'Tất cả',
            style: AppTextStyles.mdSemiBold.copyWith(color: AppColors.bw500),
          ),
          const Spacer(),
          Semantics(
            button: true,
            label: isGrid ? 'Xem dạng danh sách' : 'Xem dạng lưới',
            child: GestureDetector(
              onTap: onToggle,
              child: SvgPicture.asset(
                isGrid
                    ? 'assets/icons/ic_grid_3x2.svg'
                    : 'assets/icons/ic_grip_horizontal.svg',
                width: 26,
                height: 26,
                colorFilter:
                    const ColorFilter.mode(AppColors.bw300, BlendMode.srcIn),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Grid view ────────────────────────────────────────────────────────────────

class _DiaryGrid extends StatelessWidget {
  const _DiaryGrid({this.itemCount});

  final int? itemCount;

  @override
  Widget build(BuildContext context) {
    final entries = itemCount != null
        ? _kMockEntries.take(itemCount!).toList()
        : _kMockEntries;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 13,
        mainAxisSpacing: 32,
        mainAxisExtent: 185,
      ),
      itemCount: entries.length,
      itemBuilder: (_, i) => _DiaryGridCard(entry: entries[i]),
    );
  }
}

class _DiaryGridCard extends StatelessWidget {
  const _DiaryGridCard({required this.entry});

  final _DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DiaryMoodCard(
        title: entry.title,
        date: entry.dateLabel,
        mood: entry.mood,
      ),
    );
  }
}

// ─── List view ────────────────────────────────────────────────────────────────

class _DiaryList extends StatelessWidget {
  const _DiaryList({this.itemCount});

  final int? itemCount;

  @override
  Widget build(BuildContext context) {
    final entries = itemCount != null
        ? _kMockEntries.take(itemCount!).toList()
        : _kMockEntries;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: entries.length,
      itemBuilder: (_, i) => _DiaryListRow(entry: entries[i]),
    );
  }
}

class _DiaryListRow extends StatelessWidget {
  const _DiaryListRow({required this.entry});

  final _DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 85,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            SizedBox(
              width: 65,
              height: 65,
              child: Image.asset(
                'assets/icons/bg_${entry.mood.name}.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 19),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.title,
                  // TODO: AppTextStyles.baseBold khi leader add 18px w700 vào app_text_styles.dart
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 24 / 18,
                    color: AppColors.bw100,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.dateLabel,
                  style:
                      AppTextStyles.xsRegular.copyWith(color: AppColors.bw500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
