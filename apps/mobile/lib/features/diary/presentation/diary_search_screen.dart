import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/features/diary/data/diary_entry.dart';
import 'package:meep/features/diary/presentation/widgets/diary_filter_sheet.dart';

part 'diary_search_screen_widgets.dart';

/// Diary Search Screen — full-text search trong entries của user.
///
/// Figma `712:4356` (Tìm kiếm Nhật ký).
/// Spec: `docs/specs/2026-05-23-diary.md`
///
/// Layout: search bar (BW700 bg) + filter icon → "N kết quả" label →
/// list result cards (54×53 image circular + keyword highlight + date).
/// Client-side filter (load all entries → filter in-memory).
class DiarySearchScreen extends StatefulWidget {
  const DiarySearchScreen({super.key});

  @override
  State<DiarySearchScreen> createState() => _DiarySearchScreenState();
}

class _DiarySearchScreenState extends State<DiarySearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  /// Filter advanced — mood multi-select + date range. Default empty.
  DiaryFilterValue _filter = const DiaryFilterValue();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    // Autofocus + bật keyboard ngay khi mở.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Filter mock results theo query (case-insensitive) + advanced filter
  /// (mood + date range).
  List<_MockResult> get _results {
    final query = _controller.text.trim().toLowerCase();
    final from = _filter.from;
    final to = _filter.to;
    return _mockResults.where((r) {
      // Query: match title hoặc preview
      if (query.isNotEmpty &&
          !r.title.toLowerCase().contains(query) &&
          !r.preview.toLowerCase().contains(query)) {
        return false;
      }
      // Mood filter: nếu có chọn, result phải thuộc set
      if (_filter.moods.isNotEmpty && !_filter.moods.contains(r.mood)) {
        return false;
      }
      // Date range: from/to inclusive theo day-precision
      if (from != null && r.date.isBefore(from)) return false;
      if (to != null && r.date.isAfter(to)) return false;
      return true;
    }).toList();
  }

  Future<void> _openFilter() async {
    final picked = await DiaryFilterSheet.show(context, initial: _filter);
    if (picked != null && mounted) setState(() => _filter = picked);
  }

  /// Số nhóm filter đang active — hiển thị làm badge trên filter icon.
  /// Mood (multi-select) tính là 1 nhóm; date range (from/to) tính 1 nhóm.
  /// Range: 0..2.
  int get _activeFilterCount {
    var count = 0;
    if (_filter.moods.isNotEmpty) count++;
    if (_filter.from != null || _filter.to != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return Scaffold(
      backgroundColor: AppColors.bw900, // #050F10
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchBar(),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  child: Text(
                    '${results.length} kết quả',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.bw100, // #F9FCFC (Figma fill #ffffff ~)
                      height: 28 / 20,
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                // Chừa 60px button + 24px margin dưới cho khu vực list cuộn.
                Expanded(child: _buildResultsList(results)),
                const SizedBox(height: 84),
              ],
            ),
          ),
          // Close button bottom-center — style Figma `656:1960`.
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _SearchCloseButton(
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar + filter icon ──
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 8, 12, 0),
      child: Row(
        children: [
          // Search input — BW700 bg, cornerRadius 15
          Expanded(
            child: Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: AppColors.bw700, // #394041
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_diary_search.svg',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      cursorColor: AppColors.turquoise500, // #00DEEE
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.bw100, // #F9FCFC
                        height: 24 / 18,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: 'Tìm nhật ký...',
                        hintStyle: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: AppColors.bw500, // #8D999B
                        ),
                      ),
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    Semantics(
                      label: 'Xóa',
                      button: true,
                      child: GestureDetector(
                        onTap: () => _controller.clear(),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.bw400, // #CED9DA
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 12,
                            color: AppColors.bw700, // #394041
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Filter icon — ngoài search bar; có badge số filter active
          const SizedBox(width: 8),
          Semantics(
            label: _activeFilterCount == 0
                ? 'Lọc'
                : 'Lọc, $_activeFilterCount bộ lọc đang áp dụng',
            button: true,
            child: InkWell(
              onTap: _openFilter,
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ic_diary_filter.svg',
                      width: 20,
                      height: 20,
                    ),
                    if (_activeFilterCount > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: _FilterBadge(count: _activeFilterCount),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Result cards list ──
  Widget _buildResultsList(List<_MockResult> results) {
    if (results.isEmpty) {
      return const Center(
        child: Text(
          '0 kết quả',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.bw500, // #8D999B
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _ResultCard(
        result: results[i],
        query: _controller.text.trim(),
      ),
    );
  }
}

// ── Mock data ──

class _MockResult {
  const _MockResult({
    required this.title,
    required this.preview,
    required this.date,
    required this.mood,
  });

  final String title;
  final String preview;
  final DateTime date;
  final MoodTemplate mood;

  /// "18 tháng 5 năm 2026" — derive từ date.
  String get dateFull => '${date.day} tháng ${date.month} năm ${date.year}';

  /// Asset path từ mood enum.
  String get moodAsset => 'assets/icons/bg_${mood.name}.png';
}

final _mockResults = <_MockResult>[
  _MockResult(
    title: 'Đà lạt',
    preview: 'Chuyến đi Đà Lạt cuối tuần đầy nắng',
    date: DateTime(2026, 5, 18),
    mood: MoodTemplate.happy,
  ),
  _MockResult(
    title: 'Mệt mỏi quá',
    preview: 'Hôm nay thật là một ngày dài',
    date: DateTime(2026, 5, 20),
    mood: MoodTemplate.tired,
  ),
  _MockResult(
    title: 'Buồn vu vơ',
    preview: 'Có những lúc chỉ muốn ở yên',
    date: DateTime(2026, 5, 19),
    mood: MoodTemplate.sad,
  ),
];
