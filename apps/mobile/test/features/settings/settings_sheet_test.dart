import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/settings/presentation/settings_sheet.dart';

void main() {
  group('SettingsSheet', () {
    Widget harness() =>
        const MaterialApp(home: Scaffold(body: SettingsSheet()));

    testWidgets('render — header username + các mục menu chính',
        (tester) async {
      await tester.pumpWidget(harness());

      // Header dùng mock username 'ngantran'.
      expect(find.text('ngantran'), findsOneWidget);
      expect(find.text('Tài khoản đã chặn'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsOneWidget);
      expect(find.text('Xoá tài khoản'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap "Đăng xuất" → hiện confirm dialog đăng xuất',
        (tester) async {
      await tester.pumpWidget(harness());

      await tester.ensureVisible(find.text('Đăng xuất'));
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();

      expect(find.text('Bạn có chắc bạn muốn đăng xuất?'), findsOneWidget);
    });

    testWidgets('tap "Xoá tài khoản" → hiện confirm dialog xoá (nút đỏ "Xoá")',
        (tester) async {
      await tester.pumpWidget(harness());

      await tester.ensureVisible(find.text('Xoá tài khoản'));
      await tester.tap(find.text('Xoá tài khoản'));
      await tester.pumpAndSettle();

      expect(
        find.text('Bạn có chắc muốn xoá tài khoản này không?'),
        findsOneWidget,
      );
      expect(find.text('Xoá'), findsOneWidget);
    });
  });
}
