import 'dart:async';

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
    String? errorMessage,
  }) = _ReactionState;

  const ReactionState._();

  /// Top N reactors theo `createdAt` DESC. Dùng cho avatar stack
  /// `OwnPostActBar` (Figma 472:2052) — KHÔNG cần thêm method vào
  /// abstract repository (Decision A — compute trong State).
  List<Reaction> topNReactors(int n) {
    final sorted = [...reactions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(n).toList();
  }
}

@Riverpod(keepAlive: true)
ReactionRepository reactionRepository(Ref ref) => throw UnimplementedError(
      'reactionRepositoryProvider must be overridden — '
      'wire FirebaseReactionRepository in main.dart (TODO: R/T3/NganTNK)',
    );

@riverpod
class ReactionController extends _$ReactionController {
  late String _postId;

  @override
  ReactionState build(String postId) {
    _postId = postId;
    final repo = ref.watch(reactionRepositoryProvider);
    final sub = repo.watchReactions(postId).listen((reactions) {
      state = state.copyWith(reactions: reactions);
    });
    ref.onDispose(sub.cancel);
    return const ReactionState();
  }

  /// Toggle reaction theo spec §toggleReact:
  /// - existing == null              → upsertReaction (react lần đầu)
  /// - existing.emoji == emoji       → deleteReaction (un-react)
  /// - existing.emoji != emoji       → upsertReaction (change)
  ///
  /// Optimistic update: state thay đổi ngay, rollback khi Firestore fail.
  /// In-flight lock: tap thứ 2 bị bỏ qua khi `isSubmitting`.
  Future<void> toggleReact({
    required String uid,
    required String displayName,
    required String emoji,
  }) async {
    if (state.isSubmitting) return; // in-flight lock

    final repo = ref.read(reactionRepositoryProvider);
    final prevState = state;

    final Reaction? existing;
    try {
      existing = await repo.getMyReaction(postId: _postId, uid: uid);
    } catch (_) {
      // Không thể detect existing → bail out, không touch state.
      state = state.copyWith(
        errorMessage: 'Thả cảm xúc thất bại — thử lại',
      );
      return;
    }

    final optimisticReactions = _applyOptimistic(
      current: state.reactions,
      existing: existing,
      uid: uid,
      displayName: displayName,
      emoji: emoji,
    );
    final newMyEmoji = (existing?.emoji == emoji) ? null : emoji;
    state = state.copyWith(
      isSubmitting: true,
      reactions: optimisticReactions,
      myEmoji: newMyEmoji,
      errorMessage: null,
    );

    try {
      if (existing != null && existing.emoji == emoji) {
        await repo.deleteReaction(postId: _postId, reactorUid: uid);
      } else {
        await repo.upsertReaction(
          postId: _postId,
          reactorUid: uid,
          reactorName: displayName,
          emoji: emoji,
        );
      }
      state = state.copyWith(isSubmitting: false);
    } catch (_) {
      state = prevState.copyWith(
        isSubmitting: false,
        errorMessage: 'Thả cảm xúc thất bại — thử lại',
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Tính reactions list sau optimistic update. createdAt = now (client clock)
  /// — sẽ được replace bởi serverTimestamp từ watchReactions stream khi
  /// Firestore confirm. Đủ chính xác cho UI feedback < 1s.
  static List<Reaction> _applyOptimistic({
    required List<Reaction> current,
    required Reaction? existing,
    required String uid,
    required String displayName,
    required String emoji,
  }) {
    if (existing == null) {
      // react lần đầu — append
      return [
        ...current,
        Reaction(
          reactorUid: uid,
          reactorName: displayName,
          emoji: emoji,
          createdAt: DateTime.now(),
        ),
      ];
    }
    if (existing.emoji == emoji) {
      // un-react — remove
      return current.where((r) => r.reactorUid != uid).toList();
    }
    // change emoji — overwrite
    return current
        .map((r) => r.reactorUid == uid ? r.copyWith(emoji: emoji) : r)
        .toList();
  }
}
