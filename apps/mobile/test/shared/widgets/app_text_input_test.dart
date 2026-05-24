import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/shared/widgets/app_text_input.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(home: Scaffold(body: Center(child: w)));

  group('AppTextInput', () {
    testWidgets('renders email hint', (tester) async {
      await tester.pumpWidget(
        wrap(const AppTextInput(inputType: AppTextInputType.email)),
      );
      expect(find.text('Địa chỉ email'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders username hint', (tester) async {
      await tester.pumpWidget(
        wrap(const AppTextInput(inputType: AppTextInputType.username)),
      );
      expect(find.text('Tên người dùng'), findsOneWidget);
    });

    testWidgets('shows error text', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppTextInput(
            inputType: AppTextInputType.email,
            status: AppTextInputStatus.error,
            errorText: 'Email không hợp lệ',
          ),
        ),
      );
      expect(find.text('Email không hợp lệ'), findsOneWidget);
    });

    testWidgets('no error text when status is normal', (tester) async {
      await tester.pumpWidget(
        wrap(const AppTextInput(inputType: AppTextInputType.email)),
      );
      expect(find.text('Email không hợp lệ'), findsNothing);
    });

    testWidgets('password toggle shows/hides text', (tester) async {
      await tester.pumpWidget(
        wrap(const AppTextInput(inputType: AppTextInputType.password)),
      );
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.obscureText, isTrue);
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();
      final tf2 = tester.widget<TextField>(find.byType(TextField));
      expect(tf2.obscureText, isFalse);
    });
  });
}
