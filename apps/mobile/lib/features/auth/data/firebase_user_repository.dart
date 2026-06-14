import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meep/features/auth/data/public_profile.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/auth/data/user_repository.dart';

class FirebaseUserRepository implements UserRepository {
  FirebaseUserRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<void> createProfile(UserProfile profile) async {
    final username = profile.username.toLowerCase();
    final batch = _firestore.batch();

    final userRef = _firestore.doc('users/${profile.uid}');
    batch.set(userRef, {
      ...profile.toJson(),
      'username': username,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final usernameRef = _firestore.doc('usernames/$username');
    batch.set(usernameRef, {'uid': profile.uid});

    await batch.commit();
  }

  @override
  Future<UserProfile?> getProfile(String uid) async {
    final snap = await _firestore.doc('users/$uid').get();
    if (!snap.exists) return null;
    return UserProfile.fromJson(snap.data()!);
  }

  @override
  Future<PublicProfile?> getPublicProfile(String uid) async {
    final publicSnap = await _firestore.doc('users/$uid/public/profile').get();
    if (publicSnap.exists) return PublicProfile.fromFirestore(publicSnap);

    final userSnap = await _getUserDocForPublicFallback(uid);
    if (userSnap == null) return null;
    final data = userSnap.data();
    if (!userSnap.exists || data == null) return null;
    return _publicProfileFromUserData(uid, data);
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final snap =
        await _firestore.doc('usernames/${username.toLowerCase()}').get();
    return !snap.exists;
  }

  /// Stream of the user's profile — emits null when doc doesn't exist.
  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _firestore.doc('users/$uid').snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserProfile.fromJson(snap.data()!);
    });
  }

  @override
  Stream<PublicProfile?> watchPublicProfile(String uid) {
    return _firestore.doc('users/$uid/public/profile').snapshots().asyncMap(
      (snap) async {
        if (snap.exists) return PublicProfile.fromFirestore(snap);

        final userSnap = await _getUserDocForPublicFallback(uid);
        if (userSnap == null) return null;
        final data = userSnap.data();
        if (!userSnap.exists || data == null) return null;
        return _publicProfileFromUserData(uid, data);
      },
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _getUserDocForPublicFallback(
    String uid,
  ) async {
    try {
      return _firestore.doc('users/$uid').get();
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
}
