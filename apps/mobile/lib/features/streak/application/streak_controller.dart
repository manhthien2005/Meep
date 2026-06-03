import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/feed/data/post.dart';
import 'package:meep/features/streak/data/streak_repository.dart';

part 'streak_controller.freezed.dart';
part 'streak_controller.g.dart';

@freezed
class StreakState with _$StreakState {
  const factory StreakState({
    /// Posts của tháng đang xem (sort createdAt ASC).
    @Default([]) List<Post> monthPosts,

    /// Tất cả ngày đã post (local timezone, dedupe per day).
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

@Riverpod(keepAlive: true)
StreakRepository streakRepository(Ref ref) => throw UnimplementedError(
      'streakRepositoryProvider must be overridden — '
      'wire FirebaseStreakRepository in main.dart (TODO: ST/ST1/HanDHG)',
    );

@riverpod
class StreakController extends _$StreakController {
  @override
  StreakState build() {
    // TODO(ST/ST2/HanDHG): subscribe watchUserMonth, fetch allPostDates,
    // compute currentStreak. See docs/plans/2026-05-23-streak.md §ST2.
    return const StreakState();
  }

  /// Initialize: set viewingMonth = startOfCurrentMonthLocal, subscribe
  /// watchUserMonth, fetch getUserAllDates once, compute currentStreak.
  Future<void> init() {
    throw UnimplementedError('init — TODO: ST/ST2/HanDHG');
  }

  /// Decrement viewingMonth 1 tháng. currentStreak + allPostDates KHÔNG đổi.
  Future<void> swipePrev() {
    throw UnimplementedError('swipePrev — TODO: ST/ST2/HanDHG');
  }

  /// Increment viewingMonth 1 tháng. Early-return (no-op) nếu đang viewing
  /// tháng hiện tại — cap tại tháng hiện tại (UI bounce animation).
  Future<void> swipeNext() {
    throw UnimplementedError('swipeNext — TODO: ST/ST2/HanDHG');
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }
}
