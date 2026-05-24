import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/shared/widgets/app_primary_button.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(home: Scaffold(body: Center(child: w)));

  group('AppPrimaryButton', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(
        wrap(const AppPrimaryButton(label: 'Tiếp tục', onPressed: null)),
      );
      expect(find.text('Tiếp tục'), findsOneWidget);
    });

    testWidgets('no overflow', (tester) async {
      await tester.pumpWidget(
        wrap(const AppPrimaryButton(label: 'Tiếp tục', onPressed: null)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap fires callback when enabled', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          AppPrimaryButton(
            label: 'Tiếp tục',
            onPressed: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.byType(AppPrimaryButton));
      expect(tapped, isTrue);
    });

    testWidgets('tap disabled when onPressed null', (tester) async {
      final tapped = <bool>[];
      await tester.pumpWidget(
        wrap(const AppPrimaryButton(label: 'Tiếp tục', onPressed: null)),
      );
      await tester.tap(find.byType(AppPrimaryButton), warnIfMissed: false);
      expect(tapped, isEmpty);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppPrimaryButton(
            label: 'Tiếp tục',
            onPressed: null,
            isLoading: true,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Tiếp tục'), findsNothing);
    });
  });
}
