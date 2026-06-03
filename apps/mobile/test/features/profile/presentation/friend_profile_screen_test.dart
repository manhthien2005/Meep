import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/firebase_auth_repository.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/features/feed/data/firebase_post_repository.dart';
import 'package:meep/features/friend/application/friend_controller.dart';
import 'package:meep/features/friend/data/firebase_friend_repository.dart';
import 'package:meep/features/profile/application/profile_controller.dart';
import 'package:meep/features/profile/data/profile_repository.dart';
import 'package:meep/features/profile/presentation/friend_profile_screen.dart';

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
  const currentUid = 'uid-alice';
  const friendUid = 'uid-bob';

  late FakeFirebaseFirestore firestore;

  final bobProfile = UserProfile(
    uid: friendUid,
    email: 'bob@example.com',
    displayName: 'Bob Tran',
    username: 'bob',
    bio: 'Hello from Bob',
    postCount: 5,
    friendCount: 8,
    spaceCount: 4,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  Future<void> seedFriendship() async {
    final lo = currentUid.compareTo(friendUid) < 0 ? currentUid : friendUid;
    final hi = currentUid.compareTo(friendUid) < 0 ? friendUid : currentUid;
    await firestore.doc('friendships/${lo}_$hi').set({
      'uid1': lo,
      'uid2': hi,
      'members': [lo, hi],
      'createdAt': Timestamp.now(),
    });
  }

  Widget makeApp({
    UserProfile? profile,
    bool seedFriend = true,
  }) {
    final mockAuth = MockFirebaseAuth(
      mockUser: MockUser(uid: currentUid),
      signedIn: true,
    );
    final router = GoRouter(
      initialLocation: '/friend-profile/$friendUid',
      routes: [
        GoRoute(
          path: '/friend-profile/:uid',
          builder: (_, state) =>
              FriendProfileScreen(uid: state.pathParameters['uid'] ?? ''),
        ),
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('HOME_PLACEHOLDER')),
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
        GoRoute(
          path: '/profile',
          builder: (_, __) => const Scaffold(body: Text('PROFILE_PLACEHOLDER')),
        ),
      ],
    );
    addTearDown(router.dispose);
    return ProviderScope(
      overrides: [
        authRepositoryProvider
            .overrideWithValue(FirebaseAuthRepository(auth: mockAuth)),
        profileRepositoryProvider
            .overrideWithValue(_FakeProfileRepository(profile)),
        postRepositoryProvider
            .overrideWithValue(FirebasePostRepository(firestore)),
        friendRepositoryProvider
            .overrideWithValue(FirebaseFriendRepository(firestore)),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('hiện gate khi chưa là bạn bè', (tester) async {
    await tester.pumpWidget(makeApp(profile: bobProfile, seedFriend: false));
    await tester.pumpAndSettle();
    expect(
      find.text('Bạn cần kết bạn để xem trang cá nhân này.'),
      findsOneWidget,
    );
  });

  testWidgets('render profile + stats sau khi là bạn bè', (tester) async {
    await seedFriendship();
    await tester.pumpWidget(makeApp(profile: bobProfile));
    await tester.pumpAndSettle();

    expect(find.text('bob'), findsOneWidget); // username
    expect(find.text('Hello from Bob'), findsOneWidget); // bio
    expect(find.text('5'), findsOneWidget); // postCount
    expect(find.text('8'), findsOneWidget); // friendCount
    expect(find.text('Khoảnh khắc'), findsOneWidget);
    expect(find.text('Bạn bè'), findsOneWidget);
  });

  testWidgets('KHÔNG hiển thị Space stat trên FriendProfile', (tester) async {
    await seedFriendship();
    await tester.pumpWidget(makeApp(profile: bobProfile));
    await tester.pumpAndSettle();
    expect(
      find.text('Space'),
      findsNothing,
      reason: 'Friend profile chỉ hiện Khoảnh khắc + Bạn bè',
    );
    expect(
      find.text('4'),
      findsNothing,
      reason: 'spaceCount=4 không nên render trong FriendProfile',
    );
  });

  testWidgets('action button "Nhắn tin" + "Chia sẻ trang cá nhân" hiển thị',
      (tester) async {
    await seedFriendship();
    await tester.pumpWidget(makeApp(profile: bobProfile));
    await tester.pumpAndSettle();
    expect(find.text('Nhắn tin'), findsOneWidget);
    expect(find.text('Chia sẻ trang cá nhân'), findsOneWidget);
  });

  testWidgets('empty posts → "Chưa có ảnh nào"', (tester) async {
    await seedFriendship();
    await tester.pumpWidget(makeApp(profile: bobProfile));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có ảnh nào'), findsOneWidget);
  });
}
