import 'package:meep/features/space/data/space.dart';

abstract class SpaceRepository {
  /// Stream of spaces where [uid] is a member (includes creator).
  Stream<List<Space>> watchMySpaces(String uid);

  /// Get a single Space by ID.
  Future<Space?> getSpace(String spaceId);

  /// Soft-delete a Space — sets deletedAt. Creator only.
  Future<void> deleteSpace(String spaceId);
}
