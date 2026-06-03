import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/reaction/application/reaction_controller.dart';
import 'package:meep/features/reaction/data/reaction.dart';
import 'package:meep/features/reaction/data/reaction_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockReactionRepository extends Mock implements ReactionRepository {}

Reaction _r({
  required String uid,
  String name = 'User',
  String emoji = '🤣',
  DateTime? createdAt,
}) =>
    Reaction(
      reactorUid: uid,
      reactorName: name,
      emoji: emoji,
      createdAt: createdAt ?? DateTime(2026, 6, 3, 10, 0),
    );

const _postId = 'post-1';
const _myUid = 'uid-alice';
const _myName = 'Alice';

ProviderContainer makeContainer(MockReactionRepository repo) {
  // Mặc định watchReactions trả empty để build() không null-ref.
  // Test cần emit custom thì override trước khi spawn container.
  when(() => repo.watchReactions(any()))
      .thenAnswer((_) => const Stream.empty());
  return ProviderContainer(
    overrides: [reactionRepositoryProvider.overrideWithValue(repo)],
  );
}

void main() {
  setUpAll(() {
    // Mocktail: fallback values cho any() khi method nhận named args.
    registerFallbackValue('');
  });

  group('ReactionController — initial state', () {
    test('reactions=[], isSubmitting=false, myEmoji=null, errorMessage=null',
        () {
      final repo = MockReactionRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final state = container.read(reactionControllerProvider(_postId));
      expect(state.reactions, isEmpty);
      expect(state.isSubmitting, isFalse);
      expect(state.myEmoji, isNull);
      expect(state.errorMessage, isNull);
    });
  });

  group('ReactionController — watchReactions', () {
    test('state.reactions cập nhật theo stream từ repository', () async {
      final repo = MockReactionRepository();
      final streamCtrl = StreamController<List<Reaction>>.broadcast();
      when(() => repo.watchReactions(_postId))
          .thenAnswer((_) => streamCtrl.stream);

      final container = ProviderContainer(
        overrides: [reactionRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      // Capture mọi state change qua container.listen.
      final states = <ReactionState>[];
      container.listen(
        reactionControllerProvider(_postId),
        (prev, next) => states.add(next),
        fireImmediately: true,
      );

      streamCtrl.add([_r(uid: 'uid-bob', name: 'Bob', emoji: '🥰')]);
      // Pump đủ microtasks để listener fire + state update.
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(states.last.reactions.length, 1);
      expect(states.last.reactions.first.reactorUid, 'uid-bob');

      await streamCtrl.close();
    });
  });

  group('ReactionController — toggleReact', () {
    test('existing == null → upsertReaction (react lần đầu)', () async {
      final repo = MockReactionRepository();
      when(() => repo.getMyReaction(postId: _postId, uid: _myUid))
          .thenAnswer((_) async => null);
      when(
        () => repo.upsertReaction(
          postId: any(named: 'postId'),
          reactorUid: any(named: 'reactorUid'),
          reactorName: any(named: 'reactorName'),
          emoji: any(named: 'emoji'),
        ),
      ).thenAnswer((_) async {});

      final container = makeContainer(repo);
      addTearDown(container.dispose);

      await container
          .read(reactionControllerProvider(_postId).notifier)
          .toggleReact(uid: _myUid, displayName: _myName, emoji: '🤣');

      verify(
        () => repo.upsertReaction(
          postId: _postId,
          reactorUid: _myUid,
          reactorName: _myName,
          emoji: '🤣',
        ),
      ).called(1);
      verifyNever(
        () => repo.deleteReaction(
          postId: any(named: 'postId'),
          reactorUid: any(named: 'reactorUid'),
        ),
      );
      final state = container.read(reactionControllerProvider(_postId));
      expect(state.myEmoji, '🤣');
      expect(state.isSubmitting, isFalse);
    });

    test('existing.emoji == emoji → deleteReaction (un-react)', () async {
      final repo = MockReactionRepository();
      when(() => repo.getMyReaction(postId: _postId, uid: _myUid)).thenAnswer(
        (_) async => _r(uid: _myUid, name: _myName, emoji: '🤣'),
      );
      when(
        () => repo.deleteReaction(
          postId: any(named: 'postId'),
          reactorUid: any(named: 'reactorUid'),
        ),
      ).thenAnswer((_) async {});

      final container = makeContainer(repo);
      addTearDown(container.dispose);

      await container
          .read(reactionControllerProvider(_postId).notifier)
          .toggleReact(uid: _myUid, displayName: _myName, emoji: '🤣');

      verify(() => repo.deleteReaction(postId: _postId, reactorUid: _myUid))
          .called(1);
      verifyNever(
        () => repo.upsertReaction(
          postId: any(named: 'postId'),
          reactorUid: any(named: 'reactorUid'),
          reactorName: any(named: 'reactorName'),
          emoji: any(named: 'emoji'),
        ),
      );
      final state = container.read(reactionControllerProvider(_postId));
      expect(state.myEmoji, isNull); // un-react → myEmoji null
    });

    test('existing.emoji != emoji → upsertReaction (change emoji)', () async {
      final repo = MockReactionRepository();
      when(() => repo.getMyReaction(postId: _postId, uid: _myUid)).thenAnswer(
        (_) async => _r(uid: _myUid, name: _myName, emoji: '🤣'),
      );
      when(
        () => repo.upsertReaction(
          postId: any(named: 'postId'),
          reactorUid: any(named: 'reactorUid'),
          reactorName: any(named: 'reactorName'),
          emoji: any(named: 'emoji'),
        ),
      ).thenAnswer((_) async {});

      final container = makeContainer(repo);
      addTearDown(container.dispose);

      await container
          .read(reactionControllerProvider(_postId).notifier)
          .toggleReact(uid: _myUid, displayName: _myName, emoji: '🥰');

      verify(
        () => repo.upsertReaction(
          postId: _postId,
          reactorUid: _myUid,
          reactorName: _myName,
          emoji: '🥰',
        ),
      ).called(1);
      final state = container.read(reactionControllerProvider(_postId));
      expect(state.myEmoji, '🥰'); // change → myEmoji = new emoji
    });
  });

  group('ReactionController — optimistic rollback', () {
    test('upsert fail → rollback state + errorMessage set', () async {
      final repo = MockReactionRepository();
      when(() => repo.getMyReaction(postId: _postId, uid: _myUid))
          .thenAnswer((_) async => null);
      when(
        () => repo.upsertReaction(
          postId: any(named: 'postId'),
          reactorUid: any(named: 'reactorUid'),
          reactorName: any(named: 'reactorName'),
          emoji: any(named: 'emoji'),
        ),
      ).thenThrow(Exception('network'));

      final container = makeContainer(repo);
      addTearDown(container.dispose);

      await container
          .read(reactionControllerProvider(_postId).notifier)
          .toggleReact(uid: _myUid, displayName: _myName, emoji: '🤣');

      final state = container.read(reactionControllerProvider(_postId));
      expect(state.errorMessage, contains('Thả cảm xúc thất bại'));
      expect(state.isSubmitting, isFalse);
      // Rollback: myEmoji về null (vì optimistic đã set '🤣', rollback prev null)
      expect(state.myEmoji, isNull);
      // Rollback: reactions giữ nguyên rỗng
      expect(state.reactions, isEmpty);
    });
  });

  group('ReactionController — in-flight lock', () {
    test('tap thứ 2 khi đang submit → bỏ qua', () async {
      final repo = MockReactionRepository();
      // Cả 2 future đều dùng Completer để control timing thủ công.
      final getMyReactionCompleter = Completer<Reaction?>();
      final upsertCompleter = Completer<void>();
      when(() => repo.getMyReaction(postId: _postId, uid: _myUid))
          .thenAnswer((_) => getMyReactionCompleter.future);
      when(
        () => repo.upsertReaction(
          postId: any(named: 'postId'),
          reactorUid: any(named: 'reactorUid'),
          reactorName: any(named: 'reactorName'),
          emoji: any(named: 'emoji'),
        ),
      ).thenAnswer((_) => upsertCompleter.future);

      final container = makeContainer(repo);
      addTearDown(container.dispose);

      // Subscribe để giữ provider alive — `container.read` không subscribe
      // nên provider sẽ bị dispose + reset state giữa các read.
      container.listen(reactionControllerProvider(_postId), (_, __) {});
      final notifier =
          container.read(reactionControllerProvider(_postId).notifier);

      // Tap 1 — start. Suspend ở `await getMyReaction`.
      final future1 = notifier.toggleReact(
        uid: _myUid,
        displayName: _myName,
        emoji: '🤣',
      );

      // Resolve getMyReaction → toggleReact tiếp tục, set isSubmitting=true,
      // suspend ở `await upsertReaction` (vẫn pending).
      getMyReactionCompleter.complete(null);
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(
        container.read(reactionControllerProvider(_postId)).isSubmitting,
        isTrue,
      );

      // Tap 2 — phải bị ignore vì isSubmitting=true.
      await notifier.toggleReact(
        uid: _myUid,
        displayName: _myName,
        emoji: '🥰',
      );

      // Resolve upsert tap 1.
      upsertCompleter.complete();
      await future1;

      // upsert chỉ gọi đúng 1 lần (cho tap 1).
      verify(
        () => repo.upsertReaction(
          postId: _postId,
          reactorUid: _myUid,
          reactorName: _myName,
          emoji: '🤣',
        ),
      ).called(1);
      // getMyReaction chỉ gọi 1 lần (tap 1) — tap 2 early-return ở in-flight check.
      verify(() => repo.getMyReaction(postId: _postId, uid: _myUid)).called(1);
    });
  });

  group('ReactionState — topNReactors getter', () {
    test('trả top N theo createdAt DESC', () {
      const state = ReactionState();
      final reactions = [
        _r(uid: 'u1', createdAt: DateTime(2026, 6, 1)),
        _r(uid: 'u2', createdAt: DateTime(2026, 6, 3)),
        _r(uid: 'u3', createdAt: DateTime(2026, 6, 2)),
        _r(uid: 'u4', createdAt: DateTime(2026, 5, 30)),
      ];
      final populated = state.copyWith(reactions: reactions);

      final top3 = populated.topNReactors(3);
      expect(top3.map((Reaction r) => r.reactorUid), ['u2', 'u3', 'u1']);
    });

    test('n > reactions.length → trả tất cả', () {
      const state = ReactionState();
      final populated = state.copyWith(reactions: [_r(uid: 'u1')]);
      expect(populated.topNReactors(5).length, 1);
    });

    test('empty reactions → empty list', () {
      const state = ReactionState();
      expect(state.topNReactors(3), isEmpty);
    });
  });

  group('ReactionController — clearError', () {
    test('errorMessage về null', () async {
      final repo = MockReactionRepository();
      when(() => repo.getMyReaction(postId: _postId, uid: _myUid))
          .thenAnswer((_) async => null);
      when(
        () => repo.upsertReaction(
          postId: any(named: 'postId'),
          reactorUid: any(named: 'reactorUid'),
          reactorName: any(named: 'reactorName'),
          emoji: any(named: 'emoji'),
        ),
      ).thenThrow(Exception('network'));

      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final notifier =
          container.read(reactionControllerProvider(_postId).notifier);
      await notifier.toggleReact(
        uid: _myUid,
        displayName: _myName,
        emoji: '🤣',
      );
      expect(
        container.read(reactionControllerProvider(_postId)).errorMessage,
        isNotNull,
      );

      notifier.clearError();
      expect(
        container.read(reactionControllerProvider(_postId)).errorMessage,
        isNull,
      );
    });
  });
}
