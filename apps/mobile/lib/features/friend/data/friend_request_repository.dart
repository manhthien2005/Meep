import 'package:meep/features/friend/data/friend_request.dart';

abstract class FriendRequestRepository {
  /// Stream of incoming pending requests for [receiverUid].
  Stream<List<FriendRequest>> watchPendingRequests(String receiverUid);

  /// Send a friend request. Throws [ValidationError] if already sent.
  Future<void> sendFriendRequest({
    required String senderUid,
    required String receiverUid,
  });

  /// Accept a friend request via Cloud Function.
  /// Creates friendship + conversation + increments friendCount.
  /// Throws if sender or receiver already has 20 friends.
  Future<void> acceptFriendRequest(String requestId);

  /// Cancel a sent friend request.
  Future<void> cancelFriendRequest(String requestId);

  /// Decline an incoming friend request.
  Future<void> declineFriendRequest(String requestId);
}
