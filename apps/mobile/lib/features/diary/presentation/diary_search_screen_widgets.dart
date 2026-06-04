part of 'diary_search_screen.dart';

/// Result card — bg BW800 + image 54×53 + keyword highlight + date.
class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.entry,
    required this.query,
    required this.onTap,
  });

  final DiaryEntry entry;
  final String query;
  final VoidCallback onTap;

  String get _dateFull =>
      '${entry.createdAt.day} tháng ${entry.createdAt.month} năm ${entry.createdAt.year}';

  String get _moodAsset => 'assets/icons/bg_${entry.moodTemplate.name}.png';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${entry.moodCaption}, $_dateFull',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 85,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.bw800,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Text column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _HighlightedTitle(text: entry.moodCaption, query: query),
                    const SizedBox(height: 4),
                    Text(
                      _dateFull,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.bw500,
                        height: 16 / 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Mood image thuần (không khung tròn — giữ shape gốc)
              SizedBox(
                width: 54,
                height: 53,
                child: Image.asset(_moodAsset, fit: BoxFit.contain),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Title với highlight keyword — phần khớp query có nền Info/800 #004CDF.
class _HighlightedTitle extends StatelessWidget {
  const _HighlightedTitle({required this.text, required this.query});

  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontFamily: 'Nunito',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.bw100,
      height: 22 / 16,
    );

    if (query.isEmpty) {
      return Text(text, style: baseStyle);
    }

    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final idx = lower.indexOf(q);
    if (idx < 0) return Text(text, style: baseStyle);

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          if (idx > 0) TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: const TextStyle(
              backgroundColor: AppColors.info800,
            ),
          ),
          if (idx + query.length < text.length)
            TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }
}

/// Close button — vòng tròn 60×60 BW800 + x icon BW100.
/// Figma `656:1960` (Button trong frame mood picker).
/// Tap → pop Search screen về Diary list.
class _SearchCloseButton extends StatelessWidget {
  const _SearchCloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Đóng tìm kiếm',
      button: true,
      child: Material(
        color: AppColors.bw800,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 60,
            height: 60,
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/ic_diary_close.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  AppColors.bw100,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge số filter active — chấm tròn turquoise500 ở góc filter icon.
/// Hiển thị 1 (chỉ mood) hoặc 2 (mood + date range).
class _FilterBadge extends StatelessWidget {
  const _FilterBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.turquoise500,
        // Border BW900 cùng màu background → tách badge khỏi icon stroke
        border: Border.all(color: AppColors.bw900, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.bw900,
          height: 1,
        ),
      ),
    );
  }
}
