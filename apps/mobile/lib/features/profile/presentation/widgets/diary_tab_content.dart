import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';

// MOCK DATA — xóa khi DiaryRepository.getPublicEntries(uid) được wire (TODO T8)
class _DiaryEntry {
  const _DiaryEntry({
    required this.title,
    required this.dateLabel,
    required this.colorIndex,
  });

  final String title;
  final String dateLabel;
  final int colorIndex;
}

const _kMockEntries = <_DiaryEntry>[
  _DiaryEntry(title: 'Happy!', dateLabel: '22 tháng 5', colorIndex: 0),
  _DiaryEntry(title: 'Tired', dateLabel: '20 tháng 5', colorIndex: 1),
  _DiaryEntry(title: 'Title nhật ký', dateLabel: '19 tháng 5', colorIndex: 2),
  _DiaryEntry(title: 'Đà lạt', dateLabel: '18 tháng 5', colorIndex: 3),
  _DiaryEntry(title: 'Thư giãn', dateLabel: '17 tháng 5', colorIndex: 4),
  _DiaryEntry(title: 'Bồn chồn', dateLabel: '15 tháng 5', colorIndex: 5),
];

const _kImageColors = <Color>[
  Color(0xFF4A6FA5),
  Color(0xFF6B8E75),
  Color(0xFF8E6B6B),
  Color(0xFF8E7F6B),
  Color(0xFF6B7F8E),
  Color(0xFF7B6B8E),
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
    final color = _kImageColors[entry.colorIndex % _kImageColors.length];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          entry.title,
          style: AppTextStyles.lgBold.copyWith(color: AppColors.bw100),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          entry.dateLabel,
          style: AppTextStyles.smSemiBold.copyWith(color: AppColors.bw600),
          textAlign: TextAlign.center,
        ),
      ],
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
    final color = _kImageColors[entry.colorIndex % _kImageColors.length];
    return SizedBox(
      height: 85,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.white, width: 2),
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
