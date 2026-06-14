import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/shared/widgets/app_glass_surface.dart';
import 'package:meep/shared/widgets/app_taskbar.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(home: Scaffold(body: Center(child: w)));

  void noop(TaskbarTab _) {}

  group('AppTaskbar — floating', () {
    testWidgets('renders 5 tab icons, no overflow', (tester) async {
      await tester.pumpWidget(
        wrap(AppTaskbar(activeTab: TaskbarTab.home, onTabSelected: noop)),
      );
      expect(find.byType(SvgPicture), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows pill indicator when a tab is active', (tester) async {
      await tester.pumpWidget(
        wrap(AppTaskbar(activeTab: TaskbarTab.home, onTabSelected: noop)),
      );
      expect(find.byType(AppGlassSurface), findsOneWidget);
      expect(find.byKey(const Key('taskbarPillIndicator')), findsOneWidget);
    });

    testWidgets('hides pill indicator when activeTab is null', (tester) async {
      await tester.pumpWidget(
        wrap(AppTaskbar(activeTab: null, onTabSelected: noop)),
      );
      expect(find.byKey(const Key('taskbarPillIndicator')), findsNothing);
    });

    testWidgets('tap on a tab fires onTabSelected with that tab',
        (tester) async {
      TaskbarTab? selected;
      await tester.pumpWidget(
        wrap(
          AppTaskbar(
            activeTab: TaskbarTab.home,
            onTabSelected: (tab) => selected = tab,
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Hồ sơ'));
      expect(selected, TaskbarTab.profile);
    });

    testWidgets('renders chat badge only when count > 0', (tester) async {
      await tester.pumpWidget(
        wrap(
          AppTaskbar(
            activeTab: TaskbarTab.home,
            onTabSelected: noop,
            chatBadgeCount: 3,
          ),
        ),
      );
      expect(find.byKey(const Key('taskbarChatBadge')), findsOneWidget);

      await tester.pumpWidget(
        wrap(
          AppTaskbar(
            activeTab: TaskbarTab.home,
            onTabSelected: noop,
          ),
        ),
      );
      expect(find.byKey(const Key('taskbarChatBadge')), findsNothing);
    });
  });

  group('AppTaskbar — embedded', () {
    testWidgets('renders 4 tabs + grid + upload (home ẩn), no overflow',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          AppTaskbar(
            activeTab: TaskbarTab.home,
            variant: TaskbarVariant.embedded,
            onTabSelected: noop,
          ),
        ),
      );
      // 4 icon (streak, space, chat, profile) + 2 nút phụ = 6 (home ẩn)
      expect(find.byType(SvgPicture), findsNWidgets(6));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows ring indicator (not pill) when active', (tester) async {
      await tester.pumpWidget(
        wrap(
          AppTaskbar(
            activeTab: TaskbarTab.home,
            variant: TaskbarVariant.embedded,
            onTabSelected: noop,
          ),
        ),
      );
      expect(find.byType(AppGlassSurface), findsOneWidget);
      expect(find.byKey(const Key('taskbarRingIndicator')), findsOneWidget);
      expect(find.byKey(const Key('taskbarPillIndicator')), findsNothing);
    });

    testWidgets('tap grid / upload fires their callbacks', (tester) async {
      var grid = false;
      var upload = false;
      await tester.pumpWidget(
        wrap(
          AppTaskbar(
            activeTab: TaskbarTab.home,
            variant: TaskbarVariant.embedded,
            onTabSelected: noop,
            onGridTap: () => grid = true,
            onUploadTap: () => upload = true,
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Lưới ảnh'));
      await tester.tap(find.bySemanticsLabel('Tải ảnh lên'));
      expect(grid, isTrue);
      expect(upload, isTrue);
    });

    testWidgets('tap on a tab fires onTabSelected', (tester) async {
      TaskbarTab? selected;
      await tester.pumpWidget(
        wrap(
          AppTaskbar(
            activeTab: TaskbarTab.home,
            variant: TaskbarVariant.embedded,
            onTabSelected: (tab) => selected = tab,
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Kỷ niệm'));
      expect(selected, TaskbarTab.streak);
    });
  });
}
