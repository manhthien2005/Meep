import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/feed/data/firebase_post_repository.dart';
import 'package:meep/features/feed/data/post.dart';

Post _makePost({
  String postId = 'p1',
  String authorId = 'uid1',
  AudienceType audience = AudienceType.all,
  List<String> uids = const [],
}) =>
    Post(
      postId: postId,
      authorId: authorId,
      authorName: 'Test User',
      imageUrl: 'https://example.com/photo.jpg',
      audienceType: audience,
      audienceUids: uids,
      createdAt: DateTime(2026, 5, 27),
    );

void main() {
  late FakeFirebaseFirestore db;
  late FirebasePostRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirebasePostRepository(db);
  });

  group('createPost', () {
    test('writes doc with correct fields', () async {
      final post = _makePost();
      await repo.createPost(post);

      final snap = await db.collection('posts').doc('p1').get();
      expect(snap.exists, isTrue);
      expect(snap.data()!['authorId'], 'uid1');
      expect(snap.data()!['audienceType'], 'all');
    });

    test('persists dual camera lenses + flag', () async {
      final post = Post(
        postId: 'dual1',
        authorId: 'uid1',
        authorName: 'Test User',
        backImageUrl: 'https://example.com/back.jpg',
        frontImageUrl: 'https://example.com/front.jpg',
        isDualCamera: true,
        audienceType: AudienceType.all,
        createdAt: DateTime(2026, 5, 31),
      );
      await repo.createPost(post);

      final snap = await db.collection('posts').doc('dual1').get();
      expect(snap.data()!['isDualCamera'], isTrue);
      expect(snap.data()!['backImageUrl'], 'https://example.com/back.jpg');
      expect(snap.data()!['frontImageUrl'], 'https://example.com/front.jpg');
      expect(snap.data()!['imageUrl'], isNull);
    });

    test('select audience with empty uids throws ArgumentError', () async {
      final post = _makePost(audience: AudienceType.select, uids: []);
      await expectLater(
        () => repo.createPost(post),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('select audience with uids succeeds', () async {
      final post = _makePost(
        audience: AudienceType.select,
        uids: ['uid2', 'uid3'],
      );
      await repo.createPost(post);

      final snap = await db.collection('posts').doc('p1').get();
      expect(snap.data()!['audienceType'], 'select');
      expect(snap.data()!['audienceUids'], ['uid2', 'uid3']);
    });

    test('strips null fields so Firestore rule does not reject the create',
        () async {
      // Single-camera post WITHOUT a caption — used to write
      // `caption: null` which trips the `caption is string` rule branch and
      // causes a permission-denied in prod. Repo must drop those keys.
      final post = _makePost();
      await repo.createPost(post);

      final data = (await db.collection('posts').doc('p1').get()).data()!;
      expect(data.containsKey('caption'), isFalse);
      expect(data.containsKey('backImageUrl'), isFalse);
      expect(data.containsKey('frontImageUrl'), isFalse);
      expect(data.containsKey('captionType'), isFalse);
      expect(data.containsKey('authorAvatarUrl'), isFalse);
      // Non-null fields stay.
      expect(data['authorId'], 'uid1');
      expect(data['imageUrl'], isNotNull);
    });

    test('keeps caption key when caption is a non-empty string', () async {
      final post = Post(
        postId: 'p2',
        authorId: 'uid1',
        authorName: 'Test User',
        imageUrl: 'https://example.com/photo.jpg',
        caption: 'hello world',
        audienceType: AudienceType.all,
        createdAt: DateTime(2026, 5, 27),
      );
      await repo.createPost(post);
      final data = (await db.collection('posts').doc('p2').get()).data()!;
      expect(data['caption'], 'hello world');
    });
  });

  group('watchFeed', () {
    test('returns own posts + friend posts ordered by createdAt', () async {
      // Seed /posts docs
      final p1 = _makePost(postId: 'p1', authorId: 'uid1');
      final p2 = _makePost(postId: 'p2', authorId: 'uid2');
      final p3 = _makePost(postId: 'p3', authorId: 'uid3');
      await db.collection('posts').doc('p1').set(p1.toJson());
      await db.collection('posts').doc('p2').set(p2.toJson());
      await db.collection('posts').doc('p3').set(p3.toJson());

      // Seed /friendships — uid1 is friends with uid2 (not uid3)
      await db.collection('friendships').doc('uid1_uid2').set({
        'members': ['uid1', 'uid2'],
        'createdAt': DateTime(2026, 5, 1),
      });

      final posts = await repo.watchFeed('uid1').first;
      expect(posts.map((p) => p.postId), containsAll(['p1', 'p2']));
      expect(posts.map((p) => p.postId), isNot(contains('p3')));
    });

    test('returns empty list when no friends and no own posts', () async {
      final posts = await repo.watchFeed('uid1').first;
      expect(posts, isEmpty);
    });

    test('feed chung (spaceId null) bao gồm cả Space posts caller là member',
        () async {
      // Yêu cầu: filter "Mọi người" show TOÀN BỘ — own + friend + Space.
      // Seed 3 posts:
      // - p1: own post chung (không Space)
      // - p2: own post Space s1 (memberIds chứa uid1)
      // - p3: post của stranger uid2 trong Space s1 (uid1 cũng member,
      //   uid2 KHÔNG phải friend) → vẫn phải show qua nhánh memberIds.
      final pChung = _makePost(postId: 'p1', authorId: 'uid1');
      final pOwnSpace = Post(
        postId: 'p2',
        authorId: 'uid1',
        authorName: 'Test User',
        imageUrl: 'https://example.com/photo.jpg',
        audienceType: AudienceType.all,
        spaceIds: const ['s1'],
        memberIds: const ['uid1', 'uid2'],
        createdAt: DateTime(2026, 5, 27),
      );
      final pStrangerSpace = Post(
        postId: 'p3',
        authorId: 'uid2',
        authorName: 'Stranger',
        imageUrl: 'https://example.com/photo.jpg',
        audienceType: AudienceType.all,
        spaceIds: const ['s1'],
        memberIds: const ['uid1', 'uid2'],
        createdAt: DateTime(2026, 5, 28),
      );
      await db.collection('posts').doc('p1').set(pChung.toJson());
      await db.collection('posts').doc('p2').set(pOwnSpace.toJson());
      await db.collection('posts').doc('p3').set(pStrangerSpace.toJson());

      final posts = await repo.watchFeed('uid1').first;
      expect(
        posts.map((p) => p.postId),
        containsAll(['p1', 'p2', 'p3']),
      );
    });

    test('feed chung dedupe post của friend đăng vào Space caller cũng member',
        () async {
      // friend uid2 đăng vào Space s1 (uid1 cũng member). Post đó match
      // CẢ nhánh perAuthor (authorId == uid2) lẫn nhánh memberIds
      // (uid1 in memberIds). Kết quả phải chỉ có 1 entry, không duplicate.
      await db.collection('friendships').doc('uid1_uid2').set({
        'members': ['uid1', 'uid2'],
        'createdAt': DateTime(2026, 5, 1),
      });
      final pFriendSpace = Post(
        postId: 'p_dup',
        authorId: 'uid2',
        authorName: 'Friend',
        imageUrl: 'https://example.com/photo.jpg',
        audienceType: AudienceType.all,
        spaceIds: const ['s1'],
        memberIds: const ['uid1', 'uid2'],
        createdAt: DateTime(2026, 5, 27),
      );
      await db.collection('posts').doc('p_dup').set(pFriendSpace.toJson());

      final posts = await repo.watchFeed('uid1').first;
      expect(posts.where((p) => p.postId == 'p_dup').length, 1);
    });

    test('spaceId != null trả về chỉ posts của Space đó', () async {
      // Caller uid1 là member của cả s1 và s2. Hỗn hợp post:
      // - p_chung: post chung (không có memberIds)
      // - p_s1: post Space s1, memberIds chứa uid1
      // - p_s2: post Space s2, memberIds chứa uid1
      // watchFeed(uid1, spaceId: 's1') chỉ trả p_s1.
      final pChung = _makePost(postId: 'p_chung', authorId: 'uid1');
      final pS1 = Post(
        postId: 'p_s1',
        authorId: 'uid1',
        authorName: 'Test User',
        imageUrl: 'https://example.com/photo.jpg',
        audienceType: AudienceType.all,
        spaceIds: const ['s1'],
        memberIds: const ['uid1', 'uid2'],
        createdAt: DateTime(2026, 5, 27),
      );
      final pS2 = Post(
        postId: 'p_s2',
        authorId: 'uid1',
        authorName: 'Test User',
        imageUrl: 'https://example.com/photo.jpg',
        audienceType: AudienceType.all,
        spaceIds: const ['s2'],
        memberIds: const ['uid1', 'uid3'],
        createdAt: DateTime(2026, 5, 27),
      );
      await db.collection('posts').doc('p_chung').set(pChung.toJson());
      await db.collection('posts').doc('p_s1').set(pS1.toJson());
      await db.collection('posts').doc('p_s2').set(pS2.toJson());

      final posts = await repo.watchFeed('uid1', spaceId: 's1').first;
      expect(posts.map((p) => p.postId), ['p_s1']);
    });
  });

  group('deletePost', () {
    test('removes post doc', () async {
      await db.collection('posts').doc('p1').set(_makePost().toJson());
      await repo.deletePost('p1');
      final snap = await db.collection('posts').doc('p1').get();
      expect(snap.exists, isFalse);
    });
  });

  group('getPostsByAuthor', () {
    test('returns only posts by given author', () async {
      await db
          .collection('posts')
          .doc('p1')
          .set(_makePost(postId: 'p1', authorId: 'uid1').toJson());
      await db
          .collection('posts')
          .doc('p2')
          .set(_makePost(postId: 'p2', authorId: 'uid2').toJson());

      final posts = await repo.getPostsByAuthor('uid1');
      expect(posts.length, 1);
      expect(posts.first.authorId, 'uid1');
    });
  });
}
