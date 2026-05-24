import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/feed/data/post.dart';

part 'streak_controller.freezed.dart';
part 'streak_controller.g.dart';

@freezed
class StreakState with _$StreakState {
  const factory StreakState({
    /// Posts for the currently-viewed month.
    @Default([]) List<Post> monthPosts,

    /// All post dates — used for streak calculation (client-side).
    @Default([]) List<DateTime> allPostDates,

    /// Month currently shown in the calendar.
    DateTime? viewingMonth,

    /// Consecutive day streak from today backwards.
    @Default(0) int currentStreak,

    /// Total posts ever.
    @Default(0) int totalMoments,
    @Default(false) bool isLoading,
  }) = _StreakState;
}

@riverpod
class StreakController extends _$StreakController {
  @override
  StreakState build() => const StreakState();

  Future<void> loadMonth(DateTime month) async {
    // TODO(ST/T1/TBD): load posts for month using PostRepository
    throw UnimplementedError('loadMonth — TODO: ST/T1/TBD');
  }

  Future<void> loadAllPostDates(String uid) async {
    // TODO(ST/T2/TBD): load all post dates for streak calculation
    throw UnimplementedError('loadAllPostDates — TODO: ST/T2/TBD');
  }
}
