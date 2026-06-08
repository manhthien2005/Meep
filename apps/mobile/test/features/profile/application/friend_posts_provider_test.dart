import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/firebase_auth_repository.dart';
import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/features/feed/data/firebase_post_repository.dart';
import 'package:meep/shared/models/post.dart';
import 'package:meep/features/friend/application/friend_controller.dart';
import 'package:meep/features/friend/data/firebase_friend_repository.dart';
import 'package:meep/features/profile/application/friend_posts_provider.dart';

void main() {
  const currentUid = 'uid-alice';
  const friendUid = 'uid-bob';
  const otherUid = 'uid-charlie';

  late FakeFirebaseFirestore firestore;

  final basePost = Post(
    postId: 'p1',
    authorId: friendUid,
    authorName: 'Bob',
    imageUrl: 'https://cdn/p1.jpg',
    audienceType: AudienceType.all,
    createdAt: DateTime.utc(2026, 5, 10, 12),
  );

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  ProviderContainer makeContainer({String? signedInUid = currentUid}) {
    final mockAuth = signedInUid != null
        ? MockFirebaseAuth(
            mockUser: MockUser(uid: signedInUid),
            signedIn: true,
          )
        : MockFirebaseAuth();
    final c = ProviderContainer(
      overrides: [
        authRepositoryProvider
            .overrideWithValue(FirebaseAuthRepository(auth: mockAuth)),
        postRepositoryProvider
            .overrideWithValue(FirebasePostRepository(firestore)),
        friendRepositoryProvider
            .overrideWithValue(FirebaseFriendRepository(firestore)),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> seedPost(Post post) async {
    await firestore.doc('posts/${post.postId}').set(post.toJson());
  }

  Future<void> seedFriendship(String a, String b) async {
    final lo = a.compareTo(b) < 0 ? a : b;
    final hi = a.compareTo(b) < 0 ? b : a;
    await firestore.doc('friendships/${lo}_$hi').set({
      'uid1': lo,
      'uid2': hi,
      'members': [lo, hi],
      'createdAt': Timestamp.now(),
    });
  }

  // Keep autoDispose provider alive trong khi await `.future` — không listen →
  // provider dispose mid-load với lỗi "no value emitted".
  Future<List<Post>?> readFriendPosts(ProviderContainer c, String uid) async {
    final sub = c.listen(friendPostsProvider(uid), (_, __) {});
    addTearDown(sub.close);
    return c.read(friendPostsProvider(uid).future);
  }

  Future<bool> readIsFriend(ProviderContainer c, String uid) async {
    final sub = c.listen(isFriendOfCurrentProvider(uid), (_, __) {});
    addTearDown(sub.close);
    return c.read(isFriendOfCurrentProvider(uid).future);
  }

  group('friendPostsProvider', () {
    test('returns null khi current user chưa login', () async {
      final c = makeContainer(signedInUid: null);
      final result = await readFriendPosts(c, friendUid);
      expect(result, isNull);
    });

    test('returns empty list khi friend chưa có post', () async {
      final c = makeContainer();
      final result = await readFriendPosts(c, friendUid);
      expect(result, isNotNull);
      expect(result, isEmpty);
    });

    test('hiển thị tất cả audienceType==all posts', () async {
      await seedPost(basePost.copyWith(postId: 'p1'));
      await seedPost(basePost.copyWith(postId: 'p2'));
      final c = makeContainer();
      final result = await readFriendPosts(c, friendUid);
      expect(result!.map((p) => p.postId).toSet(), {'p1', 'p2'});
    });

    test('hiển thị audienceType==select khi currentUid trong audienceUids',
        () async {
      await seedPost(
        basePost.copyWith(
          postId: 'p-select-me',
          audienceType: AudienceType.select,
          audienceUids: [currentUid],
        ),
      );
      await seedPost(
        basePost.copyWith(
          postId: 'p-select-other',
          audienceType: AudienceType.select,
          audienceUids: [otherUid],
        ),
      );
      final c = makeContainer();
      final result = await readFriendPosts(c, friendUid);
      expect(
        result!.map((p) => p.postId).toSet(),
        {'p-select-me'},
        reason: 'chỉ post chia sẻ với currentUid hiển thị',
      );
    });

    test('loại audienceType==select khi currentUid không trong audienceUids',
        () async {
      await seedPost(
        basePost.copyWith(
          postId: 'p-hidden',
          audienceType: AudienceType.select,
          audienceUids: [otherUid],
        ),
      );
      final c = makeContainer();
      final result = await readFriendPosts(c, friendUid);
      expect(result, isEmpty);
    });

    test('mix all + select-me + select-other → only all + select-me', () async {
      await seedPost(basePost.copyWith(postId: 'p-all'));
      await seedPost(
        basePost.copyWith(
          postId: 'p-select-me',
          audienceType: AudienceType.select,
          audienceUids: [currentUid, otherUid],
        ),
      );
      await seedPost(
        basePost.copyWith(
          postId: 'p-select-other',
          audienceType: AudienceType.select,
          audienceUids: [otherUid],
        ),
      );
      final c = makeContainer();
      final result = await readFriendPosts(c, friendUid);
      expect(
        result!.map((p) => p.postId).toSet(),
        {'p-all', 'p-select-me'},
      );
    });

    test('sort createdAt DESC sau filter', () async {
      await seedPost(
        basePost.copyWith(
          postId: 'p-old',
          createdAt: DateTime.utc(2026, 5, 1),
        ),
      );
      await seedPost(
        basePost.copyWith(
          postId: 'p-new',
          createdAt: DateTime.utc(2026, 5, 20),
        ),
      );
      final c = makeContainer();
      final result = await readFriendPosts(c, friendUid);
      expect(result!.map((p) => p.postId).toList(), ['p-new', 'p-old']);
    });
  });

  group('isFriendOfCurrentProvider', () {
    test('false khi current user chưa login', () async {
      final c = makeContainer(signedInUid: null);
      final result = await readIsFriend(c, friendUid);
      expect(result, isFalse);
    });

    test('false khi currentUid == friendUid (chính mình)', () async {
      final c = makeContainer();
      final result = await readIsFriend(c, currentUid);
      expect(result, isFalse);
    });

    test('false khi chưa có friendship doc', () async {
      final c = makeContainer();
      final result = await readIsFriend(c, friendUid);
      expect(result, isFalse);
    });

    test('true khi friendship doc tồn tại', () async {
      await seedFriendship(currentUid, friendUid);
      final c = makeContainer();
      final result = await readIsFriend(c, friendUid);
      expect(result, isTrue);
    });
  });
}
