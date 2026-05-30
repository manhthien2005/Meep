import 'package:cloud_firestore/cloud_firestore.dart';

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

    final snapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: query)
        .limit(1)
        .get();

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
      if (snapshot.docs.isEmpty) return <UserProfile>[];

      // Extract friend UIDs
      final friendUids = <String>[];
      for (final doc in snapshot.docs) {
        final friendship = Friendship.fromJson(doc.data());
        final friendUid = friendship.uid1 == uid ? friendship.uid2 : friendship.uid1;
        friendUids.add(friendUid);
      }

      // Batch fetch user profiles
      if (friendUids.isEmpty) return <UserProfile>[];

      final userDocs = await Future.wait(
        friendUids.map((fuid) => _firestore.collection('users').doc(fuid).get()),
      );

      return userDocs
          .where((doc) => doc.exists)
          .map((doc) => UserProfile.fromJson(doc.data()!))
          .toList();
    });
  }

  @override
  Future<List<String>> getFriendUids(String uid) async {
    final snapshot = await _firestore
        .collection('friendships')
        .where('members', arrayContains: uid)
        .get();

    if (snapshot.docs.isEmpty) return [];

    return snapshot.docs.map((doc) {
      final friendship = Friendship.fromJson(doc.data());
      return friendship.uid1 == uid ? friendship.uid2 : friendship.uid1;
    }).toList();
  }

  @override
  Future<void> unfriend(String pairId) async {
    await _firestore.collection('friendships').doc(pairId).delete();
  }
}
