import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meep/shared/models/post.dart';
import 'package:meep/features/feed/data/post_repository.dart';
import 'package:meep/features/friend/data/friend_repository.dart';

class FirebasePostRepository implements PostRepository {
  FirebasePostRepository(this._db, {FriendRepository? friendRepository})
      : _friendRepository = friendRepository;

  final FirebaseFirestore _db;
  final FriendRepository? _friendRepository;

  static const _posts = 'posts';
  static const _feedPageSize = 10;
  static const _spaceFeedBuffer = 30;
  static const _profilePostLimit = 60;

  @override
  String newPostId() => _db.collection(_posts).doc().id;

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
    if (spaceId != null) return _watchSpaceFeed(spaceId, uid);
    return _watchFriendsFeed(uid);
  }

  /// Buffer query Space feed — query `memberIds arrayContains callerUid`
  /// có thể trả về post của Space khác mà caller cũng là member, rồi
  /// client filter theo spaceIds. Buffer 30 đủ cho MVP (caller hiếm khi ở
  /// > 3 Space active). Khi Tier 1 cần precise pagination, đổi sang
  /// compound array-contains-any (giới hạn Firestore 10 values).
  /// Feed Space — query `/posts WHERE memberIds arrayContains callerUid`
  /// rồi client filter `spaceIds.contains(spaceId)`.
  ///
  /// Tại sao không query thẳng `where('spaceIds', arrayContains: spaceId)`:
  /// Firestore rule `/posts` cần prove tĩnh "mọi doc match query đều pass
  /// read rule". Disjunct (3) ở rule là
  /// `memberIds.hasAny([request.auth.uid])` → query phải có cùng constraint
  /// `arrayContains: callerUid` thì engine mới derive được. Query khác
  /// (vd `arrayContains: spaceId`) → engine không prove được → reject
  /// toàn query với PERMISSION_DENIED.
  ///
  /// Cần compound index `(memberIds CONTAINS, createdAt desc)`.
  Stream<List<Post>> _watchSpaceFeed(String spaceId, String callerUid) {
    return _db
        .collection(_posts)
        .where('memberIds', arrayContains: callerUid)
        .orderBy('createdAt', descending: true)
        .limit(_spaceFeedBuffer)
        .snapshots()
        .map((snap) {
      final all = snap.docs.map((d) => Post.fromJson(d.data()));
      return all.where((p) => p.spaceIds.contains(spaceId)).take(10).toList();
    });
  }

  /// Feed chung — own posts + friends posts + Space posts (caller là member).
  ///
  /// Dùng 2 nhóm stream merge:
  /// 1. `where('authorId', whereIn: self + friend uids)` — 1 listener thay
  ///    vì 1 listener/author. Firestore giới hạn `whereIn` 30 values nên MVP
  ///    lấy self + 29 bạn đầu tiên.
  /// 2. `where('memberIds', arrayContains: callerUid)` — pass rule disjunct
  ///    (3) Space member, cover post của stranger-cùng-Space mà caller không
  ///    phải friend.
  ///
  /// Dedupe theo postId vì 1 post của friend đăng vào Space chung sẽ xuất
  /// hiện ở cả 2 nhánh — keep bản đầu, drop trùng. Sort lại theo createdAt.
  ///
  /// Cần compound index `(memberIds CONTAINS, createdAt desc)` — index đã
  /// declare cho Space feed nên dùng chung.
  Stream<List<Post>> _watchFriendsFeed(String uid) {
    return _getFriendUids(uid).asStream().asyncExpand((friendUids) {
      final authorIds = [uid, ...friendUids].take(30).toList();

      final authorStream = _db
          .collection(_posts)
          .where('authorId', whereIn: authorIds)
          .orderBy('createdAt', descending: true)
          .limit(_spaceFeedBuffer)
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map((doc) => Post.fromJson(doc.data())).toList(),
          );

      // Space posts mà caller là member. Buffer 30 đủ MVP (caller ở vài
      // Space active). Trùng với perAuthorStreams khi friend đăng Space —
      // dedupe ở merge step.
      final spaceMemberStream = _db
          .collection(_posts)
          .where('memberIds', arrayContains: uid)
          .orderBy('createdAt', descending: true)
          .limit(_spaceFeedBuffer)
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map((doc) => Post.fromJson(doc.data())).toList(),
          );

      return _mergeStreams([authorStream, spaceMemberStream]).map((allPosts) {
        // Dedupe theo postId (1 post Space-of-friend có thể xuất hiện ở
        // authorStream VÀ spaceMemberStream).
        final seen = <String>{};
        final unique = <Post>[];
        for (final p in allPosts) {
          if (seen.add(p.postId)) unique.add(p);
        }
        unique.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return unique.take(_feedPageSize).toList();
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
  /// Production path delegates to [FriendRepository] so friend-graph ownership
  /// stays in the Friend module. Tests may omit it and use the local fallback.
  Future<List<String>> _getFriendUids(String uid) async {
    final friendRepository = _friendRepository;
    if (friendRepository != null) {
      return friendRepository.getFriendUids(uid);
    }

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
        .limit(_profilePostLimit)
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
