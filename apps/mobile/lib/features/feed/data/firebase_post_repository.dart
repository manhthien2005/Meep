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
    final data = post.toJson()
      ..['createdAt'] = FieldValue
          .serverTimestamp(); // spec: serverTimestamp, not device clock
    await ref.set(data);
    return post;
  }

  @override
  Stream<List<Post>> watchFeed(String uid) {
    // Direct-read approach: separate queries for own posts + each friend's posts,
    // then merge streams. Works with Firestore Rules that check resource.data.authorId.
    return _getFriendUids(uid).asStream().asyncExpand((friendUids) {
      final authorIds = [uid, ...friendUids];

      if (authorIds.isEmpty) {
        return Stream.value(<Post>[]);
      }

      // Query each author separately, then merge + sort client-side.
      // Firestore Rules allow read when resource.data.authorId matches or isFriend().
      final streams = authorIds.take(30).map((authorId) {
        return _db
            .collection(_posts)
            .where('authorId', isEqualTo: authorId)
            .orderBy('createdAt', descending: true)
            .limit(10)
            .snapshots()
            .map(
              (snap) =>
                  snap.docs.map((doc) => Post.fromJson(doc.data())).toList(),
            );
      }).toList();

      // Merge all streams, flatten, sort by createdAt desc, take top 10.
      return _mergeStreams(streams).map((allPosts) {
        allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return allPosts.take(10).toList();
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
}
