import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/features/feed/data/firebase_post_repository.dart';
import 'package:meep/shared/models/post.dart';
import 'package:meep/features/profile/application/profile_posts_provider.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  final basePost = Post(
    postId: 'p1',
    authorId: 'uid-alice',
    authorName: 'Alice',
    imageUrl: 'https://cdn/1.jpg',
    audienceType: AudienceType.all,
    createdAt: DateTime.utc(2026, 5, 10, 12),
  );

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [
        postRepositoryProvider
            .overrideWithValue(FirebasePostRepository(firestore)),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> seedPost(Post post) async {
    await firestore.doc('posts/${post.postId}').set(post.toJson());
  }

  test('returns empty list khi user chưa có post', () async {
    final c = makeContainer();
    final posts = await c.read(profilePostsProvider('uid-alice').future);
    expect(posts, isEmpty);
  });

  test('returns posts của author', () async {
    await seedPost(basePost);
    await seedPost(basePost.copyWith(postId: 'p2'));

    final c = makeContainer();
    final posts = await c.read(profilePostsProvider('uid-alice').future);
    expect(posts.length, 2);
    expect(posts.every((p) => p.authorId == 'uid-alice'), isTrue);
  });

  test('sort createdAt DESC (mới → cũ)', () async {
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
    await seedPost(
      basePost.copyWith(
        postId: 'p-mid',
        createdAt: DateTime.utc(2026, 5, 10),
      ),
    );

    final c = makeContainer();
    final posts = await c.read(profilePostsProvider('uid-alice').future);
    expect(
      posts.map((p) => p.postId).toList(),
      ['p-new', 'p-mid', 'p-old'],
    );
  });

  test('không trả posts của author khác', () async {
    await seedPost(basePost);
    await seedPost(
      basePost.copyWith(
        postId: 'p-other',
        authorId: 'uid-bob',
      ),
    );

    final c = makeContainer();
    final posts = await c.read(profilePostsProvider('uid-alice').future);
    expect(posts.length, 1);
    expect(posts.first.authorId, 'uid-alice');
  });
}
