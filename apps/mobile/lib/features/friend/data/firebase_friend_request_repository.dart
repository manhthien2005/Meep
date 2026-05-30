import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:meep/features/friend/data/friend_request.dart';
import 'package:meep/features/friend/data/friend_request_repository.dart';

class FirebaseFriendRequestRepository implements FriendRequestRepository {
  FirebaseFriendRequestRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<FriendRequest>> watchPendingRequests(String receiverUid) {
    return _firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: receiverUid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => FriendRequest.fromJson({
              ...doc.data(),
              'requestId': doc.id,
            }),
          )
          .toList();
    });
  }

  @override
  Future<void> sendFriendRequest({
    required String senderUid,
    required String receiverUid,
  }) async {
    if (senderUid == receiverUid) {
      throw Exception('Cannot send friend request to yourself');
    }

    await _firestore.collection('friend_requests').add({
      'senderId': senderUid,
      'receiverId': receiverUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> acceptFriendRequest(String requestId) async {
    final callable = _functions.httpsCallable('acceptFriendRequest');
    await callable.call<Map<String, dynamic>>({'requestId': requestId});
  }

  @override
  Future<void> cancelFriendRequest(String requestId) async {
    await _firestore.collection('friend_requests').doc(requestId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> declineFriendRequest(String requestId) async {
    await _firestore.collection('friend_requests').doc(requestId).update({
      'status': 'declined',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
