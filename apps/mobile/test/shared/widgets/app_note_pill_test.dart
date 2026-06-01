import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/core/theme/app_proportions.dart';
import 'package:meep/shared/widgets/app_note_pill.dart';

void main() {
  // Phone-sized surface so pillWidth resolves to the Figma ~200px target.
  Widget wrap(Widget w) => MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(412, 917)),
          child: Scaffold(body: Center(child: w)),
        ),
      );

  group('AppNotePill', () {
    testWidgets('editable text field is center-aligned', (tester) async {
      await tester.pumpWidget(wrap(const AppNotePill(text: '')));
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textAlign, TextAlign.center);
    });

    testWidgets('pill has fixed width from proportions', (tester) async {
      await tester.pumpWidget(wrap(const AppNotePill(text: '')));
      final size = tester.getSize(
        find
            .descendant(
              of: find.byType(AppNotePill),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(size.width, closeTo(AppProportions.pillWidth(412), 0.5));
    });

    testWidgets('width is independent of text length', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppNotePill(text: 'A very long caption that would overflow'),
        ),
      );
      final size = tester.getSize(
        find
            .descendant(
              of: find.byType(AppNotePill),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(size.width, closeTo(AppProportions.pillWidth(412), 0.5));
    });
  });
}
