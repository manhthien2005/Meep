import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/public_profile.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/diary/application/diary_controller.dart';
import 'package:meep/features/diary/data/diary_content_block.dart';
import 'package:meep/features/diary/data/diary_entry.dart';
import 'package:meep/features/diary/data/diary_repository.dart';
import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/features/feed/data/firebase_post_repository.dart';
import 'package:meep/features/friend/application/friend_controller.dart';
import 'package:meep/features/friend/application/friend_state.dart';
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

class _FakeFriendController extends FriendController {
  _FakeFriendController(this._state);

  final FriendState _state;

  @override
  FriendState build(String uid) => _state;
}

class _FakeDiaryRepository implements DiaryRepository {
  _FakeDiaryRepository(this.entries);

  final List<DiaryEntry> entries;
  final requestedPublicUids = <String>[];

  @override
  Future<List<DiaryEntry>> getPublicEntries(String authorUid) async {
    requestedPublicUids.add(authorUid);
    return entries.where((e) => e.authorUid == authorUid).toList();
  }

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

  PublicProfile publicFriend(String uid) => PublicProfile(
        uid: uid,
        displayName: uid,
        username: uid,
        updatedAt: DateTime.utc(2026, 1, 1),
      );

  Widget makeApp({
    UserProfile? profile,
    String currentUid = 'uid-alice',
    List<PublicProfile> friends = const [],
    String routeUid = 'uid-alice',
    _FakeDiaryRepository? diaryRepository,
  }) {
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (_, __) => ProfileScreen(uid: routeUid),
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
        currentUidProvider.overrideWith((ref) => Stream.value(currentUid)),
        friendControllerProvider(currentUid).overrideWith(
          () => _FakeFriendController(FriendState(friends: friends)),
        ),
        profileRepositoryProvider
            .overrideWithValue(_FakeProfileRepository(profile)),
        postRepositoryProvider
            .overrideWithValue(FirebasePostRepository(firestore)),
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
    String authorUid = 'uid-alice',
  }) =>
      DiaryEntry(
        entryId: entryId,
        authorUid: authorUid,
        moodTemplate: MoodTemplate.happy,
        coverImageUrl: '',
        moodCaption: title,
        content: const [DiaryContentBlock.text(value: 'Public body')],
        privacy: DiaryPrivacy.public,
        createdAt: createdAt,
        updatedAt: createdAt,
      );

  testWidgets('renders displayName/bio/stats từ ProfileState + friend stream',
      (tester) async {
    await tester.pumpWidget(
      makeApp(
        profile: aliceProfile,
        friends: [publicFriend('friend-1'), publicFriend('friend-2')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('alice'), findsOneWidget); // username
    expect(find.text('Hello world'), findsOneWidget); // bio
    expect(find.text('7'), findsOneWidget); // postCount
    expect(find.text('2'), findsOneWidget); // friends.length
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

  testWidgets('Diary tab dùng effectiveUid và render public diary',
      (tester) async {
    final diaryRepository = _FakeDiaryRepository([
      diaryEntry(
        entryId: 'e-1',
        title: 'Một ngày vui',
        createdAt: DateTime.utc(2026, 5, 22),
      ),
    ]);

    await tester.pumpWidget(
      makeApp(
        profile: aliceProfile,
        routeUid: '',
        diaryRepository: diaryRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Tab nhật ký'));
    await tester.pumpAndSettle();

    expect(diaryRepository.requestedPublicUids, contains('uid-alice'));
    expect(find.text('Một ngày vui'), findsOneWidget);
  });

  testWidgets('friendCount drift trên profile doc → hiển thị 0 khi stream rỗng',
      (tester) async {
    final driftProfile = aliceProfile.copyWith(friendCount: 1);
    await tester.pumpWidget(makeApp(profile: driftProfile));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsNothing);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('friendCount lấy từ friends stream khi có bạn', (tester) async {
    final driftProfile = aliceProfile.copyWith(friendCount: 1);
    await tester.pumpWidget(
      makeApp(
        profile: driftProfile,
        friends: [publicFriend('friend-1'), publicFriend('friend-2')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
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

  testWidgets('counter âm (Firestore drift) → clamp về 0 trên UI',
      (tester) async {
    // Task 4A: postCount âm do CF race / miss. Display layer clamp về 0 để
    // user không thấy "-1 Khoảnh khắc". Root cause fix ở Path C (PR riêng).
    final driftProfile = aliceProfile.copyWith(
      postCount: -2,
      friendCount: -1,
      spaceCount: 5,
    );
    await tester.pumpWidget(makeApp(profile: driftProfile));
    await tester.pumpAndSettle();

    expect(find.text('-2'), findsNothing);
    expect(find.text('-1'), findsNothing);
    expect(find.text('0'), findsNWidgets(2)); // postCount + friendCount
    expect(find.text('5'), findsOneWidget); // spaceCount giữ nguyên
  });
}
