import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/settings/presentation/delete_account_dialog.dart';

void main() {
  group('DeleteAccountDialog', () {
    Widget harness() => MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => DeleteAccountDialog.show(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );

    Future<void> openStep1(WidgetTester tester) async {
      await tester.pumpWidget(harness());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('step 1 — confirm xoá tài khoản (nút đỏ "Xoá")',
        (tester) async {
      await openStep1(tester);

      expect(
        find.text('Bạn có chắc muốn xoá tài khoản này không?'),
        findsOneWidget,
      );
      expect(find.text('Xoá'), findsOneWidget);
      expect(find.text('Huỷ'), findsOneWidget);
    });

    testWidgets('step 1 confirm → step 2 re-auth (ô nhập mật khẩu)',
        (tester) async {
      await openStep1(tester);

      await tester.tap(find.text('Xoá'));
      await tester.pumpAndSettle();

      expect(find.text('Xác thực lại'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('step 2: mật khẩu rỗng + "Xác nhận" → hiện lỗi, không submit',
        (tester) async {
      await openStep1(tester);
      await tester.tap(find.text('Xoá'));
      await tester.pumpAndSettle();

      // Không nhập gì, bấm Xác nhận.
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
      // Dialog re-auth vẫn còn (không bị pop khi mật khẩu rỗng).
      expect(find.text('Xác thực lại'), findsOneWidget);
    });
  });
}
