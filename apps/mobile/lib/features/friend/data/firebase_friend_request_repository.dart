import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:meep/core/error/app_error.dart';
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
  Stream<List<FriendRequest>> watchSentRequests(String senderUid) {
    return _firestore
        .collection('friend_requests')
        .where('senderId', isEqualTo: senderUid)
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
      throw const ValidationError(
        message: 'Cannot send friend request to yourself',
      );
    }

    // Idempotent guard: bỏ qua nếu đã có pending request cùng chiều — chặn spam
    // tap tạo nhiều doc trùng. Lưu ý: đây là client-side check, vẫn còn race
    // window khi tap cực nhanh; enforce tuyệt đối cần Firestore rules / CF
    // (deterministic doc id theo cặp sender_receiver) — flag leader.
    final existing = await _firestore
        .collection('friend_requests')
        .where('senderId', isEqualTo: senderUid)
        .where('receiverId', isEqualTo: receiverUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

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
