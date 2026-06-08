import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/friend/data/friend_repository.dart';
import 'package:meep/features/friend/data/friendship.dart';

class FirebaseFriendRepository implements FriendRepository {
  FirebaseFriendRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<UserProfile?> searchUser(String username) async {
    final query = username.toLowerCase().trim();
    if (query.isEmpty) return null;

    final QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: query)
          .limit(1)
          .get();
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e, 'tìm bạn bè');
    }

    if (snapshot.docs.isEmpty) return null;

    return UserProfile.fromJson(snapshot.docs.first.data());
  }

  @override
  Stream<List<UserProfile>> watchFriends(String uid) {
    return _firestore
        .collection('friendships')
        .where('members', arrayContains: uid)
        .snapshots()
        .asyncMap((snapshot) async {
      try {
        if (snapshot.docs.isEmpty) return <UserProfile>[];

        // Extract friend UIDs
        final friendUids = <String>[];
        for (final doc in snapshot.docs) {
          final friendship = Friendship.fromJson(doc.data());
          final friendUid =
              friendship.uid1 == uid ? friendship.uid2 : friendship.uid1;
          friendUids.add(friendUid);
        }

        // Batch fetch user profiles
        if (friendUids.isEmpty) return <UserProfile>[];

        final userDocs = await Future.wait(
          friendUids
              .map((fuid) => _firestore.collection('users').doc(fuid).get()),
        );

        return userDocs
            .where((doc) => doc.exists)
            .map((doc) => UserProfile.fromJson(doc.data()!))
            .toList();
      } on FirebaseException catch (e) {
        throw _mapFirestoreError(e, 'tải danh sách bạn bè');
      }
    }).handleError((Object e, StackTrace s) {
      if (e is FirebaseException) {
        throw _mapFirestoreError(e, 'tải danh sách bạn bè');
      }
      Error.throwWithStackTrace(e, s);
    });
  }

  @override
  Future<List<String>> getFriendUids(String uid) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _firestore
          .collection('friendships')
          .where('members', arrayContains: uid)
          .get();
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e, 'tải mã bạn bè');
    }

    if (snapshot.docs.isEmpty) return [];

    return snapshot.docs.map((doc) {
      final friendship = Friendship.fromJson(doc.data());
      return friendship.uid1 == uid ? friendship.uid2 : friendship.uid1;
    }).toList();
  }

  @override
  Future<void> unfriend(String pairId) async {
    try {
      await _firestore.collection('friendships').doc(pairId).delete();
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e, 'xoá bạn bè');
    }
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
          message: serverMessage ?? 'Không tìm thấy dữ liệu bạn bè',
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
