import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/core/utils/pair_id.dart';
import 'package:meep/features/auth/data/public_profile.dart';
import 'package:meep/features/friend/data/firebase_friend_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirebaseFriendRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirebaseFriendRepository(firestore);
  });

  group('searchUser', () {
    test('returns user when exact username match (case-insensitive)', () async {
      // Arrange
      await _seedPublicProfile(
        firestore,
        uid: 'uid1',
        displayName: 'Thien PDM',
        username: 'thienpdm',
      );

      // Act
      final result = await repository.searchUser('ThienPDM');

      // Assert
      expect(result, isNotNull);
      expect(result!.uid, 'uid1');
      expect(result.username, 'thienpdm');
    });

    test('returns null when username not found', () async {
      // Act
      final result = await repository.searchUser('notexist');

      // Assert
      expect(result, isNull);
    });

    test('returns null when query is empty', () async {
      // Act
      final result = await repository.searchUser('');

      // Assert
      expect(result, isNull);
    });

    test('trims whitespace before search', () async {
      // Arrange
      await _seedPublicProfile(
        firestore,
        uid: 'uid1',
        displayName: 'Thien PDM',
        username: 'thienpdm',
      );

      // Act
      final result = await repository.searchUser('  ThienPDM  ');

      // Assert
      expect(result, isNotNull);
      expect(result!.username, 'thienpdm');
    });
  });

  group('getFriendUids', () {
    test('returns friend UIDs using arrayContains query', () async {
      // Arrange
      const uid = 'user1';
      final pairId1 = pairIdOf(uid, 'friend1');
      final pairId2 = pairIdOf(uid, 'friend2');

      await firestore.collection('friendships').doc(pairId1).set({
        'uid1': uid.compareTo('friend1') < 0 ? uid : 'friend1',
        'uid2': uid.compareTo('friend1') < 0 ? 'friend1' : uid,
        'members': [uid, 'friend1'],
        'createdAt': Timestamp.now(),
      });

      await firestore.collection('friendships').doc(pairId2).set({
        'uid1': uid.compareTo('friend2') < 0 ? uid : 'friend2',
        'uid2': uid.compareTo('friend2') < 0 ? 'friend2' : uid,
        'members': [uid, 'friend2'],
        'createdAt': Timestamp.now(),
      });

      // Act
      final result = await repository.getFriendUids(uid);

      // Assert
      expect(result, hasLength(2));
      expect(result, containsAll(['friend1', 'friend2']));
    });

    test('returns empty list when no friends', () async {
      // Act
      final result = await repository.getFriendUids('user1');

      // Assert
      expect(result, isEmpty);
    });
  });

  group('unfriend', () {
    test('deletes friendship document by pairId', () async {
      // Arrange
      const pairId = 'uid1_uid2';
      await firestore.collection('friendships').doc(pairId).set({
        'uid1': 'uid1',
        'uid2': 'uid2',
        'members': ['uid1', 'uid2'],
        'createdAt': Timestamp.now(),
      });

      // Act
      await repository.unfriend(pairId);

      // Assert
      final doc = await firestore.collection('friendships').doc(pairId).get();
      expect(doc.exists, isFalse);
    });
  });

  group('pairIdOf', () {
    test('returns same ID regardless of order', () {
      // Act
      final id1 = pairIdOf('alice', 'bob');
      final id2 = pairIdOf('bob', 'alice');

      // Assert
      expect(id1, id2);
      expect(id1, 'alice_bob'); // alice < bob lexicographically
    });

    test('handles identical UIDs', () {
      // Act
      final id = pairIdOf('alice', 'alice');

      // Assert
      expect(id, 'alice_alice');
    });
  });

  group('watchFriends', () {
    test('streams friend profiles', () async {
      // Arrange
      const uid = 'user1';
      final pairId = pairIdOf(uid, 'friend1');

      await firestore.collection('friendships').doc(pairId).set({
        'uid1': uid.compareTo('friend1') < 0 ? uid : 'friend1',
        'uid2': uid.compareTo('friend1') < 0 ? 'friend1' : uid,
        'members': [uid, 'friend1'],
        'createdAt': Timestamp.now(),
      });

      await _seedPublicProfile(
        firestore,
        uid: 'friend1',
        displayName: 'Friend One',
        username: 'friend1',
      );

      // Act
      final stream = repository.watchFriends(uid);

      // Assert
      await expectLater(
        stream,
        emits(
          predicate<List<PublicProfile>>((list) {
            return list.length == 1 && list.first.uid == 'friend1';
          }),
        ),
      );
    });

    test('returns empty list when no friends', () async {
      // Act
      final stream = repository.watchFriends('user1');

      // Assert
      await expectLater(stream, emits(isEmpty));
    });
  });
}

Future<void> _seedPublicProfile(
  FakeFirebaseFirestore firestore, {
  required String uid,
  required String displayName,
  required String username,
}) {
  return firestore.doc('users/$uid/public/profile').set({
    'uid': uid,
    'displayName': displayName,
    'username': username,
    'avatarUrl': null,
    'bio': null,
    'isSearchable': true,
    'updatedAt': Timestamp.now(),
  });
}
