import 'package:meep/features/auth/data/public_profile.dart';

abstract class FriendRepository {
  /// Search user by exact username match (case-insensitive).
  /// Returns the user if found, null otherwise.
  Future<PublicProfile?> searchUser(String username);

  /// Stream of current user's accepted friends.
  Stream<List<PublicProfile>> watchFriends(String uid);

  /// Returns UIDs of all friends — used for feed filtering.
  Future<List<String>> getFriendUids(String uid);

  /// Remove an existing friendship by pairId. Bidirectional.
  /// Use [pairIdOf] to compute the pairId from two UIDs.
  Future<void> unfriend(String pairId);
}
