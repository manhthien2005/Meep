import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/reaction/data/firebase_reaction_repository.dart';
import 'package:meep/features/reaction/data/reaction.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirebaseReactionRepository repo;

  const postId = 'post-1';
  const reactorUid = 'uid-alice';
  const reactorName = 'Alice';

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirebaseReactionRepository(db);
  });

  CollectionReference<Map<String, dynamic>> reactionsRef() =>
      db.collection('posts').doc(postId).collection('reactions');

  group('upsertReaction', () {
    test('creates doc with docId = reactorUid (NOT add())', () async {
      await repo.upsertReaction(
        postId: postId,
        reactorUid: reactorUid,
        reactorName: reactorName,
        emoji: '🤣',
      );

      // Doc tồn tại tại đường dẫn /posts/{postId}/reactions/{reactorUid}
      final snap = await reactionsRef().doc(reactorUid).get();
      expect(snap.exists, isTrue);
      expect(snap.data()!['reactorUid'], reactorUid);
      expect(snap.data()!['reactorName'], reactorName);
      expect(snap.data()!['emoji'], '🤣');

      // Subcollection chỉ chứa đúng 1 doc — chứng minh KHÔNG dùng add() (sẽ tạo doc auto-id).
      final all = await reactionsRef().get();
      expect(all.docs.length, 1);
      expect(all.docs.first.id, reactorUid);
    });

    test('second upsert with different emoji overwrites in place', () async {
      await repo.upsertReaction(
        postId: postId,
        reactorUid: reactorUid,
        reactorName: reactorName,
        emoji: '🤣',
      );
      await repo.upsertReaction(
        postId: postId,
        reactorUid: reactorUid,
        reactorName: reactorName,
        emoji: '🥰',
      );

      final all = await reactionsRef().get();
      expect(all.docs.length, 1); // overwrite, không tạo doc mới
      expect(all.docs.first.data()['emoji'], '🥰');
    });

    test('sets createdAt via serverTimestamp', () async {
      await repo.upsertReaction(
        postId: postId,
        reactorUid: reactorUid,
        reactorName: reactorName,
        emoji: '🤣',
      );

      final snap = await reactionsRef().doc(reactorUid).get();
      // FakeFirebaseFirestore resolve serverTimestamp → Timestamp instance.
      expect(snap.data()!['createdAt'], isA<Timestamp>());
    });
  });

  group('deleteReaction', () {
    test('removes the doc', () async {
      await repo.upsertReaction(
        postId: postId,
        reactorUid: reactorUid,
        reactorName: reactorName,
        emoji: '🤣',
      );
      await repo.deleteReaction(postId: postId, reactorUid: reactorUid);

      final snap = await reactionsRef().doc(reactorUid).get();
      expect(snap.exists, isFalse);
    });

    test('does not throw when doc is missing', () async {
      // Acceptance criteria: delete idempotent — re-tap khi đã un-react không vỡ.
      await expectLater(
        repo.deleteReaction(postId: postId, reactorUid: 'never-reacted'),
        completes,
      );
    });
  });

  group('getMyReaction', () {
    test('returns null when user has not reacted', () async {
      final result = await repo.getMyReaction(postId: postId, uid: reactorUid);
      expect(result, isNull);
    });

    test('returns Reaction when user has reacted', () async {
      await repo.upsertReaction(
        postId: postId,
        reactorUid: reactorUid,
        reactorName: reactorName,
        emoji: '🥰',
      );

      final result = await repo.getMyReaction(postId: postId, uid: reactorUid);
      expect(result, isA<Reaction>());
      expect(result!.reactorUid, reactorUid);
      expect(result.reactorName, reactorName);
      expect(result.emoji, '🥰');
    });
  });

  group('watchReactions', () {
    test('emits empty list when subcollection is empty', () async {
      final first = await repo.watchReactions(postId).first;
      expect(first, isEmpty);
    });

    test('emits all reactions across multiple reactors', () async {
      await repo.upsertReaction(
        postId: postId,
        reactorUid: 'uid-alice',
        reactorName: 'Alice',
        emoji: '🤣',
      );
      await repo.upsertReaction(
        postId: postId,
        reactorUid: 'uid-bob',
        reactorName: 'Bob',
        emoji: '🥰',
      );

      final list = await repo.watchReactions(postId).first;
      expect(list.length, 2);
      expect(
        list.map((Reaction r) => r.reactorUid),
        containsAll(['uid-alice', 'uid-bob']),
      );
    });

    test('re-emits when a reaction is added', () async {
      // Verify realtime: stream emit lần 2 khi có doc mới.
      final stream = repo.watchReactions(postId);
      final values = <List<Reaction>>[];
      final sub = stream.listen(values.add);

      // Cho lần emit đầu (empty) chạy.
      await Future<void>.delayed(Duration.zero);
      await repo.upsertReaction(
        postId: postId,
        reactorUid: reactorUid,
        reactorName: reactorName,
        emoji: '🤣',
      );
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(values.length, greaterThanOrEqualTo(2));
      expect(values.last.length, 1);
      expect(values.last.first.emoji, '🤣');
    });
  });
}
