import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/diary/application/diary_controller.dart';
import 'package:meep/features/diary/data/diary_content_block.dart';
import 'package:meep/features/diary/data/diary_entry.dart';
import 'package:meep/features/diary/presentation/diary_canvas_screen.dart';
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
class DiarySearchScreen extends ConsumerStatefulWidget {
  const DiarySearchScreen({super.key});

  @override
  ConsumerState<DiarySearchScreen> createState() => _DiarySearchScreenState();
}

class _DiarySearchScreenState extends ConsumerState<DiarySearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  /// Filter advanced — mood multi-select + date range. Default empty.
  DiaryFilterValue _filter = const DiaryFilterValue();

  /// Debounce timer cho input — fire `controller.searchEntries` sau 300ms
  /// kể từ lần gõ cuối (tránh spam Firestore read khi user gõ nhanh).
  Timer? _debounce;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
    // Autofocus + bật keyboard ngay khi mở.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// On input change — re-render (clear button hiện/ẩn) + debounce fire
  /// `searchEntries(uid, query)`.
  void _onQueryChanged() {
    setState(() {}); // refresh clear button hiển thị
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, _fireSearch);
  }

  void _fireSearch() {
    final uid = ref.read(currentUidProvider).valueOrNull;
    if (uid == null) return;
    final query = _controller.text.trim();
    if (query.isEmpty) {
      // Empty query → skip Firestore round-trip, reset searchResults local.
      _resetSearchResults();
      return;
    }
    ref
        .read(diaryControllerProvider.notifier)
        .searchEntries(authorUid: uid, query: query);
  }

  /// Clear searchResults trong state mà không qua repo. Dùng khi query empty.
  void _resetSearchResults() {
    final notifier = ref.read(diaryControllerProvider.notifier);
    // Gọi searchEntries với uid không tồn tại sẽ tốn 1 read — tránh, set
    // trực tiếp qua public method. Controller hiện chưa có setSearchResults
    // nên dùng cách an toàn nhất: chỉ clear khi state đang có results.
    if (ref.read(diaryControllerProvider).searchResults.isNotEmpty) {
      notifier.clearSearchResults();
    }
  }

  /// Post-filter Firestore results với mood + date range (advanced filter).
  /// Query đã được Firestore filter ở repository (case-insensitive in-memory).
  List<DiaryEntry> _applyAdvancedFilter(List<DiaryEntry> entries) {
    final from = _filter.from;
    final to = _filter.to;
    return entries.where((e) {
      if (_filter.moods.isNotEmpty && !_filter.moods.contains(e.moodTemplate)) {
        return false;
      }
      if (from != null && e.createdAt.isBefore(from)) return false;
      if (to != null && e.createdAt.isAfter(to)) return false;
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
    final state = ref.watch(diaryControllerProvider);
    final results = _applyAdvancedFilter(state.searchResults);

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
  Widget _buildResultsList(List<DiaryEntry> results) {
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
        entry: results[i],
        query: _controller.text.trim(),
        onTap: () => _openCanvasRead(results[i]),
      ),
    );
  }

  /// Open Canvas read mode với entry — controller sẽ loadEntry qua initState.
  void _openCanvasRead(DiaryEntry entry) {
    // Lấy text content từ block đầu tiên dạng text (placeholder cho T9b
    // render đầy đủ block list).
    final firstText = entry.content.firstWhere(
      (b) => b.maybeWhen(text: (_, __) => true, orElse: () => false),
      orElse: () => const DiaryContentBlock.text(value: ''),
    );
    final textValue = firstText.maybeWhen(
      text: (value, _) => value,
      orElse: () => '',
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DiaryCanvasScreen(
          mode: DiaryCanvasMode.read,
          entryId: entry.entryId,
          moodTemplate: entry.moodTemplate,
          initialCaption: entry.moodCaption,
          initialContent: textValue,
          initialImageUrl:
              entry.coverImageUrl.isNotEmpty ? entry.coverImageUrl : null,
          entryDate: entry.createdAt,
        ),
      ),
    );
  }
}
