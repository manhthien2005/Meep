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

    testWidgets('width grows with text length (hug content)', (tester) async {
      await tester.pumpWidget(wrap(const AppNotePill(text: '')));
      await tester.pump();
      final emptyW = pillSize(tester).width;

      await tester.pumpWidget(
        wrap(const AppNotePill(text: 'a much longer caption here')),
      );
      await tester.pump();
      final longW = pillSize(tester).width;

      expect(longW, greaterThan(emptyW));
    });

    testWidgets('enforces 30-char maxLength', (tester) async {
      await tester.pumpWidget(wrap(const AppNotePill(text: '')));
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.maxLength, AppNotePill.maxLength);
      expect(AppNotePill.maxLength, 30);
    });
  });
}
