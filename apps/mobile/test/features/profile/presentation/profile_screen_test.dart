import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/features/feed/data/firebase_post_repository.dart';
import 'package:meep/features/profile/application/profile_controller.dart';
import 'package:meep/features/profile/data/profile_repository.dart';
import 'package:meep/features/profile/presentation/profile_screen.dart';

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.profile);

  final UserProfile? profile;

  @override
  Future<UserProfile?> getUserProfile(String uid) async => profile;

  @override
  Stream<UserProfile?> watchUserProfile(String uid) => Stream.value(profile);

  @override
  Future<void> updateProfile(String uid, Map<String, dynamic> fields) async {}

  @override
  Future<void> updateAvatar(String uid, dynamic file) async {}

  @override
  Future<void> removeAvatar(String uid) async {}
}

void main() {
  late FakeFirebaseFirestore firestore;

  final aliceProfile = UserProfile(
    uid: 'uid-alice',
    email: 'alice@example.com',
    displayName: 'Alice Nguyen',
    username: 'alice',
    bio: 'Hello world',
    postCount: 7,
    friendCount: 12,
    spaceCount: 3,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  Widget makeApp({UserProfile? profile}) {
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (_, __) => const ProfileScreen(uid: 'uid-alice'),
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (_, __) =>
              const Scaffold(body: Text('EDIT_PROFILE_PLACEHOLDER')),
        ),
        GoRoute(
          path: '/streak',
          builder: (_, __) => const Scaffold(body: Text('STREAK_PLACEHOLDER')),
        ),
        GoRoute(
          path: '/diary',
          builder: (_, __) => const Scaffold(body: Text('DIARY_PLACEHOLDER')),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('HOME_PLACEHOLDER')),
        ),
        GoRoute(
          path: '/inbox',
          builder: (_, __) => const Scaffold(body: Text('INBOX_PLACEHOLDER')),
        ),
      ],
    );
    addTearDown(router.dispose);
    return ProviderScope(
      overrides: [
        profileRepositoryProvider
            .overrideWithValue(_FakeProfileRepository(profile)),
        postRepositoryProvider
            .overrideWithValue(FirebasePostRepository(firestore)),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('renders displayName/bio/stats từ ProfileState', (tester) async {
    await tester.pumpWidget(makeApp(profile: aliceProfile));
    await tester.pumpAndSettle();

    expect(find.text('alice'), findsOneWidget); // username
    expect(find.text('Hello world'), findsOneWidget); // bio
    expect(find.text('7'), findsOneWidget); // postCount
    expect(find.text('12'), findsOneWidget); // friendCount
    expect(find.text('3'), findsOneWidget); // spaceCount
    expect(find.text('Khoảnh khắc'), findsOneWidget);
    expect(find.text('Bạn bè'), findsOneWidget);
    expect(find.text('Space'), findsOneWidget);
  });

  testWidgets('không render bio khi null', (tester) async {
    final noBio = aliceProfile.copyWith(bio: null);
    await tester.pumpWidget(makeApp(profile: noBio));
    await tester.pumpAndSettle();
    expect(find.text('Hello world'), findsNothing);
  });

  testWidgets('không render bio khi empty string', (tester) async {
    final emptyBio = aliceProfile.copyWith(bio: '');
    await tester.pumpWidget(makeApp(profile: emptyBio));
    await tester.pumpAndSettle();
    expect(
      find.text(''),
      findsNothing,
      reason: 'empty bio không hiển thị Text widget',
    );
  });

  testWidgets('hiện error fallback khi profile null', (tester) async {
    await tester.pumpWidget(makeApp(profile: null));
    await tester.pumpAndSettle();
    expect(find.text('Không tải được hồ sơ'), findsOneWidget);
  });

  testWidgets('hiện "Chưa có ảnh nào" khi posts empty', (tester) async {
    await tester.pumpWidget(makeApp(profile: aliceProfile));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có ảnh nào'), findsOneWidget);
  });

  testWidgets('action button "Chỉnh sửa" navigate /profile/edit',
      (tester) async {
    await tester.pumpWidget(makeApp(profile: aliceProfile));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chỉnh sửa'));
    await tester.pumpAndSettle();

    expect(find.text('EDIT_PROFILE_PLACEHOLDER'), findsOneWidget);
  });

  testWidgets('avatar hiển thị initials khi avatarUrl null', (tester) async {
    await tester.pumpWidget(makeApp(profile: aliceProfile));
    await tester.pumpAndSettle();
    // username 'alice' single-word → first char 'A'
    expect(find.text('A'), findsOneWidget);
  });
}
