import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/settings/presentation/widget_confirm_sheet.dart';

void main() {
  group('WidgetConfirmSheet', () {
    Widget harness() => MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const WidgetConfirmSheet(),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );

    Future<void> openSheet(WidgetTester tester) async {
      await tester.pumpWidget(harness());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('render — tiêu đề + nút Thêm/Huỷ', (tester) async {
      await openSheet(tester);

      expect(find.text('Thêm vào màn hình chờ?'), findsOneWidget);
      expect(find.text('Thêm'), findsOneWidget);
      expect(find.text('Huỷ'), findsOneWidget);
    });

    testWidgets('tap [Thêm] → đóng sheet + hiện toast thành công',
        (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Thêm'));
      await tester.pump(); // đóng sheet + show toast dialog

      expect(
        find.text('Đã thêm tiện ích vào màn hình chờ thành công!'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      // Toast tự đóng sau 3s — đẩy timer cho hết để không leak pending timer.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });
  });
}
