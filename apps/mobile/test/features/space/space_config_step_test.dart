import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/space/presentation/widgets/space_config_step.dart';

void main() {
  group('SpaceConfigStep', () {
    Widget buildStep({
      String spaceName = '',
      String iconEmoji = '👥',
      String colorHex = '#BFD5FF',
      ValueChanged<String>? onNameChanged,
      void Function(String, String)? onPresetSelected,
      VoidCallback? onCustomIconTap,
      VoidCallback? onComplete,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SpaceConfigStep(
            spaceName: spaceName,
            iconEmoji: iconEmoji,
            colorHex: colorHex,
            onNameChanged: onNameChanged ?? (_) {},
            onPresetSelected: onPresetSelected ?? (_, __) {},
            onCustomIconTap: onCustomIconTap ?? () {},
            onComplete: onComplete ?? () {},
          ),
        ),
      );
    }

    void setTallSurface(WidgetTester tester) {
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    testWidgets('renders title + sections + presets', (tester) async {
      setTallSurface(tester);
      await tester.pumpWidget(buildStep());
      await tester.pumpAndSettle();

      expect(find.text('Cấu hình Space'), findsOneWidget);
      expect(find.text('Đặt tên cho Space'), findsOneWidget);
      expect(find.text('Space theme'), findsOneWidget);
      // 8 preset emoji + nút "+"
      expect(find.text('👨‍👩‍👧‍👦'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('complete button disabled when name empty', (tester) async {
      var completed = false;
      await tester.pumpWidget(buildStep(onComplete: () => completed = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hoàn tất'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(completed, isFalse);
    });

    testWidgets('complete button enabled when name filled', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        buildStep(spaceName: 'Meepsie', onComplete: () => completed = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hoàn tất'));
      await tester.pumpAndSettle();
      expect(completed, isTrue);
    });

    testWidgets('tap preset fires onPresetSelected with pair', (tester) async {
      String? emoji;
      String? color;
      await tester.pumpWidget(
        buildStep(
          onPresetSelected: (e, c) {
            emoji = e;
            color = c;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('❤️'));
      await tester.pumpAndSettle();
      expect(emoji, '❤️');
      expect(color, '#FFCFBF');
    });

    testWidgets('tap "+" fires onCustomIconTap', (tester) async {
      setTallSurface(tester);
      var tapped = false;
      await tester.pumpWidget(buildStep(onCustomIconTap: () => tapped = true));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('selected preset shows check badge', (tester) async {
      setTallSurface(tester);
      await tester.pumpWidget(
        buildStep(iconEmoji: '❤️', colorHex: '#FFCFBF'),
      );
      await tester.pumpAndSettle();

      // Badge checkmark hiện cho preset đang chọn
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
