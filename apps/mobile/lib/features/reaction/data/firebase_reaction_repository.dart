import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meep/features/reaction/data/reaction.dart';
import 'package:meep/features/reaction/data/reaction_repository.dart';

class FirebaseReactionRepository implements ReactionRepository {
  FirebaseReactionRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _reactionsRef(String postId) =>
      _db.collection('posts').doc(postId).collection('reactions');

  @override
  Stream<List<Reaction>> watchReactions(String postId) {
    return _reactionsRef(postId).snapshots().map(
          (snap) =>
              snap.docs.map((doc) => Reaction.fromJson(doc.data())).toList(),
        );
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
    await _reactionsRef(postId).doc(reactorUid).set({
      'reactorUid': reactorUid,
      'reactorName': reactorName,
      if (reactorAvatarUrl != null && reactorAvatarUrl.isNotEmpty)
        'reactorAvatarUrl': reactorAvatarUrl,
      'emoji': emoji,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteReaction({
    required String postId,
    required String reactorUid,
  }) async {
    // Firestore delete() idempotent — không throw khi doc không tồn tại.
    await _reactionsRef(postId).doc(reactorUid).delete();
  }

  @override
  Future<Reaction?> getMyReaction({
    required String postId,
    required String uid,
  }) async {
    final snap = await _reactionsRef(postId).doc(uid).get();
    if (!snap.exists) return null;
    return Reaction.fromJson(snap.data()!);
  }
}
