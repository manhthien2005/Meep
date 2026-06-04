import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/notification/application/notification_state.dart';
import 'package:meep/features/notification/presentation/widgets/notification_banner.dart';

Widget wrapBanner(
  BannerPayload payload, {
  VoidCallback? onTap,
  VoidCallback? onSuppress,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: NotificationBanner(
          payload: payload,
          onTap: onTap ?? () {},
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

  group('render', () {
    testWidgets('renders sender name (title)', (tester) async {
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

    testWidgets('banner has correct size (w=364, h≈65)', (tester) async {
      await tester.pumpWidget(wrapBanner(testPayload));

      // Banner outer Container — drilled down via byType vì
      // SlideTransition + Container chain ổn định.
      final size = tester.getSize(find.byType(NotificationBanner));
      expect(size.width, 364);
      expect(size.height, 65);
    });
  });

  group('interactions', () {
    testWidgets('tap banner → onTap fires', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        wrapBanner(
          testPayload,
          onTap: () => tapped++,
        ),
      );

      await tester.pumpAndSettle(); // wait for slide-in animation
      await tester.tap(find.byType(NotificationBanner));
      await tester.pumpAndSettle();

      expect(tapped, 1);
    });

    testWidgets('long-press banner → onSuppress fires (not onTap)',
        (tester) async {
      var tapped = 0;
      var suppressed = 0;
      await tester.pumpWidget(
        wrapBanner(
          testPayload,
          onTap: () => tapped++,
          onSuppress: () => suppressed++,
        ),
      );

      await tester.pumpAndSettle();
      await tester.longPress(find.byType(NotificationBanner));
      await tester.pumpAndSettle();

      expect(suppressed, 1);
      expect(tapped, 0);
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
