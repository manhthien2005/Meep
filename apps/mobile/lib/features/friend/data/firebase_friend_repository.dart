import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/auth/data/public_profile.dart';
import 'package:meep/features/friend/data/friend_repository.dart';
import 'package:meep/features/friend/data/friendship.dart';

class FirebaseFriendRepository implements FriendRepository {
  FirebaseFriendRepository(this._firestore);

  final FirebaseFirestore _firestore;
  static const int _whereInLimit = 10;

  @override
  Future<PublicProfile?> searchUser(String username) async {
    final query = username.toLowerCase().trim();
    if (query.isEmpty) return null;

    final QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _firestore
          .collectionGroup('public')
          .where('username', isEqualTo: query)
          .where('isSearchable', isEqualTo: true)
          .limit(1)
          .get();
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e, 'tìm bạn bè');
    }

    if (snapshot.docs.isEmpty) return null;

    return PublicProfile.fromFirestore(snapshot.docs.first);
  }

  @override
  Stream<List<PublicProfile>> watchFriends(String uid) {
    return _firestore
        .collection('friendships')
        .where('members', arrayContains: uid)
        .snapshots()
        .asyncMap((snapshot) async {
      try {
        if (snapshot.docs.isEmpty) return <PublicProfile>[];

        final friendUids = <String>[];
        for (final doc in snapshot.docs) {
          final friendship = Friendship.fromJson(doc.data());
          final friendUid =
              friendship.uid1 == uid ? friendship.uid2 : friendship.uid1;
          friendUids.add(friendUid);
        }

        if (friendUids.isEmpty) return <PublicProfile>[];

        return _fetchPublicProfiles(friendUids);
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

  Future<List<PublicProfile>> _fetchPublicProfiles(
    List<String> friendUids,
  ) async {
    final profilesByUid = <String, PublicProfile>{};

    for (var i = 0; i < friendUids.length; i += _whereInLimit) {
      final end = (i + _whereInLimit > friendUids.length)
          ? friendUids.length
          : i + _whereInLimit;
      final chunk = friendUids.sublist(i, end);
      final snapshot = await _firestore
          .collectionGroup('public')
          .where('uid', whereIn: chunk)
          .get();

      for (final doc in snapshot.docs) {
        final profile = PublicProfile.fromFirestore(doc);
        profilesByUid[profile.uid] = profile;
      }
    }

    return friendUids
        .map((friendUid) => profilesByUid[friendUid])
        .whereType<PublicProfile>()
        .toList();
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
