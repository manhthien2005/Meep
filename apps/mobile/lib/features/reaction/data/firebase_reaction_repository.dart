import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/reaction/data/reaction.dart';
import 'package:meep/features/reaction/data/reaction_repository.dart';

class FirebaseReactionRepository implements ReactionRepository {
  FirebaseReactionRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _reactionsRef(String postId) =>
      _db.collection('posts').doc(postId).collection('reactions');

  @override
  Stream<List<Reaction>> watchReactions(String postId) {
    return _reactionsRef(postId)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => Reaction.fromJson(doc.data())).toList(),
        )
        .handleError((Object e, StackTrace s) {
      if (e is FirebaseException) {
        throw _mapFirestoreError(e, 'tải phản ứng');
      }
      Error.throwWithStackTrace(e, s);
    });
  }

  @override
  Future<void> upsertReaction({
    required String postId,
    required String reactorUid,
    required String reactorName,
    String? reactorAvatarUrl,
    required String emoji,
  }) async {
    // docId = reactorUid → enforce 1 reaction/user/post. set() upsert, KHÔNG add().
    try {
      await _reactionsRef(postId).doc(reactorUid).set({
        'reactorUid': reactorUid,
        'reactorName': reactorName,
        if (reactorAvatarUrl != null && reactorAvatarUrl.isNotEmpty)
          'reactorAvatarUrl': reactorAvatarUrl,
        'emoji': emoji,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e, 'thả cảm xúc');
    }
  }

  @override
  Future<void> deleteReaction({
    required String postId,
    required String reactorUid,
  }) async {
    // Firestore delete() idempotent — không throw khi doc không tồn tại.
    try {
      await _reactionsRef(postId).doc(reactorUid).delete();
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e, 'gỡ cảm xúc');
    }
  }

  @override
  Future<Reaction?> getMyReaction({
    required String postId,
    required String uid,
  }) async {
    final DocumentSnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _reactionsRef(postId).doc(uid).get();
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e, 'tải phản ứng của bạn');
    }
    if (!snap.exists) return null;
    return Reaction.fromJson(snap.data()!);
  }

  AppError _mapFirestoreError(FirebaseException e, String action) {
    final serverMessage = e.message;
    return switch (e.code) {
      'permission-denied' => ForbiddenError.message(
          message: serverMessage ?? 'Bạn không có quyền $action',
          code: e.code,
          cause: e,
        ),
      'not-found' => NotFoundError.message(
          message: serverMessage ?? 'Không tìm thấy phản ứng',
          code: e.code,
          cause: e,
        ),
      'unavailable' || 'deadline-exceeded' || 'cancelled' => NetworkError(
          message: serverMessage ?? 'Mất kết nối khi $action. Thử lại sau.',
          code: e.code,
          cause: e,
        ),
      'failed-precondition' => ValidationError(
          message: serverMessage ?? 'Không thể $action: dữ liệu không hợp lệ',
          code: e.code,
          cause: e,
        ),
      _ => UnexpectedError(
          message: serverMessage ?? 'Không thể $action. Thử lại sau.',
          code: e.code,
          cause: e,
        ),
    };
  }
}
