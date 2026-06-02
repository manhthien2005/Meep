import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/shared/widgets/app_note_pill.dart';

void main() {
  // Phone-sized surface so MediaQuery-driven font sizing is deterministic.
  Widget wrap(Widget w) => MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(412, 917)),
          child: Scaffold(body: Center(child: w)),
        ),
      );

  Size pillSize(WidgetTester tester) => tester.getSize(
        find
            .descendant(
              of: find.byType(AppNotePill),
              matching: find.byType(Container),
            )
            .first,
      );

  group('AppNotePill', () {
    testWidgets('editable text field is center-aligned', (tester) async {
      await tester.pumpWidget(wrap(const AppNotePill(text: '')));
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textAlign, TextAlign.center);
    });

    testWidgets('editable pill width is fixed at 40% of screen',
        (tester) async {
      // Screen is 412 in wrap(), so the editable pill (which has horizontal
      // padding around the 40% TextField) should be ≥ 0.40 * 412 ≈ 164.8 px
      // regardless of content length — the pill no longer hugs typed text.
      const screenW = 412.0;
      const expectedInner = screenW * AppNotePill.editableWidthRatio;

      await tester.pumpWidget(wrap(const AppNotePill(text: '')));
      await tester.pump();
      final emptyW = pillSize(tester).width;

      await tester.pumpWidget(
        wrap(const AppNotePill(text: 'a much longer caption here')),
      );
      await tester.pump();
      final longW = pillSize(tester).width;

      expect(emptyW, closeTo(longW, 0.5));
      expect(emptyW, greaterThanOrEqualTo(expectedInner));
    });

    testWidgets('enforces 30-char maxLength', (tester) async {
      await tester.pumpWidget(wrap(const AppNotePill(text: '')));
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.maxLength, AppNotePill.maxLength);
      expect(AppNotePill.maxLength, 30);
    });
  });
}
