import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/settings/data/block.dart';
import 'package:meep/features/settings/data/block_repository.dart';

class FirebaseBlockRepository implements BlockRepository {
  FirebaseBlockRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  static const _blocksCollection = 'blocks';

  /// Asymmetric block doc ID: blocker initiates, NOT sorted (khác `pairId`).
  String _blockIdOf(String blockerUid, String blockedUid) =>
      '${blockerUid}_$blockedUid';

  @override
  Future<void> blockUser({
    required String blockerUid,
    required String targetUid,
  }) async {
    // CF Admin SDK bypass rules → atomic block + unfriend + conversation
    // status update (Task T5 #119). Client KHÔNG write Firestore trực tiếp.
    try {
      final callable = _functions.httpsCallable('blockUser');
      await callable.call<void>({'targetUid': targetUid});
    } on FirebaseFunctionsException catch (e) {
      throw _mapFunctionsException(e, 'chặn người dùng');
    }
  }

  @override
  Future<void> unblockUser({
    required String blockerUid,
    required String targetUid,
  }) async {
    // Client-side delete OK — blocker chính chủ doc, rule cho phép xoá
    // khi request.auth.uid == blockerUid (resolved OQ5 trong #116).
    await _firestore
        .collection(_blocksCollection)
        .doc(_blockIdOf(blockerUid, targetUid))
        .delete();
  }

  @override
  Stream<List<Block>> watchBlockedUsers(String blockerUid) {
    return _firestore
        .collection(_blocksCollection)
        .where('blockerUid', isEqualTo: blockerUid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Block.fromJson(doc.data())).toList(),
        );
  }

  @override
  Future<bool> isBlocked({required String uid1, required String uid2}) async {
    // Check cả 2 chiều song song: tồn tại 1 trong 2 doc là true.
    final results = await Future.wait([
      _firestore
          .collection(_blocksCollection)
          .doc(_blockIdOf(uid1, uid2))
          .get(),
      _firestore
          .collection(_blocksCollection)
          .doc(_blockIdOf(uid2, uid1))
          .get(),
    ]);
    return results.any((doc) => doc.exists);
  }

  /// Map [FirebaseFunctionsException] sang [AppError] tương ứng.
  /// Pattern theo `firebase_space_repository.dart`.
  AppError _mapFunctionsException(
    FirebaseFunctionsException e,
    String action,
  ) {
    final serverMessage = e.message;
    switch (e.code) {
      case 'invalid-argument':
      case 'failed-precondition':
        return ValidationError(
          message: serverMessage ?? 'Không thể $action: dữ liệu không hợp lệ',
          code: e.code,
          cause: e,
        );
      case 'permission-denied':
        return ForbiddenError(action);
      case 'not-found':
        return NotFoundError(serverMessage ?? action);
      case 'unauthenticated':
        return UnauthenticatedError(
          message: serverMessage ?? 'Cần đăng nhập để $action',
          code: e.code,
          cause: e,
        );
      case 'unavailable':
      case 'deadline-exceeded':
        return NetworkError(
          message: serverMessage ?? 'Mất kết nối khi $action. Thử lại sau.',
          code: e.code,
          cause: e,
        );
      default:
        return UnexpectedError(
          message: serverMessage ?? 'Không thể $action. Thử lại sau.',
          code: e.code,
          cause: e,
        );
    }
  }
}
