import 'package:meep/features/auth/data/user_profile.dart';

abstract class FriendRepository {
  /// Search users by display name or username prefix. Max 20 results.
  Future<List<UserProfile>> searchUser(String query);

  /// Stream of current user's accepted friends.
  Stream<List<UserProfile>> watchFriends(String uid);

  /// Returns UIDs of all friends — used for feed filtering.
  Future<List<String>> getFriendUids(String uid);

  /// Remove an existing friendship. Bidirectional.
  Future<void> unfriend({required String uid, required String friendUid});
}
