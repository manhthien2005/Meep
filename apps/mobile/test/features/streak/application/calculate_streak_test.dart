import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/streak/application/calculate_streak.dart';

void main() {
  final now = DateTime(2026, 5, 22, 14, 30); // any time of day — ignored

  DateTime daysAgo(int n) => DateTime(now.year, now.month, now.day - n);

  group('calculateStreak', () {
    test('[] → 0 (chưa có post nào)', () {
      expect(calculateStreak([], now), 0);
    });

    test('[today] → 1', () {
      expect(calculateStreak([daysAgo(0)], now), 1);
    });

    test('[today, yesterday, 2d ago] → 3', () {
      expect(
        calculateStreak([daysAgo(0), daysAgo(1), daysAgo(2)], now),
        3,
      );
    });

    test('[today, 3d ago] → 1 (gap đứt streak)', () {
      expect(calculateStreak([daysAgo(0), daysAgo(3)], now), 1);
    });

    test('[yesterday only] (no today) → 0', () {
      expect(calculateStreak([daysAgo(1)], now), 0);
    });

    test('duplicates same day → count 1 lần', () {
      // 3 posts cùng ngày → day set chỉ 1 entry → streak = 1
      final today = DateTime(now.year, now.month, now.day, 8);
      final today2 = DateTime(now.year, now.month, now.day, 14);
      final today3 = DateTime(now.year, now.month, now.day, 22);
      expect(calculateStreak([today, today2, today3], now), 1);
    });

    test('timezone: dates đã local — không drift khi date có hours/minutes',
        () {
      // Caller responsibility convert toLocal() trước. Fn này chỉ
      // care year/month/day. Test verify hours/minutes bị ignore.
      final todayMorning = DateTime(now.year, now.month, now.day, 6, 30);
      final yesterdayEvening =
          DateTime(now.year, now.month, now.day - 1, 23, 55);
      expect(
        calculateStreak([todayMorning, yesterdayEvening], now),
        2,
      );
    });
  });
}
