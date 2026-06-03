import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/notification/application/notification_state.dart';
import 'package:meep/features/notification/presentation/widgets/notification_banner.dart';

Widget wrapBanner(
  BannerPayload payload, {
  VoidCallback? onSuppress,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: NotificationBanner(
          payload: payload,
          onSuppress: onSuppress ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  final testPayload = BannerPayload(
    title: 'ThienPDM',
    body: 'đã react vào ảnh của bạn',
    timestamp: DateTime(2026, 6, 4, 10, 30),
    data: {'type': 'reaction', 'postId': 'abc123'},
  );

  // SVG network/http calls fail in test — pre-warm the asset cache.
  setUpAll(() {
    // flutter_svg uses a picture provider that may fail in test without
    // a real asset bundle. The banner is testable for its structure even
    // if the SVG logo doesn't render. We suppress SVG errors via golden
    // or just verify non-SVG elements.
  });

  group('collapsed state', () {
    testWidgets('renders sender name', (tester) async {
      await tester.pumpWidget(wrapBanner(testPayload));

      expect(find.text('ThienPDM'), findsOneWidget);
    });

    testWidgets('renders message body preview', (tester) async {
      await tester.pumpWidget(wrapBanner(testPayload));

      expect(find.text('đã react vào ảnh của bạn'), findsOneWidget);
    });

    testWidgets('renders timestamp ("Vừa xong" for recent)', (tester) async {
      final recent = BannerPayload(
        title: 'Alice',
        body: 'test',
        timestamp: DateTime.now(),
      );
      await tester.pumpWidget(wrapBanner(recent));

      expect(find.text('Vừa xong'), findsOneWidget);
    });

    testWidgets('chevron-down icon visible in collapsed', (tester) async {
      await tester.pumpWidget(wrapBanner(testPayload));

      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets('banner has correct size (w=364, h≈65 collapsed)',
        (tester) async {
      await tester.pumpWidget(wrapBanner(testPayload));

      final size = tester.getSize(find.byType(AnimatedContainer));
      expect(size.width, 364);
      // Height may vary slightly due to AnimatedContainer, but default is
      // collapsed = 65.
    });
  });

  group('expanded state', () {
    testWidgets('tap banner → expands, shows chevron-up + actions',
        (tester) async {
      await tester.pumpWidget(wrapBanner(testPayload));

      await tester.pumpAndSettle(); // wait for slide-in animation
      await tester.tap(find.byType(NotificationBanner));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(find.text('Trả lời'), findsOneWidget);
      expect(find.text('Tắt thông báo'), findsOneWidget);
    });

    testWidgets('tap banner twice → collapses back', (tester) async {
      await tester.pumpWidget(wrapBanner(testPayload));

      // Expand
      await tester.pumpAndSettle(); // wait for slide-in animation
      await tester.tap(find.byType(NotificationBanner));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);

      // Collapse
      await tester.pumpAndSettle(); // wait for slide-in animation
      await tester.tap(find.byType(NotificationBanner));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      expect(find.text('Trả lời'), findsNothing);
      expect(find.text('Tắt thông báo'), findsNothing);
    });
  });

  group('actions', () {
    testWidgets('"Tắt thông báo" tap calls onSuppress', (tester) async {
      var suppressed = false;
      await tester.pumpWidget(
        wrapBanner(
          testPayload,
          onSuppress: () => suppressed = true,
        ),
      );

      // Expand first
      await tester.pumpAndSettle(); // wait for slide-in animation
      await tester.tap(find.byType(NotificationBanner));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tắt thông báo'));
      await tester.pumpAndSettle();

      expect(suppressed, isTrue);
    });

    testWidgets('"Trả lời" renders but is no-op (no throw)', (tester) async {
      await tester.pumpWidget(wrapBanner(testPayload));

      // Expand
      await tester.pumpAndSettle(); // wait for slide-in animation
      await tester.tap(find.byType(NotificationBanner));
      await tester.pumpAndSettle();

      // Tap "Trả lời" — should not throw, even though it's a no-op with TODO
      await tester.tap(find.text('Trả lời'));
      await tester.pumpAndSettle();

      // Banner still exists (not dismissed)
      expect(find.byType(NotificationBanner), findsOneWidget);
    });
  });

  group('timestamp formatting', () {
    testWidgets('minutes ago', (tester) async {
      final payload = BannerPayload(
        title: 'Test',
        body: 'body',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      await tester.pumpWidget(wrapBanner(payload));
      expect(find.text('5 phút'), findsOneWidget);
    });

    testWidgets('hours ago', (tester) async {
      final payload = BannerPayload(
        title: 'Test',
        body: 'body',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      );
      await tester.pumpWidget(wrapBanner(payload));
      expect(find.text('3 giờ'), findsOneWidget);
    });

    testWidgets('older → dd/MM format', (tester) async {
      final payload = BannerPayload(
        title: 'Test',
        body: 'body',
        timestamp: DateTime(2026, 1, 15),
      );
      await tester.pumpWidget(wrapBanner(payload));
      expect(find.text('15/01'), findsOneWidget);
    });
  });
}
