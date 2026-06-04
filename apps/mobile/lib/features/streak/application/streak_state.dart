import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:meep/features/feed/data/post.dart';

part 'streak_state.freezed.dart';

@freezed
class StreakState with _$StreakState {
  const factory StreakState({
    /// Posts của tháng đang xem (sort createdAt ASC).
    @Default([]) List<Post> monthPosts,

    /// Tất cả ngày đã post (local timezone, dedupe per day, sort DESC).
    /// Dùng cho `calculateStreak` + Calendar render dot ngày có post.
    @Default([]) List<DateTime> allPostDates,

    /// Tháng đang xem (startOfMonthLocal). Null = chưa init.
    DateTime? viewingMonth,

    /// Số ngày liên tiếp từ hôm nay trở về (toàn cục, không đổi khi swipe tháng).
    @Default(0) int currentStreak,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _StreakState;
}
