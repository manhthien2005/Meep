import 'package:meep/features/reaction/data/reaction.dart';

abstract class ReactionRepository {
  /// Stream of all reactions on [postId].
  Stream<List<Reaction>> watchReactions(String postId);

  /// Create or replace the calling user's reaction on [postId].
  Future<void> upsertReaction({
    required String postId,
    required String reactorUid,
    required String reactorName,
    required String emoji,
  });

  /// Delete the calling user's reaction on [postId].
  Future<void> deleteReaction({
    required String postId,
    required String reactorUid,
  });

  /// [H2-FIX] Get the calling user's current reaction, or null if none.
  /// Required for toggleReact to detect existing reaction.
  Future<Reaction?> getMyReaction({
    required String postId,
    required String uid,
  });
}
