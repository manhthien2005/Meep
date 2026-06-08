import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/shared/models/post.dart';
import 'package:meep/features/streak/application/streak_controller.dart';
import 'package:meep/features/streak/data/streak_repository.dart';
import 'package:meep/features/streak/presentation/streak_screen.dart';
import 'package:meep/features/streak/presentation/widgets/empty_state_overlay.dart';
import 'package:meep/features/streak/presentation/widgets/streak_calendar.dart';
import 'package:meep/features/streak/presentation/widgets/streak_stats_pill.dart';
import 'package:meep/shared/widgets/app_taskbar.dart';

class FakeStreakRepo implements StreakRepository {
  FakeStreakRepo({this.allDates = const [], this.monthPostsMap = const {}});

  final List<DateTime> allDates;
  final Map<DateTime, List<Post>> monthPostsMap;

  @override
  Future<List<DateTime>> getUserAllDates(String uid) async => allDates;

  @override
  Stream<List<Post>> watchUserMonth(String uid, DateTime month) {
    final key = DateTime(month.year, month.month);
    return Stream.value(monthPostsMap[key] ?? const []);
  }
}

UserProfile fakeProfile({int postCount = 0, String? avatar}) => UserProfile(
      uid: 'uid-alice',
      email: 'a@b.com',
      displayName: 'Alice Doe',
      username: 'alice',
      avatarUrl: avatar,
      postCount: postCount,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

Widget host({
  required FakeStreakRepo repo,
  String? uid = 'uid-alice',
  UserProfile? profile,
  DateTime? now,
}) {
  return ProviderScope(
    overrides: [
      streakRepositoryProvider.overrideWithValue(repo),
      // Sync Stream — emit value ngay lập tức trong cùng frame để
      // controller.init() đọc valueOrNull thấy uid non-null.
      currentUidProvider.overrideWith(
        (ref) async* {
          yield uid;
        },
      ),
      currentUserProfileProvider.overrideWith(
        (ref) async* {
          yield profile;
        },
      ),
      nowProvider.overrideWithValue(
        () => now ?? DateTime(2026, 5, 22, 14, 30),
      ),
    ],
    child: const MaterialApp(home: StreakScreen()),
  );
}

/// Helper: pump enough frames để init() chạy xong + stream emit.
Future<void> pumpUntilSettled(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('topbar render "Kỷ niệm" title', (tester) async {
    await tester.pumpWidget(
      host(repo: FakeStreakRepo(), profile: fakeProfile()),
    );
    await pumpUntilSettled(tester);
    expect(find.text('Kỷ niệm'), findsOneWidget);
  });

  testWidgets('empty state visible khi chưa có post nào', (tester) async {
    await tester.pumpWidget(
      host(repo: FakeStreakRepo(), profile: fakeProfile()),
    );
    await pumpUntilSettled(tester);

    expect(find.byType(EmptyStateOverlay), findsOneWidget);
    expect(
      find.text('Gửi khoảnh khắc đầu tiên của bạn tại Meep !'),
      findsOneWidget,
    );
    expect(find.byType(StreakArrowDown), findsOneWidget);
  });

  testWidgets('empty state ẩn khi có ít nhất 1 post', (tester) async {
    final now = DateTime(2026, 5, 22, 14, 30);
    await tester.pumpWidget(
      host(
        repo: FakeStreakRepo(
          allDates: [DateTime(2026, 5, 22)],
          monthPostsMap: {
            DateTime(2026, 5): [
              Post(
                postId: 'p1',
                authorId: 'uid-alice',
                authorName: 'Alice',
                imageUrl: 'https://cdn/p1.jpg',
                audienceType: AudienceType.all,
                createdAt: DateTime(2026, 5, 22, 8),
              ),
            ],
          },
        ),
        profile: fakeProfile(postCount: 1),
        now: now,
      ),
    );
    await pumpUntilSettled(tester);

    expect(find.byType(EmptyStateOverlay), findsNothing);
    expect(find.byType(StreakArrowDown), findsNothing);
  });

  testWidgets('calendar + pill stats luôn render', (tester) async {
    await tester.pumpWidget(
      host(repo: FakeStreakRepo(), profile: fakeProfile()),
    );
    await pumpUntilSettled(tester);

    expect(find.byType(StreakCalendar), findsOneWidget);
    expect(find.byType(StreakStatsPill), findsOneWidget);
  });

  testWidgets('pill render postCount từ UserProfile (denormalized)',
      (tester) async {
    await tester.pumpWidget(
      host(
        repo: FakeStreakRepo(),
        profile: fakeProfile(postCount: 42),
      ),
    );
    await pumpUntilSettled(tester);

    final pill = tester.widget<StreakStatsPill>(find.byType(StreakStatsPill));
    expect(pill.totalMoments, 42);
  });

  testWidgets('profile null (chưa load) → fallback allPostDates length',
      (tester) async {
    final now = DateTime(2026, 5, 22);
    await tester.pumpWidget(
      host(
        repo: FakeStreakRepo(
          allDates: [DateTime(2026, 5, 22), DateTime(2026, 5, 21)],
        ),
        profile: null,
        now: now,
      ),
    );
    await pumpUntilSettled(tester);

    final pill = tester.widget<StreakStatsPill>(find.byType(StreakStatsPill));
    expect(pill.totalMoments, 2);
  });

  // ── E2E: Taskbar wired ──────────────────────────────────────────────────

  testWidgets('Taskbar visible với active tab = streak', (tester) async {
    await tester.pumpWidget(
      host(repo: FakeStreakRepo(), profile: fakeProfile()),
    );
    await pumpUntilSettled(tester);

    final taskbar = tester.widget<AppTaskbar>(find.byType(AppTaskbar));
    expect(taskbar.activeTab, TaskbarTab.streak);
  });

  // Navigate từ Taskbar trong GoRouter — verify onTabSelected dispatch.
  // Chỉ test navigation logic, không test render màn destination (dest cần
  // providers module khác → out-of-scope).
  testWidgets('tap Taskbar home tab → navigate /home (không còn ở Streak)',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/streak',
      routes: [
        GoRoute(path: '/streak', builder: (_, __) => const StreakScreen()),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('HOME_MARKER')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          streakRepositoryProvider.overrideWithValue(FakeStreakRepo()),
          currentUidProvider.overrideWith((ref) async* {
            yield 'uid-alice';
          }),
          currentUserProfileProvider.overrideWith((ref) async* {
            yield fakeProfile();
          }),
          nowProvider.overrideWithValue(
            () => DateTime(2026, 5, 22),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpUntilSettled(tester);

    await tester.tap(find.bySemanticsLabel('Trang chủ'));
    await pumpUntilSettled(tester);

    expect(find.text('HOME_MARKER'), findsOneWidget);
  });

  testWidgets(
      'tap Taskbar streak tab khi đang ở /streak → no-op (vẫn ở Streak)',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/streak',
      routes: [
        GoRoute(path: '/streak', builder: (_, __) => const StreakScreen()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          streakRepositoryProvider.overrideWithValue(FakeStreakRepo()),
          currentUidProvider.overrideWith((ref) async* {
            yield 'uid-alice';
          }),
          currentUserProfileProvider.overrideWith((ref) async* {
            yield fakeProfile();
          }),
          nowProvider.overrideWithValue(
            () => DateTime(2026, 5, 22),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpUntilSettled(tester);

    // Tap streak tab (Semantics label "Kỷ niệm" trên Taskbar)
    // .last vì topbar title cũng có text "Kỷ niệm"
    await tester.tap(find.bySemanticsLabel('Kỷ niệm').last);
    await pumpUntilSettled(tester);

    // Vẫn ở StreakScreen
    expect(find.byType(StreakScreen), findsOneWidget);
  });
}
