/// Pure function — số ngày liên tiếp post từ hôm nay trở về.
///
/// Quy ước (spec §Data model + §Timezone contract):
/// - [postDatesLocal]: danh sách ngày đã post, đã convert sang **local timezone**
///   và dedupe per day (caller responsibility — `FirebaseStreakRepository`).
/// - [nowLocal]: thời điểm hiện tại (local timezone). Inject để test deterministic.
///
/// Algorithm:
/// 1. Build dayKey set (year/month/day) từ [postDatesLocal]
/// 2. Bắt đầu từ today: nếu có trong set → +1, lùi 1 ngày
/// 3. Dừng khi gặp ngày không có trong set
///
/// Examples:
/// - `[today]` → 1
/// - `[today, yesterday, 2d ago]` → 3
/// - `[today, 3d ago]` → 1 (gap ở 2d/1d ago → đứt)
/// - `[]` → 0
/// - `[yesterday only]` (no today) → 0
int calculateStreak(List<DateTime> postDatesLocal, DateTime nowLocal) {
  final daySet =
      postDatesLocal.map((d) => DateTime(d.year, d.month, d.day)).toSet();
  int streak = 0;
  var day = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
  while (daySet.contains(day)) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}
