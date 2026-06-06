import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/feed/data/post.dart';
import 'package:meep/features/streak/application/streak_controller.dart';
import 'package:meep/features/streak/data/streak_repository.dart';

/// Fake repo — controller test không touch Firestore.
class FakeStreakRepository implements StreakRepository {
  FakeStreakRepository({
    List<DateTime>? allDates,
    Map<DateTime, List<Post>>? monthPosts,
    this.shouldThrowOnGetAll = false,
    this.shouldThrowOnWatch = false,
  })  : _allDates = allDates ?? const [],
        _monthPosts = monthPosts ?? const {};

  final List<DateTime> _allDates;
  final Map<DateTime, List<Post>> _monthPosts;
  final bool shouldThrowOnGetAll;
  final bool shouldThrowOnWatch;

  int getAllCalls = 0;
  final List<DateTime> watchedMonths = [];

  @override
  Future<List<DateTime>> getUserAllDates(String uid) async {
    getAllCalls++;
    if (shouldThrowOnGetAll) throw Exception('boom');
    return _allDates;
  }

  @override
  Stream<List<Post>> watchUserMonth(String uid, DateTime month) {
    watchedMonths.add(month);
    if (shouldThrowOnWatch) {
      return Stream.error(Exception('watch-boom'));
    }
    final key = DateTime(month.year, month.month);
    return Stream.value(_monthPosts[key] ?? const []);
  }
}

Post makePost({
  String id = 'p1',
  required DateTime createdAt,
}) =>
    Post(
      postId: id,
      authorId: 'uid-alice',
      authorName: 'Alice',
      imageUrl: 'https://cdn/$id.jpg',
      audienceType: AudienceType.all,
      createdAt: createdAt,
    );

ProviderContainer makeContainer({
  required FakeStreakRepository repo,
  String? uid = 'uid-alice',
  DateTime? now,
}) {
  return ProviderContainer(
    overrides: [
      streakRepositoryProvider.overrideWithValue(repo),
      currentUidProvider.overrideWith(
        (ref) => Stream.value(uid),
      ),
      nowProvider.overrideWithValue(
        () => now ?? DateTime(2026, 5, 22, 14, 30),
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StreakController — initial state', () {
    test('default state: empty, isLoading=false, viewingMonth=null', () {
      final container = makeContainer(repo: FakeStreakRepository());
      addTearDown(container.dispose);

      final state = container.read(streakControllerProvider);
      expect(state.monthPosts, isEmpty);
      expect(state.allPostDates, isEmpty);
      expect(state.viewingMonth, isNull);
      expect(state.currentStreak, 0);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
    });
  });

  group('StreakController — init', () {
    test('load allPostDates + compute currentStreak + subscribe tháng hiện tại',
        () async {
      final now = DateTime(2026, 5, 22, 14, 30);
      final repo = FakeStreakRepository(
        allDates: [
          DateTime(2026, 5, 22),
          DateTime(2026, 5, 21),
          DateTime(2026, 5, 20),
        ],
        monthPosts: {
          DateTime(2026, 5): [
            makePost(id: 'p1', createdAt: DateTime(2026, 5, 10, 8)),
            makePost(id: 'p2', createdAt: DateTime(2026, 5, 22, 17)),
          ],
        },
      );
      final container = makeContainer(repo: repo, now: now);
      addTearDown(container.dispose);

      // Pre-warm currentUidProvider stream
      await container.read(currentUidProvider.future);
      await container.read(streakControllerProvider.notifier).init();
      // Wait stream subscription emit
      await Future<void>.delayed(Duration.zero);

      final state = container.read(streakControllerProvider);
      expect(state.viewingMonth, DateTime(2026, 5));
      // allPostDates được merge từ stream → 3 (init) + 1 (May 10 từ monthPosts) = 4
      expect(state.allPostDates.length, 4);
      expect(state.currentStreak, 3);
      expect(state.monthPosts.length, 2);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
      expect(repo.getAllCalls, 1);
      expect(repo.watchedMonths, [DateTime(2026, 5)]);
    });

    test('uid null → errorMessage, không gọi repo', () async {
      final repo = FakeStreakRepository();
      final container = makeContainer(repo: repo, uid: null);
      addTearDown(container.dispose);

      await container.read(currentUidProvider.future);
      await container.read(streakControllerProvider.notifier).init();

      final state = container.read(streakControllerProvider);
      expect(state.errorMessage, contains('đăng nhập'));
      expect(repo.getAllCalls, 0);
    });

    test('getUserAllDates throw → errorMessage set, isLoading false', () async {
      final repo = FakeStreakRepository(shouldThrowOnGetAll: true);
      final container = makeContainer(repo: repo);
      addTearDown(container.dispose);

      await container.read(currentUidProvider.future);
      await container.read(streakControllerProvider.notifier).init();

      final state = container.read(streakControllerProvider);
      expect(state.isLoading, false);
      expect(state.errorMessage, 'Không thể tải Kỷ niệm');
    });
  });

  group('StreakController — swipePrev', () {
    test('viewingMonth - 1, monthPosts reset, currentStreak KHÔNG đổi',
        () async {
      final now = DateTime(2026, 5, 22);
      final repo = FakeStreakRepository(
        allDates: [DateTime(2026, 5, 22)],
        monthPosts: {
          DateTime(2026, 5): [
            makePost(id: 'p-may', createdAt: DateTime(2026, 5, 10)),
          ],
          DateTime(2026, 4): [
            makePost(id: 'p-apr', createdAt: DateTime(2026, 4, 15)),
          ],
        },
      );
      final container = makeContainer(repo: repo, now: now);
      addTearDown(container.dispose);

      await container.read(currentUidProvider.future);
      await container.read(streakControllerProvider.notifier).init();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(streakControllerProvider).currentStreak, 1);

      await container.read(streakControllerProvider.notifier).swipePrev();
      await Future<void>.delayed(Duration.zero);

      final state = container.read(streakControllerProvider);
      expect(state.viewingMonth, DateTime(2026, 4));
      expect(state.currentStreak, 1, reason: 'global, không đổi khi swipe');
      // allPostDates được merge từ stream: May 22 (init) + May 10 (stream May) + Apr 15 (stream April) = 3
      expect(state.allPostDates.length, 3);
      expect(state.monthPosts.length, 1);
      expect(state.monthPosts.first.postId, 'p-apr');
      expect(repo.watchedMonths, [DateTime(2026, 5), DateTime(2026, 4)]);
    });
  });

  group('StreakController — swipeNext (cap tại tháng hiện tại)', () {
    test('đang viewing tháng hiện tại → no-op, không gọi repo', () async {
      final now = DateTime(2026, 5, 22);
      final repo = FakeStreakRepository(
        monthPosts: {DateTime(2026, 5): const []},
      );
      final container = makeContainer(repo: repo, now: now);
      addTearDown(container.dispose);

      await container.read(currentUidProvider.future);
      await container.read(streakControllerProvider.notifier).init();
      await Future<void>.delayed(Duration.zero);
      final watchCountBefore = repo.watchedMonths.length;

      await container.read(streakControllerProvider.notifier).swipeNext();
      await Future<void>.delayed(Duration.zero);

      final state = container.read(streakControllerProvider);
      expect(state.viewingMonth, DateTime(2026, 5));
      expect(repo.watchedMonths.length, watchCountBefore);
    });

    test('đang viewing tháng cũ → tăng 1 tháng', () async {
      final now = DateTime(2026, 5, 22);
      final repo = FakeStreakRepository(
        monthPosts: {
          DateTime(2026, 5): const [],
          DateTime(2026, 4): const [],
        },
      );
      final container = makeContainer(repo: repo, now: now);
      addTearDown(container.dispose);

      await container.read(currentUidProvider.future);
      await container.read(streakControllerProvider.notifier).init();
      await container.read(streakControllerProvider.notifier).swipePrev();
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(streakControllerProvider).viewingMonth,
        DateTime(2026, 4),
      );

      await container.read(streakControllerProvider.notifier).swipeNext();
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(streakControllerProvider).viewingMonth,
        DateTime(2026, 5),
      );
    });
  });

  group('StreakController — clearError', () {
    test('errorMessage non-null → set null', () async {
      final repo = FakeStreakRepository(shouldThrowOnGetAll: true);
      final container = makeContainer(repo: repo);
      addTearDown(container.dispose);

      await container.read(currentUidProvider.future);
      await container.read(streakControllerProvider.notifier).init();
      expect(container.read(streakControllerProvider).errorMessage, isNotNull);

      container.read(streakControllerProvider.notifier).clearError();
      expect(container.read(streakControllerProvider).errorMessage, isNull);
    });

    test('errorMessage đã null → no-op', () {
      final container = makeContainer(repo: FakeStreakRepository());
      addTearDown(container.dispose);

      container.read(streakControllerProvider.notifier).clearError();
      expect(container.read(streakControllerProvider).errorMessage, isNull);
    });
  });
}
