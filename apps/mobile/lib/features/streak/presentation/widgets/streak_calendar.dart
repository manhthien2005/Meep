import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/shared/models/post.dart';
import 'package:meep/features/streak/presentation/widgets/calendar_day_cell.dart';

/// Custom calendar grid 7 cols × 6 rows. Match Figma `269:1990`.
///
/// - Container: cornerRadius 22, fill `#5857546e`
/// - Month header: bg `#8383836e`, "tháng MM YYYY" Inter SemiBold 14 white
/// - Cell: 37×35 cornerRadius 7, column gap 8, row gap 4
/// - Tuần bắt đầu CN (col 0 = Sunday) — match Figma layout
///
/// Swipe horizontal:
/// - Kéo phải→trái = swipePrev → tháng cũ hơn
/// - Kéo trái→phải = swipeNext → tháng mới hơn (controller cap tháng hiện tại)
class StreakCalendar extends StatelessWidget {
  const StreakCalendar({
    super.key,
    required this.viewingMonth,
    required this.monthPosts,
    required this.today,
    this.isLoading = false,
    this.onTapDay,
    this.onTapToday,
    this.onSwipePrev,
    this.onSwipeNext,
  });

  /// Start-of-month (year/month/1) đang xem.
  final DateTime viewingMonth;

  /// Posts thuộc tháng này, dùng để map day → coverImageUrl.
  /// Caller phải đảm bảo posts đều thuộc viewingMonth.
  final List<Post> monthPosts;

  /// Ngày hôm nay (local timezone) — dùng để highlight ô today.
  final DateTime today;

  /// Render skeleton cells trong lúc controller đang tải dữ liệu.
  final bool isLoading;

  /// Tap handler khi user tap ô có post. Receives index trong [monthPosts]
  /// (sort theo createdAt ASC). Null = no-op.
  final ValueChanged<int>? onTapDay;

  /// Tap handler cho ô today khi hôm nay chưa post (CTA turquoise + dấu cộng).
  /// Caller thường điều hướng về `/home` để mở camera. Null = ô today CTA
  /// không tappable.
  final VoidCallback? onTapToday;

  final VoidCallback? onSwipePrev;
  final VoidCallback? onSwipeNext;

  static const _columns = 7;
  static const _rows = 6;

  @override
  Widget build(BuildContext context) {
    // Map dayOfMonth → first post của ngày đó (1 post / ngày để render
    // thumbnail; nếu user post nhiều lần/ngày, hiển thị ảnh đầu tiên).
    // Index trong monthPosts dùng cho onTapDay callback.
    final Map<int, int> dayToPostIndex = {};
    for (var i = 0; i < monthPosts.length; i++) {
      final d = monthPosts[i].createdAt.toLocal();
      // Chỉ map ngày đầu tiên gặp — Streak tap → carousel open tại ảnh đó,
      // PhotoDetailScreen sẽ swipe qua các ảnh khác cùng ngày.
      dayToPostIndex.putIfAbsent(d.day, () => i);
    }

    final firstWeekday =
        DateTime(viewingMonth.year, viewingMonth.month).weekday;
    // Dart weekday: Mon=1...Sun=7. Convert sang Sun=0...Sat=6.
    final leadingEmpty = firstWeekday % 7;
    final daysInMonth =
        DateTime(viewingMonth.year, viewingMonth.month + 1, 0).day;

    final todayInMonth =
        today.year == viewingMonth.year && today.month == viewingMonth.month;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v < -200) {
          // Kéo phải→trái = tháng cũ hơn.
          onSwipePrev?.call();
        } else if (v > 200) {
          // Kéo trái→phải = tháng mới hơn.
          onSwipeNext?.call();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bw800.withValues(alpha: 0.74),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.bw700.withValues(alpha: 0.46),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final horizontalPadding = maxWidth < 330 ? 10.0 : 14.0;
            final columnGap = maxWidth < 330 ? 4.0 : 6.0;
            const rowGap = 6.0;
            final gridWidth = maxWidth - horizontalPadding * 2;
            final cellWidth =
                (gridWidth - columnGap * (_columns - 1)) / _columns;
            final cellHeight = (cellWidth * 0.92).clamp(30.0, 42.0);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MonthHeader(month: viewingMonth),
                const SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    12,
                  ),
                  child: _Grid(
                    leadingEmpty: leadingEmpty,
                    daysInMonth: daysInMonth,
                    todayDay: todayInMonth ? today.day : null,
                    dayToPostIndex: dayToPostIndex,
                    postsForDay: (day) {
                      final i = dayToPostIndex[day];
                      if (i == null) return null;
                      return monthPosts[i].coverImageUrl;
                    },
                    onTapDay: onTapDay,
                    onTapToday: onTapToday,
                    isLoading: isLoading,
                    cellWidth: cellWidth,
                    cellHeight: cellHeight.toDouble(),
                    columnGap: columnGap,
                    rowGap: rowGap,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bw700.withValues(alpha: 0.82),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      child: Text(
        _format(month),
        style: AppTextStyles.smSemiBold.copyWith(color: AppColors.bw100),
      ),
    );
  }

  String _format(DateTime month) {
    final mm = month.month.toString().padLeft(2, '0');
    return 'tháng $mm ${month.year}';
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.leadingEmpty,
    required this.daysInMonth,
    required this.todayDay,
    required this.dayToPostIndex,
    required this.postsForDay,
    required this.onTapDay,
    required this.onTapToday,
    required this.isLoading,
    required this.cellWidth,
    required this.cellHeight,
    required this.columnGap,
    required this.rowGap,
  });

  final int leadingEmpty;
  final int daysInMonth;
  final int? todayDay;
  final Map<int, int> dayToPostIndex;
  final String? Function(int day) postsForDay;
  final ValueChanged<int>? onTapDay;
  final VoidCallback? onTapToday;
  final bool isLoading;
  final double cellWidth;
  final double cellHeight;
  final double columnGap;
  final double rowGap;

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[];

    for (var i = 0; i < StreakCalendar._rows; i++) {
      final row = <Widget>[];
      for (var j = 0; j < StreakCalendar._columns; j++) {
        final slotIndex = i * StreakCalendar._columns + j;
        final dayNumber = slotIndex - leadingEmpty + 1;
        final isInMonth = dayNumber >= 1 && dayNumber <= daysInMonth;
        final url = isInMonth ? postsForDay(dayNumber) : null;
        final postIndex = isInMonth ? dayToPostIndex[dayNumber] : null;
        final isTodayCell = isInMonth && todayDay == dayNumber;
        // Priority: post → today CTA → no-op. Today cell có post vẫn mở
        // PhotoDetailScreen (postIndex non-null), chỉ today no-post mới CTA.
        final VoidCallback? tapHandler = postIndex != null
            ? () => onTapDay?.call(postIndex)
            : (isTodayCell ? onTapToday : null);

        row.add(
          CalendarDayCell(
            isInMonth: isInMonth,
            isToday: isTodayCell,
            imageUrl: url,
            onTap: tapHandler,
            isLoading: isLoading,
            width: cellWidth,
            height: cellHeight,
          ),
        );
        if (j < StreakCalendar._columns - 1) {
          row.add(SizedBox(width: columnGap));
        }
      }
      cells.add(Row(mainAxisSize: MainAxisSize.min, children: row));
      if (i < StreakCalendar._rows - 1) {
        cells.add(SizedBox(height: rowGap));
      }
    }

    return Column(mainAxisSize: MainAxisSize.min, children: cells);
  }
}
