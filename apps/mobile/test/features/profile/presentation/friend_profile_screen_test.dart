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
import 'package:meep/features/diary/application/diary_controller.dart';
import 'package:meep/features/diary/data/diary_content_block.dart';
import 'package:meep/features/diary/data/diary_entry.dart';
import 'package:meep/features/diary/data/diary_repository.dart';
import 'package:meep/features/diary/presentation/diary_canvas_screen.dart';
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

class _FakeDiaryRepository implements DiaryRepository {
  _FakeDiaryRepository(this.entries);

  final List<DiaryEntry> entries;

  @override
  Future<List<DiaryEntry>> getPublicEntries(String authorUid) async =>
      entries.where((e) => e.authorUid == authorUid).toList();

  @override
  Stream<List<DiaryEntry>> watchEntries(String authorUid) =>
      Stream.value(entries.where((e) => e.authorUid == authorUid).toList());

  @override
  Future<DiaryEntry?> getEntry(String entryId) async {
    for (final entry in entries) {
      if (entry.entryId == entryId) return entry;
    }
    return null;
  }

  @override
  Future<List<DiaryEntry>> searchEntries({
    required String authorUid,
    required String query,
  }) async =>
      const [];

  @override
  String reserveEntryId() => 'reserved-id';

  @override
  Future<DiaryEntry> createEntry(DiaryEntry entry) async => entry;

  @override
  Future<void> updateEntry(DiaryEntry entry) async {}

  @override
  Future<void> updatePrivacy({
    required String entryId,
    required DiaryPrivacy privacy,
  }) async {}

  @override
  Future<void> deleteEntry(String entryId) async {}
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
    _FakeDiaryRepository? diaryRepository,
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
          path: '/diary/:entryId',
          builder: (_, state) {
            final extra = state.extra;
            final ownerActionsEnabled = extra is Map<String, dynamic>
                ? extra['ownerActionsEnabled'] as bool? ?? true
                : true;
            return DiaryCanvasScreen(
              mode: DiaryCanvasMode.read,
              entryId: state.pathParameters['entryId'],
              ownerActionsEnabled: ownerActionsEnabled,
            );
          },
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
        diaryRepositoryProvider.overrideWithValue(
          diaryRepository ?? _FakeDiaryRepository(const []),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  DiaryEntry diaryEntry({
    required String entryId,
    required String title,
    required DateTime createdAt,
  }) =>
      DiaryEntry(
        entryId: entryId,
        authorUid: friendUid,
        moodTemplate: MoodTemplate.happy,
        coverImageUrl: '',
        moodCaption: title,
        content: const [DiaryContentBlock.text(value: 'Friend public body')],
        privacy: DiaryPrivacy.public,
        createdAt: createdAt,
        updatedAt: createdAt,
      );

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

  testWidgets('Diary tab render public diary và mở read-only không owner menu',
      (tester) async {
    await seedFriendship();
    final diaryRepository = _FakeDiaryRepository([
      diaryEntry(
        entryId: 'e-friend',
        title: 'Nhật ký của Bob',
        createdAt: DateTime.utc(2026, 5, 22),
      ),
    ]);

    await tester.pumpWidget(
      makeApp(
        profile: bobProfile,
        diaryRepository: diaryRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Tab nhật ký'));
    await tester.pumpAndSettle();

    expect(find.text('Nhật ký của Bob'), findsOneWidget);

    await tester.tap(find.text('Nhật ký của Bob'));
    await tester.pumpAndSettle();

    expect(find.text('Friend public body'), findsOneWidget);
    expect(find.bySemanticsLabel('Tùy chọn'), findsNothing);
  });
}
