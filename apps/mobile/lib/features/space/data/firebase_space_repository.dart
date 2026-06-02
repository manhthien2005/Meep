import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/space/data/space.dart';
import 'package:meep/features/space/data/space_member.dart';
import 'package:meep/features/space/data/space_repository.dart';

class FirebaseSpaceRepository implements SpaceRepository {
  FirebaseSpaceRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  static const _spacesCollection = 'spaces';

  // ===== Firestore reads =====

  @override
  Stream<List<Space>> watchMySpaces(String uid) {
    // orderBy createdAt desc — Space mới nhất lên đầu để Space list trong
    // Profile/Camera context sheet có thứ tự ổn định (không bị Firestore
    // default insertion order khiến UI nhảy).
    return _firestore
        .collection(_spacesCollection)
        .where('memberIds', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Space.fromJson({...doc.data(), 'spaceId': doc.id}))
          .where((space) => space.deletedAt == null)
          .toList();
    });
  }

  @override
  Stream<Space?> watchSpace(String spaceId) {
    return _firestore
        .collection(_spacesCollection)
        .doc(spaceId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final space = Space.fromJson({...doc.data()!, 'spaceId': doc.id});
      // Mirror getSpace logic — soft-deleted treated as not exists.
      if (space.deletedAt != null) return null;
      return space;
    });
  }

  @override
  Stream<List<SpaceMember>> watchMembers(String spaceId) {
    return _firestore
        .collection(_spacesCollection)
        .doc(spaceId)
        .collection('members')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SpaceMember.fromJson({...doc.data(), 'uid': doc.id}))
          .toList();
    });
  }

  @override
  Future<Space?> getSpace(String spaceId) async {
    final doc =
        await _firestore.collection(_spacesCollection).doc(spaceId).get();
    if (!doc.exists) return null;

    final space = Space.fromJson({...doc.data()!, 'spaceId': doc.id});
    if (space.deletedAt != null) return null;
    return space;
  }

  @override
  Future<void> deleteSpace(String spaceId) async {
    await _firestore.collection(_spacesCollection).doc(spaceId).update({
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  // ===== Cloud Function mutations =====

  @override
  Future<String> createSpace({
    required String name,
    required String iconEmoji,
    required String colorHex,
    required List<String> friendUids,
  }) async {
    try {
      final callable = _functions.httpsCallable('createSpace');
      final result = await callable.call<Map<Object?, Object?>>({
        'name': name,
        'iconEmoji': iconEmoji,
        'colorHex': colorHex,
        'friendUids': friendUids,
      });
      final spaceId = result.data['spaceId'];
      if (spaceId is! String || spaceId.isEmpty) {
        throw const UnexpectedError(
          message: 'CF createSpace không trả về spaceId hợp lệ',
        );
      }
      return spaceId;
    } on FirebaseFunctionsException catch (e) {
      throw _mapFunctionsException(e, 'tạo Space');
    }
  }

  @override
  Future<void> updateSpace({
    required String spaceId,
    String? name,
    String? iconEmoji,
    String? colorHex,
  }) async {
    // Partial update — chỉ truyền field non-null xuống CF. CF zod schema
    // refine reject empty patch nên ít nhất 1 field phải pass.
    final payload = <String, Object?>{'spaceId': spaceId};
    if (name != null) payload['name'] = name;
    if (iconEmoji != null) payload['iconEmoji'] = iconEmoji;
    if (colorHex != null) payload['colorHex'] = colorHex;

    try {
      final callable = _functions.httpsCallable('updateSpace');
      await callable.call<void>(payload);
    } on FirebaseFunctionsException catch (e) {
      throw _mapFunctionsException(e, 'cập nhật Space');
    }
  }

  @override
  Future<void> leaveSpace(String spaceId) async {
    try {
      final callable = _functions.httpsCallable('leaveSpace');
      await callable.call<void>({'spaceId': spaceId});
    } on FirebaseFunctionsException catch (e) {
      throw _mapFunctionsException(e, 'rời Space');
    }
  }

  @override
  Future<void> kickMember({
    required String spaceId,
    required String targetUid,
  }) async {
    try {
      final callable = _functions.httpsCallable('kickMember');
      await callable.call<void>({
        'spaceId': spaceId,
        'targetUid': targetUid,
      });
    } on FirebaseFunctionsException catch (e) {
      throw _mapFunctionsException(e, 'xoá thành viên');
    }
  }

  @override
  Future<void> transferOwnership({
    required String spaceId,
    required String newCreatorUid,
  }) async {
    try {
      final callable = _functions.httpsCallable('transferOwnership');
      await callable.call<void>({
        'spaceId': spaceId,
        'newCreatorUid': newCreatorUid,
      });
    } on FirebaseFunctionsException catch (e) {
      throw _mapFunctionsException(e, 'chuyển quyền quản trị');
    }
  }

  /// Map [FirebaseFunctionsException] sang [AppError] tương ứng.
  ///
  /// [action] là động từ tiếng Việt mô tả thao tác (vd "tạo Space",
  /// "rời Space") — dùng cho fallback message khi server không trả message.
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
