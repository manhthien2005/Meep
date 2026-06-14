import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/auth/data/public_profile.dart';
import 'package:meep/features/friend/data/friend_repository.dart';
import 'package:meep/features/friend/data/friendship.dart';

class FirebaseFriendRepository implements FriendRepository {
  FirebaseFriendRepository(
    this._firestore, {
    FirebaseFunctions? functions,
  }) : _functions = functions;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions? _functions;
  static const int _whereInLimit = 10;

  @override
  Future<PublicProfile?> searchUser(String username) async {
    final query = username.toLowerCase().trim();
    if (query.isEmpty) return null;

    final functions = _functions;
    if (functions != null) {
      try {
        final result = await _searchUserByCallable(functions, query);
        if (result != null) return result;
      } on FirebaseFunctionsException catch (e) {
        if (e.code != 'not-found' && e.code != 'unimplemented') {
          throw _mapFunctionsError(e, 'tìm bạn bè');
        }
      }
    }

    final publicResult = await _searchUserByPublicProfile(query);
    if (publicResult != null) return publicResult;

    return _searchUserByUserDoc(query);
  }

  Future<PublicProfile?> _searchUserByCallable(
    FirebaseFunctions functions,
    String query,
  ) async {
    final callable = functions.httpsCallable('searchUserByUsername');
    final result = await callable.call<Map<String, dynamic>>({
      'username': query,
    });
    final profileData = result.data['profile'];
    if (profileData == null) return null;

    final profile = Map<String, dynamic>.from(profileData as Map);
    final updatedAtMillis = (profile['updatedAtMillis'] as num).toInt();
    return PublicProfile(
      uid: profile['uid'] as String,
      displayName: profile['displayName'] as String,
      username: profile['username'] as String,
      avatarUrl: profile['avatarUrl'] as String?,
      bio: profile['bio'] as String?,
      isSearchable: profile['isSearchable'] as bool? ?? true,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMillis),
    );
  }

  Future<PublicProfile?> _searchUserByPublicProfile(String query) async {
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

  Future<PublicProfile?> _searchUserByUserDoc(String query) async {
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

    final profile = _publicProfileFromUserData(
      snapshot.docs.first.id,
      snapshot.docs.first.data(),
    );
    if (profile?.isSearchable == false) return null;
    return profile;
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

      final missingUids = chunk
          .where((friendUid) => !profilesByUid.containsKey(friendUid))
          .toList();
      if (missingUids.isEmpty) continue;

      final userDocs = await Future.wait(
        missingUids.map(_getUserDocForPublicFallback),
      );

      for (final doc in userDocs) {
        if (doc == null) continue;
        final data = doc.data();
        if (!doc.exists || data == null) continue;
        final profile = _publicProfileFromUserData(doc.id, data);
        if (profile != null) {
          profilesByUid[profile.uid] = profile;
        }
      }
    }

    return friendUids
        .map((friendUid) => profilesByUid[friendUid])
        .whereType<PublicProfile>()
        .toList();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _getUserDocForPublicFallback(
    String uid,
  ) async {
    try {
      return _firestore.collection('users').doc(uid).get();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return null;
      rethrow;
    }
  }

  PublicProfile? _publicProfileFromUserData(
    String uid,
    Map<String, dynamic> data,
  ) {
    final updatedAt = data['updatedAt'] ?? data['createdAt'];
    if (updatedAt == null) return null;

    return PublicProfile.fromJson({
      ...data,
      'uid': data['uid'] ?? uid,
      'updatedAt': updatedAt,
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

  AppError _mapFunctionsError(FirebaseFunctionsException e, String action) {
    final serverMessage = e.message;
    return switch (e.code) {
      'permission-denied' => ForbiddenError.message(
          message: serverMessage ?? 'Bạn không có quyền $action',
          code: e.code,
          cause: e,
        ),
      'unauthenticated' => UnauthenticatedError(
          message: serverMessage ?? 'Bạn cần đăng nhập để $action',
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
      'invalid-argument' || 'failed-precondition' => ValidationError(
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
