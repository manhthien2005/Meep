import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/reaction/data/reaction.dart';
import 'package:meep/features/reaction/data/reaction_repository.dart';

part 'reaction_controller.freezed.dart';
part 'reaction_controller.g.dart';

@freezed
class ReactionState with _$ReactionState {
  const factory ReactionState({
    @Default([]) List<Reaction> reactions,
    @Default(false) bool isSubmitting,
    String? myEmoji,
  }) = _ReactionState;
}

@Riverpod(keepAlive: true)
ReactionRepository reactionRepository(Ref ref) => throw UnimplementedError(
      'reactionRepositoryProvider must be overridden — '
      'wire FirestoreReactionRepository in main.dart (TODO: R/T1/TBD)',
    );

@riverpod
class ReactionController extends _$ReactionController {
  @override
  ReactionState build(String postId) => const ReactionState();

  Future<void> toggleReact({
    required String uid,
    required String displayName,
    required String emoji,
  }) async {
    // TODO(R/T2/TBD): getMyReaction → if same emoji delete, else upsert
    throw UnimplementedError('toggleReact — TODO: R/T2/TBD');
  }
}
