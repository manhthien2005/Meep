import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/chat/presentation/chat_time_format.dart';

void main() {
  group('formatThreadSeparator', () {
    final now = DateTime(2026, 5, 30, 14, 30);

    test('same day → HH:mm', () {
      final time = DateTime(2026, 5, 30, 9, 5);
      expect(formatThreadSeparator(time, now: now), '09:05');
    });

    test('pads single-digit hour and minute', () {
      final time = DateTime(2026, 5, 30, 8, 7);
      expect(formatThreadSeparator(time, now: now), '08:07');
    });

    test('different day → DD thg M lúc HH:mm', () {
      final time = DateTime(2026, 4, 11, 14, 30);
      expect(formatThreadSeparator(time, now: now), '11 thg 4 lúc 14:30');
    });

    test('different year still uses day/month form', () {
      final time = DateTime(2025, 12, 31, 23, 59);
      expect(formatThreadSeparator(time, now: now), '31 thg 12 lúc 23:59');
    });
  });

  group('threadSeparatorGap', () {
    test('is 1 hour', () {
      expect(threadSeparatorGap, const Duration(hours: 1));
    });

    test('gap below threshold does not trigger (boundary 59m)', () {
      const gap = Duration(minutes: 59);
      expect(gap >= threadSeparatorGap, isFalse);
    });

    test('gap at threshold triggers (boundary 60m)', () {
      const gap = Duration(minutes: 60);
      expect(gap >= threadSeparatorGap, isTrue);
    });
  });
}
