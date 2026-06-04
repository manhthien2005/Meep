import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/streak/presentation/widgets/calendar_day_cell.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('isInMonth=false → spacer 37×35, không render gì',
      (tester) async {
    await tester.pumpWidget(
      host(const CalendarDayCell(isInMonth: false, isToday: false)),
    );
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byType(GestureDetector), findsNothing);
    expect(find.byType(DecoratedBox), findsNothing);
  });

  testWidgets('isInMonth + no post + no today → render dot 11×11',
      (tester) async {
    await tester.pumpWidget(
      host(const CalendarDayCell(isInMonth: true, isToday: false)),
    );
    expect(find.byType(CachedNetworkImage), findsNothing);
    // Dot là Container width: 11, height: 11 + decoration. Match Container
    // có width/height = 11 (constraints set qua Container shortcut).
    final dot = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.constraints?.maxWidth == 11 &&
          w.constraints?.maxHeight == 11,
    );
    expect(dot, findsAtLeast(1));
  });

  testWidgets('imageUrl non-null → render CachedNetworkImage', (tester) async {
    await tester.pumpWidget(
      host(
        const CalendarDayCell(
          isInMonth: true,
          isToday: false,
          imageUrl: 'https://cdn/p1.jpg',
        ),
      ),
    );
    expect(find.byType(CachedNetworkImage), findsOneWidget);
  });

  testWidgets('isToday=true → render outline border', (tester) async {
    await tester.pumpWidget(
      host(const CalendarDayCell(isInMonth: true, isToday: true)),
    );
    // CalendarDayCell wrap content trong Stack với DecoratedBox overlay
    // chứa Border. Tìm bất kỳ widget nào có border non-null.
    final hasBorder = find.byWidgetPredicate((w) {
      if (w is DecoratedBox) {
        final dec = w.decoration;
        return dec is BoxDecoration && dec.border != null;
      }
      if (w is Container) {
        final dec = w.decoration;
        return dec is BoxDecoration && dec.border != null;
      }
      return false;
    });
    expect(hasBorder, findsAtLeast(1));
  });

  testWidgets('onTap fire khi có post', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      host(
        CalendarDayCell(
          isInMonth: true,
          isToday: false,
          imageUrl: 'https://cdn/p1.jpg',
          onTap: () => tapped = true,
        ),
      ),
    );
    await tester.tap(find.byType(GestureDetector));
    expect(tapped, isTrue);
  });

  testWidgets('onTap null khi no post → không có GestureDetector wrapper',
      (tester) async {
    await tester.pumpWidget(
      host(const CalendarDayCell(isInMonth: true, isToday: false)),
    );
    // CalendarDayCell có GestureDetector chỉ khi onTap != null
    expect(find.byType(GestureDetector), findsNothing);
  });
}
