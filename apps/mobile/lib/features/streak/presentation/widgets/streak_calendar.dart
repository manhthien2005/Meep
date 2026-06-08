import 'package:flutter/material.dart';

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
/// - Right→Left (drag end velocity > 0) = swipePrev → tháng cũ hơn
/// - Left→Right = swipeNext → tháng mới hơn (controller cap tại tháng hiện tại)
class StreakCalendar extends StatelessWidget {
  const StreakCalendar({
    super.key,
    required this.viewingMonth,
    required this.monthPosts,
    required this.today,
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

  /// Tap handler khi user tap ô có post. Receives index trong [monthPosts]
  /// (sort theo createdAt ASC). Null = no-op.
  final ValueChanged<int>? onTapDay;

  /// Tap handler cho ô today khi hôm nay chưa post (CTA turquoise + dấu cộng).
  /// Caller thường điều hướng về `/home` để mở camera. Null = ô today CTA
  /// không tappable.
  final VoidCallback? onTapToday;

  final VoidCallback? onSwipePrev;
  final VoidCallback? onSwipeNext;

  static const _bgFill = Color(0x6E585754);
  static const _headerFill = Color(0x6E838383);
  static const _columnGap = 8.0;
  static const _rowGap = 4.0;
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
          // swipe right→left = next month (controller cap)
          onSwipeNext?.call();
        } else if (v > 200) {
          // swipe left→right = prev month
          onSwipePrev?.call();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: _bgFill,
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MonthHeader(
              month: viewingMonth,
              fill: _headerFill,
            ),
            const SizedBox(height: 10),
            _Grid(
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
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month, required this.fill});

  final DateTime month;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      child: Text(
        _format(month),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFFFFFFFF),
          height: 17 / 14,
        ),
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
  });

  final int leadingEmpty;
  final int daysInMonth;
  final int? todayDay;
  final Map<int, int> dayToPostIndex;
  final String? Function(int day) postsForDay;
  final ValueChanged<int>? onTapDay;
  final VoidCallback? onTapToday;

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
          ),
        );
        if (j < StreakCalendar._columns - 1) {
          row.add(const SizedBox(width: StreakCalendar._columnGap));
        }
      }
      cells.add(Row(mainAxisSize: MainAxisSize.min, children: row));
      if (i < StreakCalendar._rows - 1) {
        cells.add(const SizedBox(height: StreakCalendar._rowGap));
      }
    }

    return Column(mainAxisSize: MainAxisSize.min, children: cells);
  }
}
