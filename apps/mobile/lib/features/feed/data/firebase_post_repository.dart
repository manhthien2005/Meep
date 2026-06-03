import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meep/features/feed/data/post.dart';
import 'package:meep/features/feed/data/post_repository.dart';

class FirebasePostRepository implements PostRepository {
  FirebasePostRepository(this._db);

  final FirebaseFirestore _db;

  static const _posts = 'posts';

  @override
  Future<Post> createPost(Post post) async {
    if (post.audienceType == AudienceType.select && post.audienceUids.isEmpty) {
      throw ArgumentError('select audience requires at least one uid');
    }

    final ref = _db.collection(_posts).doc(post.postId);
    // Strip null fields BEFORE writing: Firestore rule `/posts/{postId}` requires
    // `caption is string` whenever the `caption` key is present, so leaving an
    // explicit `caption: null` (or other null fields) in the payload trips a
    // permission-denied. Removing the keys makes the rule's `!('caption' in data)`
    // branch satisfy instead.
    final data = post.toJson()
      ..removeWhere((_, value) => value == null)
      ..['createdAt'] = FieldValue
          .serverTimestamp(); // spec: serverTimestamp, not device clock
    await ref.set(data);
    return post;
  }

  @override
  Stream<List<Post>> watchFeed(String uid, {String? spaceId}) {
    // Branch theo Space context.
    if (spaceId != null) {
      return _watchSpaceFeed(spaceId);
    }
    return _watchFriendsFeed(uid);
  }

  /// Feed Space — query thẳng `/posts where spaceId == X`. Cần compound
  /// index `(spaceId asc, createdAt desc)` ở firestore.indexes.json.
  ///
  /// Rule `/posts` read pass cho Space member qua nhánh
  /// `exists(/users/{uid}/feed/{postId})` (CF spacePostFanOut tạo entry
  /// khi post.spaceId != null) — không cần Space member phải là friend
  /// của author.
  Stream<List<Post>> _watchSpaceFeed(String spaceId) {
    return _db
        .collection(_posts)
        .where('spaceId', isEqualTo: spaceId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => Post.fromJson(doc.data())).toList(),
        );
  }

  /// Feed chung — own posts + friends posts, loại Space posts.
  ///
  /// Filter `p.spaceId == null` client-side sau merge: Firestore không
  /// index null mặc định, query `where('spaceId', '==', null)` chỉ match
  /// docs có explicit null field, miss docs không có field (posts cũ
  /// pre-spaceId). Client-side an toàn hơn — vẫn loại đúng Space posts.
  ///
  /// Per-author query limit = 20 (buffer 2x): nếu user gần đây post nhiều
  /// vào Space, page đầu có thể full Space posts → take(10) sau filter sẽ
  /// thiếu post non-Space. Buffer 20 đủ rộng cho MVP (≤ 30 authors × 20
  /// posts = 600 docs reads/min worst case). Khi Tier 1 thêm cursor pagi,
  /// đổi sang server-side filter compound query.
  static const _perAuthorBuffer = 20;

  Stream<List<Post>> _watchFriendsFeed(String uid) {
    return _getFriendUids(uid).asStream().asyncExpand((friendUids) {
      final authorIds = [uid, ...friendUids];

      if (authorIds.isEmpty) {
        return Stream.value(<Post>[]);
      }

      final streams = authorIds.take(30).map((authorId) {
        return _db
            .collection(_posts)
            .where('authorId', isEqualTo: authorId)
            .orderBy('createdAt', descending: true)
            .limit(_perAuthorBuffer)
            .snapshots()
            .map(
              (snap) =>
                  snap.docs.map((doc) => Post.fromJson(doc.data())).toList(),
            );
      }).toList();

      return _mergeStreams(streams).map((allPosts) {
        allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        // Loại Space posts khỏi feed chung — chỉ post.spaceId == null
        // xuất hiện ở "Mọi người" / "Bạn" / "Friend X" filter.
        return allPosts.where((p) => p.spaceId == null).take(10).toList();
      });
    });
  }

  /// Merge multiple streams of `List<Post>` into one stream of flattened `List<Post>`.
  Stream<List<Post>> _mergeStreams(List<Stream<List<Post>>> streams) async* {
    if (streams.isEmpty) {
      yield [];
      return;
    }

    final latestValues = List<List<Post>?>.filled(streams.length, null);
    final controller = StreamController<List<Post>>();
    final subscriptions = <StreamSubscription<List<Post>>>[];

    for (var i = 0; i < streams.length; i++) {
      subscriptions.add(
        streams[i].listen(
          (posts) {
            latestValues[i] = posts;
            // Emit only after all streams have emitted at least once.
            if (latestValues.every((v) => v != null)) {
              final merged = latestValues
                  .whereType<List<Post>>()
                  .expand((list) => list)
                  .toList();
              controller.add(merged);
            }
          },
          onError: controller.addError,
        ),
      );
    }

    yield* controller.stream;

    await Future.wait(subscriptions.map((s) => s.cancel()));
    await controller.close();
  }

  /// Fetch friend UIDs from /friendships where members contains [uid].
  /// Does NOT use FriendRepository (which is stub UnimplementedError).
  Future<List<String>> _getFriendUids(String uid) async {
    final snap = await _db
        .collection('friendships')
        .where('members', arrayContains: uid)
        .get();

    return snap.docs.expand((doc) {
      final members = doc.data()['members'] as List<dynamic>? ?? [];
      return members.cast<String>().where((m) => m != uid);
    }).toList();
  }

  @override
  Future<void> deletePost(String postId) async {
    await _db.collection(_posts).doc(postId).delete();
    // Storage cleanup is handled by CF onPostDeleted
  }

  @override
  Future<List<Post>> getPostsByAuthor(String authorId) async {
    final snap = await _db
        .collection(_posts)
        .where('authorId', isEqualTo: authorId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => Post.fromJson(d.data())).toList();
  }

  @override
  Future<Post?> getPost(String postId) async {
    if (postId.isEmpty) return null;
    final doc = await _db.collection(_posts).doc(postId).get();
    if (!doc.exists) return null;
    return Post.fromJson({...doc.data()!, 'postId': doc.id});
  }
}
