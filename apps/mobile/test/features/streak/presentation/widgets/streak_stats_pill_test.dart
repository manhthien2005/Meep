import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/streak/presentation/widgets/streak_stats_pill.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('render N Khoảnh khắc + Xd chuỗi', (tester) async {
    await tester.pumpWidget(
      host(const StreakStatsPill(totalMoments: 12, currentStreak: 7)),
    );
    final richText = tester.widget<RichText>(find.byType(RichText));
    final fullText = richText.text.toPlainText();
    expect(fullText, contains('12'));
    expect(fullText, contains('Khoảnh khắc'));
    expect(fullText, contains('7d'));
    expect(fullText, contains('chuỗi'));
  });

  testWidgets('0 moments + 0 streak vẫn render đúng', (tester) async {
    await tester.pumpWidget(
      host(const StreakStatsPill(totalMoments: 0, currentStreak: 0)),
    );
    final richText = tester.widget<RichText>(find.byType(RichText));
    final fullText = richText.text.toPlainText();
    expect(fullText, contains('0 Khoảnh khắc'));
    expect(fullText, contains('0d chuỗi'));
  });
}
