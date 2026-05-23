import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/settings/presentation/blocked_accounts_page.dart';

void main() {
  group('BlockedAccountsPage', () {
    Widget harness() => const MaterialApp(home: BlockedAccountsPage());

    testWidgets('hiện danh sách bị chặn, không overflow', (tester) async {
      await tester.pumpWidget(harness());

      expect(find.text('Tài khoản bị chặn'), findsOneWidget);
      expect(find.text('Lauren'), findsOneWidget);
      expect(find.text('Bỏ chặn'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap "Bỏ chặn" → hiện confirm dialog (state 3)',
        (tester) async {
      await tester.pumpWidget(harness());

      await tester.tap(find.text('Bỏ chặn'));
      await tester.pumpAndSettle();

      expect(
        find.text('Bạn có chắc muốn bỏ chặn tài khoản này không?'),
        findsOneWidget,
      );
      expect(find.text('Xác nhận'), findsOneWidget);
      expect(find.text('Huỷ'), findsOneWidget);
    });

    testWidgets('[Xác nhận] → xoá user, rỗng thì hiện empty state (state 1)',
        (tester) async {
      await tester.pumpWidget(harness());

      await tester.tap(find.text('Bỏ chặn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(find.text('Lauren'), findsNothing);
      expect(find.text('Không có tài khoản bị chặn nào'), findsOneWidget);
    });

    testWidgets('[Huỷ] → giữ nguyên danh sách', (tester) async {
      await tester.pumpWidget(harness());

      await tester.tap(find.text('Bỏ chặn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();

      expect(find.text('Lauren'), findsOneWidget);
      expect(find.text('Không có tài khoản bị chặn nào'), findsNothing);
    });
  });
}
