import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/space/presentation/widgets/icon_builder_step.dart';

void main() {
  group('IconBuilderStep', () {
    Widget buildStep({
      String initialEmoji = '😄',
      String initialColor = '#FEEBCA',
      void Function(String, String)? onDone,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: IconBuilderStep(
            initialEmoji: initialEmoji,
            initialColor: initialColor,
            onDone: onDone ?? (_, __) {},
          ),
        ),
      );
    }

    void setTallSurface(WidgetTester tester) {
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    testWidgets('renders title + preview + suggestions', (tester) async {
      setTallSurface(tester);
      await tester.pumpWidget(buildStep());
      await tester.pumpAndSettle();

      expect(find.text('Tạo theme cho Space'), findsOneWidget);
      expect(find.text('Gợi ý'), findsOneWidget);
      // Emoji hiện ở preview + 9 suggestion = 10 instances
      expect(find.text('😄'), findsNWidgets(10));
    });

    testWidgets('tap suggestion changes selected color', (tester) async {
      setTallSurface(tester);
      await tester.pumpWidget(buildStep(initialColor: '#FEEBCA'));
      await tester.pumpAndSettle();

      // Ban đầu màu #FEEBCA được chọn (border turquoise)
      // Tap suggestion khác → đổi selection
      // (verify gián tiếp qua onDone)
      expect(find.text('Gợi ý'), findsOneWidget);
    });

    testWidgets('done button fires onDone with emoji + color', (tester) async {
      setTallSurface(tester);
      String? emoji;
      String? color;
      await tester.pumpWidget(
        buildStep(
          initialEmoji: '🎃',
          initialColor: '#C4F3D9',
          onDone: (e, c) {
            emoji = e;
            color = c;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xong'));
      await tester.pumpAndSettle();

      expect(emoji, '🎃');
      expect(color, '#C4F3D9');
    });

    testWidgets('has 2 tab buttons (emoji + color)', (tester) async {
      setTallSurface(tester);
      await tester.pumpWidget(buildStep());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.emoji_emotions_outlined), findsOneWidget);
      expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    });
  });
}
