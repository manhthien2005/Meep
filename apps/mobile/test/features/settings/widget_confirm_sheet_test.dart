import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/settings/presentation/widget_confirm_sheet.dart';
import 'package:meep/features/widget/application/widget_data_service.dart';

UserProfile _profile({int friendCount = 15}) {
  return UserProfile(
    uid: 'user1',
    email: 'user1@test.com',
    displayName: 'Test',
    username: 'test',
    friendCount: friendCount,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

/// Controls what [WidgetDataService.requestPinAppWidget] returns in tests.
bool _mockPinSupported = true;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late final WidgetDataService testWidgetDataService;

  group('WidgetConfirmSheet', () {
    setUpAll(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('meep/widget'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'requestPinAppWidget') {
            return _mockPinSupported;
          }
          return null;
        },
      );

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      testWidgetDataService = WidgetDataService(prefs: prefs);
    });

    Widget harness() => ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith(
              (ref) => Stream<UserProfile?>.value(_profile()),
            ),
            widgetDataServiceProvider.overrideWith(
              (ref) => testWidgetDataService,
            ),
          ],
          child: MaterialApp(
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

    testWidgets(
      'tap [Thêm] với launcher hỗ trợ → đóng sheet + hiện toast thành công',
      (tester) async {
        _mockPinSupported = true;

        await openSheet(tester);

        await tester.tap(find.text('Thêm'));
        await tester.pumpAndSettle();

        expect(
          find.text('Đã thêm tiện ích vào màn hình chờ thành công!'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        // Toast tự đóng sau 3s.
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'tap [Thêm] với launcher không hỗ trợ → đóng sheet + hiện toast manual',
      (tester) async {
        _mockPinSupported = false;

        await openSheet(tester);

        await tester.tap(find.text('Thêm'));
        await tester.pumpAndSettle();

        expect(
          find.text('Launcher không hỗ trợ thêm tự động. Hãy giữ ở màn hình chờ → '
              'chọn Widget → chọn Meep.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        // Toast tự đóng sau 3s.
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
      },
    );
  });
}
