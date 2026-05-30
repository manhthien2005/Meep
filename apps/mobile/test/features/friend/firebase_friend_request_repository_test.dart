import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:meep/features/friend/data/firebase_friend_request_repository.dart';
import 'package:meep/features/friend/data/friend_request.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseFunctions functions;
  late FirebaseFriendRequestRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    functions = MockFirebaseFunctions();
    repository = FirebaseFriendRequestRepository(firestore, functions);
  });

  group('watchPendingRequests', () {
    test('streams pending requests for receiver', () async {
      // Arrange
      const receiverUid = 'user1';
      await firestore.collection('friend_requests').add({
        'senderId': 'sender1',
        'receiverId': receiverUid,
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      await firestore.collection('friend_requests').add({
        'senderId': 'sender2',
        'receiverId': receiverUid,
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Add accepted request (should not appear)
      await firestore.collection('friend_requests').add({
        'senderId': 'sender3',
        'receiverId': receiverUid,
        'status': 'accepted',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Act
      final stream = repository.watchPendingRequests(receiverUid);

      // Assert
      await expectLater(
        stream,
        emits(
          predicate<List<FriendRequest>>((list) {
            return list.length == 2 &&
                list.every((req) => req.status == FriendRequestStatus.pending);
          }),
        ),
      );
    });

    test('returns empty list when no pending requests', () async {
      // Act
      final stream = repository.watchPendingRequests('user1');

      // Assert
      await expectLater(stream, emits(isEmpty));
    });
  });

  group('sendFriendRequest', () {
    test('creates friend request document', () async {
      // Act
      await repository.sendFriendRequest(
        senderUid: 'user1',
        receiverUid: 'user2',
      );

      // Assert
      final snapshot = await firestore.collection('friend_requests').get();
      expect(snapshot.docs, hasLength(1));

      final data = snapshot.docs.first.data();
      expect(data['senderId'], 'user1');
      expect(data['receiverId'], 'user2');
      expect(data['status'], 'pending');
    });

    test('throws when sending request to self', () async {
      // Act & Assert
      expect(
        () => repository.sendFriendRequest(
          senderUid: 'user1',
          receiverUid: 'user1',
        ),
        throwsException,
      );
    });
  });

  group('cancelFriendRequest', () {
    test('updates request status to cancelled', () async {
      // Arrange
      final docRef = await firestore.collection('friend_requests').add({
        'senderId': 'user1',
        'receiverId': 'user2',
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Act
      await repository.cancelFriendRequest(docRef.id);

      // Assert
      final doc = await firestore.collection('friend_requests').doc(docRef.id).get();
      expect(doc.data()!['status'], 'cancelled');
    });
  });

  group('declineFriendRequest', () {
    test('updates request status to declined', () async {
      // Arrange
      final docRef = await firestore.collection('friend_requests').add({
        'senderId': 'user1',
        'receiverId': 'user2',
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Act
      await repository.declineFriendRequest(docRef.id);

      // Assert
      final doc = await firestore.collection('friend_requests').doc(docRef.id).get();
      expect(doc.data()!['status'], 'declined');
    });
  });
}
