import 'package:meep/features/space/data/space.dart';

/// Single source of truth cho mọi Space data ops — Firestore reads + CF mutations.
///
/// **Option A (#133):** repository wrap `httpsCallable` cho 4 CF mutations
/// (`createSpace`, `leaveSpace`, `kickMember`, `transferOwnership`), parallel
/// với [FriendRequestRepository.acceptFriendRequest]. Controller chỉ depend
/// abstract này — KHÔNG inject [FirebaseFunctions] trực tiếp.
abstract class SpaceRepository {
  // ===== Firestore reads =====

  /// Stream of spaces where [uid] is a member (includes creator).
  /// Filters out soft-deleted spaces (`deletedAt != null`).
  Stream<List<Space>> watchMySpaces(String uid);

  /// Get a single Space by ID. Returns null if not found or soft-deleted.
  Future<Space?> getSpace(String spaceId);

  /// Soft-delete a Space — sets `deletedAt = serverTimestamp()`. Creator only
  /// (Firestore rule enforces). Client-side guard cũng check creator ở
  /// controller layer để fail-fast trước khi gọi Firestore.
  Future<void> deleteSpace(String spaceId);

  // ===== Cloud Function mutations (httpsCallable wrappers) =====

  /// Calls CF `createSpace` (region `asia-southeast1`).
  ///
  /// Server tạo `/spaces/{spaceId}` + `/space_members/{spaceId}/members/*` +
  /// `/conversations/{spaceId}` (group chat). Returns server-generated
  /// `spaceId`.
  ///
  /// Throws [AppError] on CF error: [ValidationError] (`name` rỗng /
  /// `friendUids` > 9), [NetworkError] (offline), [UnexpectedError] (other).
  Future<String> createSpace({
    required String name,
    required String iconEmoji,
    required String colorHex,
    required List<String> friendUids,
  });

  /// Calls CF `leaveSpace`. Server enforces creator phải `transferOwnership`
  /// trước khi leave — throw [ValidationError] nếu vi phạm.
  Future<void> leaveSpace(String spaceId);

  /// Calls CF `kickMember`. Creator-only (server-enforced).
  Future<void> kickMember({
    required String spaceId,
    required String targetUid,
  });

  /// Calls CF `transferOwnership`. Creator-only + target phải là member
  /// (server-enforced).
  Future<void> transferOwnership({
    required String spaceId,
    required String newCreatorUid,
  });
}
