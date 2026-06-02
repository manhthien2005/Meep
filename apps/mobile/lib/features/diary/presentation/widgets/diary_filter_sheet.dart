import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/features/diary/data/diary_entry.dart';

part 'diary_filter_sheet_mood_grid.dart';
part 'diary_filter_sheet_date_row.dart';
part 'diary_filter_sheet_actions.dart';

/// Filter giá trị được người dùng chọn — return từ `DiaryFilterSheet.show`.
///
/// `moods` rỗng = không lọc theo mood. `from`/`to` null = không lọc đầu/cuối.
class DiaryFilterValue {
  const DiaryFilterValue({
    this.moods = const <MoodTemplate>{},
    this.from,
    this.to,
  });

  final Set<MoodTemplate> moods;
  final DateTime? from;
  final DateTime? to;
}

/// Diary Filter Sheet — bottom sheet "Tìm kiếm nâng cao".
///
/// Figma: `712:4420` (Tùy chọn lọc). Sheet bg BW800, drag handle top,
/// 3 section: Biểu tượng (mood multi-select), Từ (date pickers),
/// Đến (date pickers), button "Lọc" bottom.
///
/// Usage:
/// ```dart
/// final picked = await DiaryFilterSheet.show(context, initial: _filter);
/// if (picked != null) setState(() => _filter = picked);
/// ```
class DiaryFilterSheet extends StatefulWidget {
  /// Hiện sheet. Resolve = giá trị user tap "Lọc"; null nếu dismiss scrim.
  static Future<DiaryFilterValue?> show(
    BuildContext context, {
    DiaryFilterValue? initial,
  }) {
    return showModalBottomSheet<DiaryFilterValue>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => DiaryFilterSheet(initial: initial),
    );
  }

  const DiaryFilterSheet({super.key, this.initial});

  final DiaryFilterValue? initial;

  @override
  State<DiaryFilterSheet> createState() => _DiaryFilterSheetState();
}

class _DiaryFilterSheetState extends State<DiaryFilterSheet> {
  late Set<MoodTemplate> _moods;
  int? _fromDay, _fromMonth, _fromYear;
  int? _toDay, _toMonth, _toYear;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _moods = {...?init?.moods};
    final from = init?.from;
    if (from != null) {
      _fromDay = from.day;
      _fromMonth = from.month;
      _fromYear = from.year;
    }
    final to = init?.to;
    if (to != null) {
      _toDay = to.day;
      _toMonth = to.month;
      _toYear = to.year;
    }
  }

  /// Build DateTime từ 3 part — chỉ trả non-null khi đủ cả 3.
  DateTime? _composeDate(int? d, int? m, int? y) {
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  void _apply() {
    final value = DiaryFilterValue(
      moods: _moods,
      from: _composeDate(_fromDay, _fromMonth, _fromYear),
      to: _composeDate(_toDay, _toMonth, _toYear),
    );
    Navigator.of(context).pop(value);
  }

  /// Bỏ lọc nhanh — pop sheet ngay với value rỗng (list sẽ hiện toàn bộ).
  void _clearAll() {
    Navigator.of(context).pop(const DiaryFilterValue());
  }

  void _toggleMood(MoodTemplate t) {
    setState(() {
      _moods.contains(t) ? _moods.remove(t) : _moods.add(t);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sheet height = 669 trong Figma; dùng max ~73% screen height để
    // không che status bar. Padding bottom theo viewInsets cho keyboard.
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bw800,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              // Drag handle 55×6.34, BW600
              Container(
                width: 55,
                height: 6.34,
                decoration: BoxDecoration(
                  color: AppColors.bw600,
                  borderRadius: BorderRadius.circular(6.5),
                ),
              ),
              const SizedBox(height: 13),
              // Header
              const Text(
                'Tìm kiếm nâng cao',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bw100,
                  height: 30 / 24,
                ),
              ),
              const SizedBox(height: 33),
              // ── Sections (scrollable nếu màn nhỏ) ──
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel('Biểu tượng'),
                      const SizedBox(height: 14),
                      _MoodGrid(
                        selected: _moods,
                        onToggle: _toggleMood,
                      ),
                      const SizedBox(height: 45),
                      const _SectionLabel('Từ'),
                      const SizedBox(height: 4),
                      _DateRow(
                        day: _fromDay,
                        month: _fromMonth,
                        year: _fromYear,
                        onDayChanged: (v) => setState(() => _fromDay = v),
                        onMonthChanged: (v) => setState(() => _fromMonth = v),
                        onYearChanged: (v) => setState(() => _fromYear = v),
                      ),
                      const SizedBox(height: 10),
                      const _SectionLabel('Đến'),
                      const SizedBox(height: 4),
                      _DateRow(
                        day: _toDay,
                        month: _toMonth,
                        year: _toYear,
                        onDayChanged: (v) => setState(() => _toDay = v),
                        onMonthChanged: (v) => setState(() => _toMonth = v),
                        onYearChanged: (v) => setState(() => _toYear = v),
                      ),
                      const SizedBox(height: 42),
                      _FilterActions(onClear: _clearAll, onApply: _apply),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section label "Biểu tượng" / "Từ" / "Đến".
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.bw500,
        height: 18 / 14,
      ),
    );
  }
}
