import 'package:meep/features/settings/data/block.dart';

/// Canonical owner of block logic.
/// Chat and Feed modules import from this path —
/// do NOT define a separate BlockRepository in those modules.
abstract class BlockRepository {
  /// Block [targetUid]. Creates `/blocks/{blockerUid}_{targetUid}`.
  Future<void> blockUser({
    required String blockerUid,
    required String targetUid,
  });

  /// Unblock [targetUid].
  Future<void> unblockUser({
    required String blockerUid,
    required String targetUid,
  });

  /// Stream of users blocked by [blockerUid].
  Stream<List<Block>> watchBlockedUsers(String blockerUid);

  /// True if either direction has a block between [uid1] and [uid2].
  Future<bool> isBlocked({required String uid1, required String uid2});
}
