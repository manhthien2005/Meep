import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/feed/data/post.dart';
import 'package:meep/features/streak/application/calculate_streak.dart';
import 'package:meep/features/streak/application/streak_state.dart';
import 'package:meep/features/streak/data/streak_repository.dart';

export 'package:meep/features/streak/application/streak_state.dart';

part 'streak_controller.g.dart';

@Riverpod(keepAlive: true)
StreakRepository streakRepository(Ref ref) => throw UnimplementedError(
      'streakRepositoryProvider must be overridden — '
      'wire FirebaseStreakRepository in main.dart (TODO: ST/ST1/HanDHG)',
    );

/// Inject `DateTime.now` để test deterministic. Override trong test
/// `nowProvider.overrideWithValue(() => fixedNow)`.
@Riverpod(keepAlive: true)
DateTime Function() now(Ref ref) => DateTime.now;

/// `keepAlive: true` để state survive cross route transitions (user navigate
/// Streak → Photo detail → back). Pattern AUTH #6 (keepAlive cho controllers
/// xuyên route).
@Riverpod(keepAlive: true)
class StreakController extends _$StreakController {
  StreamSubscription<List<Post>>? _monthSub;

  @override
  StreakState build() {
    ref.onDispose(() => _monthSub?.cancel());
    return const StreakState();
  }

  /// Load tháng hiện tại + allPostDates + compute currentStreak.
  ///
  /// Gọi từ `StreakScreen.initState` hoặc `ref.read(...notifier).init()` khi
  /// user mở Streak tab lần đầu.
  Future<void> init() async {
    // Use `.future` thay vì `.valueOrNull` để chờ Stream emit lần đầu.
    // valueOrNull return null nếu provider chưa subscribe → race condition
    // khi controller init trước UI watch currentUidProvider.
    final uid = await ref.read(currentUidProvider.future);
    if (uid == null) {
      state = state.copyWith(
        errorMessage: 'Bạn cần đăng nhập để xem Kỷ niệm',
      );
      return;
    }

    final nowLocal = ref.read(nowProvider)();
    final currentMonth = DateTime(nowLocal.year, nowLocal.month);
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      viewingMonth: currentMonth,
    );

    try {
      final repo = ref.read(streakRepositoryProvider);
      final allDates = await repo.getUserAllDates(uid);
      final streak = calculateStreak(allDates, nowLocal);
      state = state.copyWith(
        allPostDates: allDates,
        currentStreak: streak,
      );
      _subscribeMonth(uid, currentMonth);
    } catch (e) {
      state = _afterFailure(e);
    }
  }

  /// Decrement viewingMonth 1 tháng. Stream re-subscribe cho tháng mới.
  /// `currentStreak` + `allPostDates` KHÔNG đổi (toàn cục).
  Future<void> swipePrev() async {
    final current = state.viewingMonth;
    if (current == null) return; // chưa init
    final uid = await ref.read(currentUidProvider.future);
    if (uid == null) return;

    final prevMonth = DateTime(current.year, current.month - 1);
    state = state.copyWith(
      viewingMonth: prevMonth,
      monthPosts: const [],
      isLoading: true,
      errorMessage: null,
    );
    _subscribeMonth(uid, prevMonth);
  }

  /// Increment viewingMonth 1 tháng. Cap tại tháng hiện tại — early return.
  Future<void> swipeNext() async {
    final current = state.viewingMonth;
    if (current == null) return;
    final uid = await ref.read(currentUidProvider.future);
    if (uid == null) return;

    final nowLocal = ref.read(nowProvider)();
    final currentMonth = DateTime(nowLocal.year, nowLocal.month);

    // Cap: không vượt tháng hiện tại
    if (!current.isBefore(currentMonth)) return;

    final nextMonth = DateTime(current.year, current.month + 1);
    state = state.copyWith(
      viewingMonth: nextMonth,
      monthPosts: const [],
      isLoading: true,
      errorMessage: null,
    );
    _subscribeMonth(uid, nextMonth);
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  void _subscribeMonth(String uid, DateTime month) {
    _monthSub?.cancel();
    final repo = ref.read(streakRepositoryProvider);
    _monthSub = repo.watchUserMonth(uid, month).listen(
      (posts) {
        final nowLocal = ref.read(nowProvider)();
        final newDates = _extractDates(posts);
        final merged = _mergeDates(state.allPostDates, newDates);
        final streak = calculateStreak(merged, nowLocal);
        state = state.copyWith(
          monthPosts: posts,
          allPostDates: merged,
          currentStreak: streak,
          isLoading: false,
        );
      },
      onError: (Object e) {
        state = _afterFailure(e);
      },
    );
  }

  /// Extract unique days (local timezone) from a list of posts.
  List<DateTime> _extractDates(List<Post> posts) {
    final days = <DateTime>{};
    for (final p in posts) {
      final local = p.createdAt.toLocal();
      days.add(DateTime(local.year, local.month, local.day));
    }
    return days.toList();
  }

  /// Merge two date lists, deduplicate, sort DESC.
  List<DateTime> _mergeDates(
    List<DateTime> existing,
    List<DateTime> incoming,
  ) {
    final set = <DateTime>{};
    for (final d in existing) {
      set.add(DateTime(d.year, d.month, d.day));
    }
    for (final d in incoming) {
      set.add(DateTime(d.year, d.month, d.day));
    }
    final sorted = set.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  /// Reset isLoading + map error to message (pattern AUTH #4).
  StreakState _afterFailure(Object e) {
    final err = AppError.fromUnknown(e, fallback: 'Không thể tải Kỷ niệm');
    return state.copyWith(
      isLoading: false,
      errorMessage: err is OperationCancelledError ? null : err.message,
    );
  }
}
