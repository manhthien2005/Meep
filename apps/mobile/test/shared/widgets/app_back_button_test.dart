import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/shared/widgets/app_back_button.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(home: Scaffold(body: w));

  group('AppBackButton', () {
    testWidgets('renders without overflow', (tester) async {
      await tester.pumpWidget(wrap(const AppBackButton()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('is 40×40', (tester) async {
      await tester.pumpWidget(wrap(const AppBackButton()));
      final size = tester.getSize(find.byType(AppBackButton));
      expect(size.width, 40);
      expect(size.height, 40);
    });

    testWidgets('tap fires custom callback', (tester) async {
      var tapped = false;
      await tester
          .pumpWidget(wrap(AppBackButton(onPressed: () => tapped = true)));
      await tester.tap(find.byType(AppBackButton));
      expect(tapped, isTrue);
    });
  });
}
