import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/shared/widgets/app_back_button.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(home: Scaffold(body: w));

  group('AppBackButton', () {
    testWidgets('renders without overflow', (tester) async {
      await tester.pumpWidget(wrap(const AppBackButton()));
      expect(tester.takeException(), isNull);
    });

    // AppBackButton dùng Align(centerLeft) → widget chiếm full available width,
    // nhưng SVG icon bên trong vẫn là 40×40 và nằm ở góc trái.
    testWidgets('SVG icon là 40×40', (tester) async {
      await tester.pumpWidget(wrap(const AppBackButton()));
      final svgSize = tester.getSize(find.byType(SvgPicture));
      expect(svgSize.width, 40);
      expect(svgSize.height, 40);
    });

    testWidgets('tap fires custom callback', (tester) async {
      var tapped = false;
      await tester
          .pumpWidget(wrap(AppBackButton(onPressed: () => tapped = true)));
      // Tap trực tiếp vào SvgPicture (icon 40×40 ở góc trái)
      await tester.tap(find.byType(SvgPicture), warnIfMissed: false);
      expect(tapped, isTrue);
    });
  });
}
