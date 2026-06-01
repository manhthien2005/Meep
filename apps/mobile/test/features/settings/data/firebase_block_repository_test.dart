import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:meep/features/settings/data/block.dart';
import 'package:meep/features/settings/data/firebase_block_repository.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseFunctions functions;
  late FirebaseBlockRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    functions = MockFirebaseFunctions();
    repository = FirebaseBlockRepository(firestore, functions);
  });

  Map<String, dynamic> blockDoc({
    required String blockerUid,
    required String blockedUid,
    DateTime? createdAt,
  }) {
    return {
      'blockId': '${blockerUid}_$blockedUid',
      'blockerUid': blockerUid,
      'blockedUid': blockedUid,
      'createdAt': Timestamp.fromDate(createdAt ?? DateTime(2026, 6, 1)),
    };
  }

  group('unblockUser', () {
    test('xoá doc /blocks/{blockerUid}_{targetUid}', () async {
      const blockerUid = 'me';
      const targetUid = 'target';
      const blockId = '${blockerUid}_$targetUid';

      await firestore.collection('blocks').doc(blockId).set(
            blockDoc(blockerUid: blockerUid, blockedUid: targetUid),
          );

      await repository.unblockUser(
        blockerUid: blockerUid,
        targetUid: targetUid,
      );

      final doc = await firestore.collection('blocks').doc(blockId).get();
      expect(doc.exists, isFalse);
    });

    test('KHÔNG xoá doc chiều ngược (target chặn me)', () async {
      const blockerUid = 'me';
      const targetUid = 'target';
      const reverseId = '${targetUid}_$blockerUid';

      await firestore.collection('blocks').doc(reverseId).set(
            blockDoc(blockerUid: targetUid, blockedUid: blockerUid),
          );

      await repository.unblockUser(
        blockerUid: blockerUid,
        targetUid: targetUid,
      );

      final doc = await firestore.collection('blocks').doc(reverseId).get();
      expect(doc.exists, isTrue);
    });
  });

  group('isBlocked', () {
    test('true khi uid1 chặn uid2', () async {
      await firestore.collection('blocks').doc('a_b').set(
            blockDoc(blockerUid: 'a', blockedUid: 'b'),
          );

      final result = await repository.isBlocked(uid1: 'a', uid2: 'b');
      expect(result, isTrue);
    });

    test('true khi uid2 chặn uid1 (chiều ngược)', () async {
      await firestore.collection('blocks').doc('b_a').set(
            blockDoc(blockerUid: 'b', blockedUid: 'a'),
          );

      final result = await repository.isBlocked(uid1: 'a', uid2: 'b');
      expect(result, isTrue);
    });

    test('false khi không có block nào giữa 2 uid', () async {
      // Có block của cặp khác không liên quan.
      await firestore.collection('blocks').doc('x_y').set(
            blockDoc(blockerUid: 'x', blockedUid: 'y'),
          );

      final result = await repository.isBlocked(uid1: 'a', uid2: 'b');
      expect(result, isFalse);
    });
  });

  group('watchBlockedUsers', () {
    test('stream chỉ doc do blockerUid tạo (loại doc người khác chặn me)',
        () async {
      const me = 'me';
      await firestore.collection('blocks').doc('${me}_target1').set(
            blockDoc(blockerUid: me, blockedUid: 'target1'),
          );
      await firestore.collection('blocks').doc('${me}_target2').set(
            blockDoc(blockerUid: me, blockedUid: 'target2'),
          );
      // Doc người khác chặn me — không được lọt vào stream.
      await firestore.collection('blocks').doc('stranger_$me').set(
            blockDoc(blockerUid: 'stranger', blockedUid: me),
          );

      final stream = repository.watchBlockedUsers(me);

      await expectLater(
        stream,
        emits(
          predicate<List<Block>>((list) {
            final ids = list.map((b) => b.blockedUid).toSet();
            return list.length == 2 &&
                ids.containsAll(['target1', 'target2']) &&
                list.every((b) => b.blockerUid == me);
          }),
        ),
      );
    });

    test('empty list khi chưa chặn ai', () async {
      final stream = repository.watchBlockedUsers('lonely');
      await expectLater(stream, emits(isEmpty));
    });
  });
}
