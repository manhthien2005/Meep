import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/shared/models/post.dart';
import 'package:meep/features/streak/presentation/widgets/calendar_day_cell.dart';
import 'package:meep/features/streak/presentation/widgets/streak_calendar.dart';

void main() {
  Post makePost(String id, DateTime createdAt) => Post(
        postId: id,
        authorId: 'uid-alice',
        authorName: 'Alice',
        imageUrl: 'https://cdn/$id.jpg',
        audienceType: AudienceType.all,
        createdAt: createdAt,
      );

  Widget host(Widget child, {double width = 330}) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: width, child: child),
          ),
        ),
      );

  testWidgets('header render đúng format "tháng MM YYYY"', (tester) async {
    await tester.pumpWidget(
      host(
        StreakCalendar(
          viewingMonth: DateTime(2026, 4),
          monthPosts: const [],
          today: DateTime(2026, 5, 22),
        ),
      ),
    );
    expect(find.text('tháng 04 2026'), findsOneWidget);
  });

  testWidgets('grid render 42 cells (6 rows × 7 cols)', (tester) async {
    await tester.pumpWidget(
      host(
        StreakCalendar(
          viewingMonth: DateTime(2026, 5),
          monthPosts: const [],
          today: DateTime(2026, 5, 22),
        ),
      ),
    );
    expect(find.byType(CalendarDayCell), findsNWidgets(42));
  });

  testWidgets('ngày có post → render CachedNetworkImage', (tester) async {
    final posts = [
      makePost('p1', DateTime(2026, 5, 10, 14)),
      makePost('p2', DateTime(2026, 5, 22, 8)),
    ];
    await tester.pumpWidget(
      host(
        StreakCalendar(
          viewingMonth: DateTime(2026, 5),
          monthPosts: posts,
          today: DateTime(2026, 5, 22),
        ),
      ),
    );
    expect(find.byType(CachedNetworkImage), findsNWidgets(2));
  });

  testWidgets('tap ngày có post → onTapDay fires với đúng index',
      (tester) async {
    int? tappedIndex;
    final posts = [
      makePost('p1', DateTime(2026, 5, 10, 14)),
      makePost('p2', DateTime(2026, 5, 22, 8)),
    ];
    await tester.pumpWidget(
      host(
        StreakCalendar(
          viewingMonth: DateTime(2026, 5),
          monthPosts: posts,
          today: DateTime(2026, 5, 22),
          onTapDay: (i) => tappedIndex = i,
        ),
      ),
    );
    final tappableCells = find.byWidgetPredicate(
      (w) => w is CalendarDayCell && w.imageUrl != null,
    );
    await tester.tap(tappableCells.first);
    expect(tappedIndex, isIn([0, 1]));
  });

  testWidgets('kéo phải→trái = swipePrev fires', (tester) async {
    var prevCalled = false;
    await tester.pumpWidget(
      host(
        StreakCalendar(
          viewingMonth: DateTime(2026, 5),
          monthPosts: const [],
          today: DateTime(2026, 5, 22),
          onSwipePrev: () => prevCalled = true,
        ),
      ),
    );
    final container = find.byType(StreakCalendar);
    await tester.fling(container, const Offset(-300, 0), 800);
    await tester.pumpAndSettle();
    expect(prevCalled, isTrue);
  });

  testWidgets('kéo trái→phải = swipeNext fires', (tester) async {
    var nextCalled = false;
    await tester.pumpWidget(
      host(
        StreakCalendar(
          viewingMonth: DateTime(2026, 5),
          monthPosts: const [],
          today: DateTime(2026, 5, 22),
          onSwipeNext: () => nextCalled = true,
        ),
      ),
    );
    final container = find.byType(StreakCalendar);
    await tester.fling(container, const Offset(300, 0), 800);
    await tester.pumpAndSettle();
    expect(nextCalled, isTrue);
  });

  testWidgets('calendar không overflow ở mobile widths phổ biến',
      (tester) async {
    for (final width in [320.0, 360.0, 430.0]) {
      await tester.pumpWidget(
        host(
          StreakCalendar(
            viewingMonth: DateTime(2026, 5),
            monthPosts: const [],
            today: DateTime(2026, 5, 22),
          ),
          width: width,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'width=$width');
    }
  });

  testWidgets('today highlight chỉ khi viewingMonth chứa today',
      (tester) async {
    // viewingMonth khác today's month → KHÔNG có ô isToday
    await tester.pumpWidget(
      host(
        StreakCalendar(
          viewingMonth: DateTime(2026, 3),
          monthPosts: const [],
          today: DateTime(2026, 5, 22),
        ),
      ),
    );
    final todayCells = find.byWidgetPredicate(
      (w) => w is CalendarDayCell && w.isToday,
    );
    expect(todayCells, findsNothing);
  });

  testWidgets('today highlight khi viewingMonth = today month', (tester) async {
    await tester.pumpWidget(
      host(
        StreakCalendar(
          viewingMonth: DateTime(2026, 5),
          monthPosts: const [],
          today: DateTime(2026, 5, 22),
        ),
      ),
    );
    final todayCells = find.byWidgetPredicate(
      (w) => w is CalendarDayCell && w.isToday,
    );
    expect(todayCells, findsOneWidget);
  });

  testWidgets('today no-post + onTapToday → tap fires CTA callback',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      var ctaCalled = false;
      await tester.pumpWidget(
        host(
          StreakCalendar(
            viewingMonth: DateTime(2026, 5),
            monthPosts: const [],
            today: DateTime(2026, 5, 22),
            onTapToday: () => ctaCalled = true,
          ),
        ),
      );
      final todayCell = find.byWidgetPredicate(
        (w) => w is CalendarDayCell && w.isToday,
      );
      await tester.tap(todayCell);
      expect(ctaCalled, isTrue);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Chụp khoảnh khắc hôm nay',
        ),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('today có post → tap mở photo detail (onTapDay), không CTA',
      (tester) async {
    var ctaCalled = false;
    int? tappedIndex;
    final posts = [makePost('p1', DateTime(2026, 5, 22, 14))];
    await tester.pumpWidget(
      host(
        StreakCalendar(
          viewingMonth: DateTime(2026, 5),
          monthPosts: posts,
          today: DateTime(2026, 5, 22),
          onTapDay: (i) => tappedIndex = i,
          onTapToday: () => ctaCalled = true,
        ),
      ),
    );
    final todayCell = find.byWidgetPredicate(
      (w) => w is CalendarDayCell && w.isToday,
    );
    await tester.tap(todayCell);
    expect(tappedIndex, 0);
    expect(ctaCalled, isFalse);
  });
}
