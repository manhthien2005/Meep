import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:meep/features/space/data/firebase_space_repository.dart';
import 'package:meep/features/space/data/space.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseFunctions functions;
  late FirebaseSpaceRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    functions = MockFirebaseFunctions();
    repository = FirebaseSpaceRepository(firestore, functions);
  });

  Map<String, dynamic> spaceDoc({
    required String spaceId,
    required String name,
    required String creatorId,
    required List<String> memberIds,
    String iconEmoji = '👥',
    String colorHex = '#00DEEE',
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return {
      'spaceId': spaceId,
      'name': name,
      'iconEmoji': iconEmoji,
      'colorHex': colorHex,
      'creatorId': creatorId,
      'memberCount': memberIds.length,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt ?? DateTime(2026, 6, 1)),
      if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt),
    };
  }

  group('watchMySpaces', () {
    test('streams spaces where uid in memberIds', () async {
      const uid = 'user1';
      await firestore.collection('spaces').doc('s1').set(
            spaceDoc(
              spaceId: 's1',
              name: 'Family',
              creatorId: uid,
              memberIds: [uid, 'user2'],
            ),
          );
      await firestore.collection('spaces').doc('s2').set(
            spaceDoc(
              spaceId: 's2',
              name: 'Friends',
              creatorId: 'user3',
              memberIds: ['user3', uid],
            ),
          );

      final stream = repository.watchMySpaces(uid);

      await expectLater(
        stream,
        emits(
          predicate<List<Space>>((list) {
            final ids = list.map((s) => s.spaceId).toSet();
            return list.length == 2 && ids.containsAll(['s1', 's2']);
          }),
        ),
      );
    });

    test('excludes spaces where uid is not a member', () async {
      const uid = 'user1';
      await firestore.collection('spaces').doc('s1').set(
            spaceDoc(
              spaceId: 's1',
              name: 'Other group',
              creatorId: 'user2',
              memberIds: ['user2', 'user3'],
            ),
          );

      final stream = repository.watchMySpaces(uid);

      await expectLater(stream, emits(isEmpty));
    });

    test('filters out soft-deleted spaces', () async {
      const uid = 'user1';
      await firestore.collection('spaces').doc('s1').set(
            spaceDoc(
              spaceId: 's1',
              name: 'Active',
              creatorId: uid,
              memberIds: [uid],
            ),
          );
      await firestore.collection('spaces').doc('s2').set(
            spaceDoc(
              spaceId: 's2',
              name: 'Deleted',
              creatorId: uid,
              memberIds: [uid],
              deletedAt: DateTime(2026, 5, 30),
            ),
          );

      final stream = repository.watchMySpaces(uid);

      await expectLater(
        stream,
        emits(
          predicate<List<Space>>((list) {
            return list.length == 1 && list.first.spaceId == 's1';
          }),
        ),
      );
    });

    test('returns empty list when no spaces', () async {
      final stream = repository.watchMySpaces('user1');

      await expectLater(stream, emits(isEmpty));
    });
  });

  group('getSpace', () {
    test('returns Space when doc exists', () async {
      await firestore.collection('spaces').doc('s1').set(
            spaceDoc(
              spaceId: 's1',
              name: 'Family',
              creatorId: 'user1',
              memberIds: ['user1', 'user2'],
            ),
          );

      final result = await repository.getSpace('s1');

      expect(result, isNotNull);
      expect(result!.spaceId, 's1');
      expect(result.name, 'Family');
      expect(result.memberIds, ['user1', 'user2']);
    });

    test('returns null when doc not found', () async {
      final result = await repository.getSpace('nonexistent');

      expect(result, isNull);
    });

    test('returns null when doc soft-deleted', () async {
      await firestore.collection('spaces').doc('s1').set(
            spaceDoc(
              spaceId: 's1',
              name: 'Deleted',
              creatorId: 'user1',
              memberIds: ['user1'],
              deletedAt: DateTime(2026, 5, 30),
            ),
          );

      final result = await repository.getSpace('s1');

      expect(result, isNull);
    });
  });

  group('deleteSpace', () {
    test('sets deletedAt field (soft delete)', () async {
      await firestore.collection('spaces').doc('s1').set(
            spaceDoc(
              spaceId: 's1',
              name: 'Family',
              creatorId: 'user1',
              memberIds: ['user1'],
            ),
          );

      await repository.deleteSpace('s1');

      final doc = await firestore.collection('spaces').doc('s1').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['deletedAt'], isNotNull);
    });

    test('keeps document existing (not hard delete)', () async {
      await firestore.collection('spaces').doc('s1').set(
            spaceDoc(
              spaceId: 's1',
              name: 'Family',
              creatorId: 'user1',
              memberIds: ['user1'],
            ),
          );

      await repository.deleteSpace('s1');

      final doc = await firestore.collection('spaces').doc('s1').get();
      expect(doc.exists, isTrue);
      // Other fields preserved
      expect(doc.data()!['name'], 'Family');
      expect(doc.data()!['creatorId'], 'user1');
    });
  });
}
