import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
    // [DEBUG/Space Feed] Log entry point để xác nhận tham số được truyền
    // đúng từ controller xuống. Nếu spaceId null mà anh đang chọn filter
    // Space → bug ở provider/controller chứ không phải repo.
    debugPrint(
      '[Space Feed] watchFeed bắt đầu — uid=$uid, spaceId=${spaceId ?? "<null/feed chung>"}',
    );

    // Branch theo Space context.
    if (spaceId != null) {
      debugPrint(
        '[Space Feed] → đi nhánh _watchSpaceFeed cho spaceId=$spaceId, callerUid=$uid',
      );
      return _watchSpaceFeed(spaceId, uid);
    }
    debugPrint('[Space Feed] → đi nhánh _watchFriendsFeed (feed chung)');
    return _watchFriendsFeed(uid);
  }

  /// Buffer query Space feed — query `memberIds arrayContains callerUid`
  /// có thể trả về post của Space khác mà caller cũng là member, rồi
  /// client filter theo spaceIds. Buffer 30 đủ cho MVP (caller hiếm khi ở
  /// > 3 Space active). Khi Tier 1 cần precise pagination, đổi sang
  /// compound array-contains-any (giới hạn Firestore 10 values).
  static const _spaceFeedBuffer = 30;

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
    debugPrint(
      '[Space Feed] _watchSpaceFeed: gửi query Firestore '
      '/posts WHERE memberIds arrayContains "$callerUid" '
      'ORDER BY createdAt DESC LIMIT $_spaceFeedBuffer '
      '(rồi client filter spaceIds.contains("$spaceId"))',
    );
    return _db
        .collection(_posts)
        .where('memberIds', arrayContains: callerUid)
        .orderBy('createdAt', descending: true)
        .limit(_spaceFeedBuffer)
        .snapshots()
        .map((snap) {
      debugPrint(
        '[Space Feed] _watchSpaceFeed snapshot — '
        'caller=$callerUid trả về ${snap.docs.length} doc (raw, chưa filter spaceId)',
      );
      try {
        final all = snap.docs.map((d) => Post.fromJson(d.data())).toList();
        final filtered =
            all.where((p) => p.spaceIds.contains(spaceId)).take(10).toList();
        debugPrint(
          '[Space Feed] _watchSpaceFeed sau filter spaceId="$spaceId": '
          '${filtered.length}/${all.length} post',
        );
        if (filtered.isEmpty && all.isEmpty) {
          debugPrint(
            '[Space Feed] CẢNH BÁO: query trả 0 doc. Khả năng: '
            '(1) caller chưa post vào Space nào & chưa member của Space có post; '
            '(2) post cũ thiếu field memberIds (post pre-multi-Space).',
          );
        }
        return filtered;
      } catch (e, st) {
        debugPrint(
          '[Space Feed] LỖI parse Post.fromJson trong _watchSpaceFeed: $e',
        );
        debugPrint('[Space Feed] Stacktrace: $st');
        rethrow;
      }
    }).handleError((Object e, StackTrace st) {
      if (e is FirebaseException) {
        debugPrint(
          '[Space Feed] LỖI Firestore _watchSpaceFeed — '
          'code=${e.code}, message=${e.message}',
        );
        switch (e.code) {
          case 'failed-precondition':
            debugPrint(
              '[Space Feed] → NGUYÊN NHÂN: compound index '
              '(memberIds CONTAINS, createdAt desc) chưa deploy. '
              'Chạy: firebase deploy --only firestore:indexes',
            );
          case 'permission-denied':
            debugPrint(
              '[Space Feed] → NGUYÊN NHÂN: rules /posts deny read. '
              'Query constraint không khớp disjunct rule — kiểm tra query '
              'có dùng đúng `where("memberIds", arrayContains: callerUid)` không.',
            );
          case 'unavailable':
            debugPrint(
              '[Space Feed] → NGUYÊN NHÂN: mất kết nối Firestore.',
            );
          default:
            debugPrint(
              '[Space Feed] → Error code khác. Em cần đọc message để chẩn đoán.',
            );
        }
      } else {
        debugPrint(
          '[Space Feed] LỖI không phải FirebaseException _watchSpaceFeed: $e',
        );
      }
      debugPrint('[Space Feed] Stacktrace: $st');
      // ignore: only_throw_errors — preserve original error type
      throw e;
    });
  }

  /// Buffer per-author query — page đầu có thể full Space posts → sau
  /// dedupe + sort, take(10) thiếu. Buffer 20 đủ cho MVP (≤ 30 authors).
  static const _perAuthorBuffer = 20;

  /// Feed chung — own posts + friends posts + Space posts (caller là member).
  ///
  /// Dùng 2 nhóm stream merge:
  /// 1. `where('authorId', isEqualTo: X)` cho mỗi author (self + friend uids)
  ///    — pass rule disjunct (1) own / (2) friend.
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
      final authorIds = [uid, ...friendUids];

      final perAuthorStreams = authorIds.take(30).map((authorId) {
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

      final allStreams = [...perAuthorStreams, spaceMemberStream];

      if (allStreams.isEmpty) {
        return Stream.value(<Post>[]);
      }

      return _mergeStreams(allStreams).map((allPosts) {
        // Dedupe theo postId (1 post Space-of-friend có thể xuất hiện ở
        // perAuthorStreams VÀ spaceMemberStream).
        final seen = <String>{};
        final unique = <Post>[];
        for (final p in allPosts) {
          if (seen.add(p.postId)) unique.add(p);
        }
        unique.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return unique.take(10).toList();
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
