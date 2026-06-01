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
      expect(data.containsKey('spaceId'), isFalse);
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
