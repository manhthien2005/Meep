import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/shared/widgets/app_google_button.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(home: Scaffold(body: Center(child: w)));

  group('AppGoogleButton', () {
    testWidgets('renders without overflow', (tester) async {
      await tester.pumpWidget(wrap(const AppGoogleButton(onPressed: null)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows label text', (tester) async {
      await tester.pumpWidget(wrap(const AppGoogleButton(onPressed: null)));
      expect(find.text('Tiếp tục với Google'), findsOneWidget);
    });

    testWidgets('tap fires callback', (tester) async {
      var tapped = false;
      await tester
          .pumpWidget(wrap(AppGoogleButton(onPressed: () => tapped = true)));
      await tester.tap(find.byType(AppGoogleButton));
      expect(tapped, isTrue);
    });
  });
}
