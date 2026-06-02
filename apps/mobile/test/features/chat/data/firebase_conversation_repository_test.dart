import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/core/utils/pair_id.dart';
import 'package:meep/features/chat/data/conversation.dart';
import 'package:meep/features/chat/data/firebase_conversation_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirebaseConversationRepository repository;

  const aliceUid = 'alice';
  const bobUid = 'bob';
  const strangerUid = 'stranger';

  String aliceBobPairId() => pairIdOf(aliceUid, bobUid);
  String aliceStrangerPairId() => pairIdOf(aliceUid, strangerUid);

  Conversation conversationDoc({
    required String conversationId,
    required List<String> participantIds,
    ConversationStatus status = ConversationStatus.active,
    DateTime? lastMessageAt,
    String lastMessage = '',
  }) {
    return Conversation(
      conversationId: conversationId,
      type: ConversationType.direct,
      participantIds: participantIds,
      status: status,
      lastMessage: lastMessage,
      lastMessageAt: lastMessageAt ?? DateTime(2026, 6, 1),
      lastSenderId: '',
      createdAt: DateTime(2026, 6, 1),
    );
  }

  Future<void> seedConversation(Conversation c) async {
    await firestore.collection('conversations').doc(c.conversationId).set(
          c.toJson(),
        );
  }

  Future<void> seedMessage({
    required String conversationId,
    required String senderId,
    required String text,
    DateTime? createdAt,
    String? messageId,
  }) async {
    final id = messageId ?? 'msg-${text.hashCode}';
    await firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(id)
        .set({
      'messageId': id,
      'senderId': senderId,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt ?? DateTime(2026, 6, 1)),
    });
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirebaseConversationRepository(firestore);
  });

  // --- watchConversations --------------------------------------------------

  group('watchConversations', () {
    test(
        'returns conversations where uid is participant, sorted by lastMessageAt DESC',
        () async {
      final pairId = aliceBobPairId();
      final early = conversationDoc(
        conversationId: pairId,
        participantIds: [aliceUid, bobUid],
        lastMessageAt: DateTime(2026, 6, 1, 10, 0),
        lastMessage: 'older',
      );
      final laterPairId = aliceStrangerPairId();
      final later = conversationDoc(
        conversationId: laterPairId,
        participantIds: [aliceUid, strangerUid],
        lastMessageAt: DateTime(2026, 6, 1, 12, 0),
        lastMessage: 'newer',
      );

      await seedConversation(early);
      await seedConversation(later);

      final results = await repository.watchConversations(aliceUid).first;

      expect(results.length, 2);
      expect(results[0].conversationId, laterPairId); // newer first
      expect(results[1].conversationId, pairId);
    });

    test('returns empty when no conversations for uid', () async {
      final results = await repository.watchConversations(aliceUid).first;
      expect(results, isEmpty);
    });

    test('filters out blocked conversations client-side', () async {
      final active = conversationDoc(
        conversationId: aliceBobPairId(),
        participantIds: [aliceUid, bobUid],
        status: ConversationStatus.active,
        lastMessageAt: DateTime(2026, 6, 1, 12, 0),
      );
      final blocked = conversationDoc(
        conversationId: aliceStrangerPairId(),
        participantIds: [aliceUid, strangerUid],
        status: ConversationStatus.blocked,
        lastMessageAt: DateTime(2026, 6, 1, 14, 0),
      );

      await seedConversation(active);
      await seedConversation(blocked);

      final results = await repository.watchConversations(aliceUid).first;

      expect(results.length, 1);
      expect(results.single.conversationId, aliceBobPairId());
    });

    test('does not return conversations uid is not a participant of', () async {
      final conv = conversationDoc(
        conversationId: pairIdOf(bobUid, strangerUid),
        participantIds: [bobUid, strangerUid],
      );
      await seedConversation(conv);

      final results = await repository.watchConversations(aliceUid).first;

      expect(results, isEmpty);
    });

    test(
        'returns empty stream immediately when uid is empty (no Firestore call)',
        () async {
      // Seed a conversation that would match an empty uid query if it fired.
      final conv = conversationDoc(
        conversationId: aliceBobPairId(),
        participantIds: [aliceUid, bobUid],
      );
      await seedConversation(conv);

      final results = await repository.watchConversations('').first;

      expect(results, isEmpty);
    });
  });

  // --- getOrCreateConversation ---------------------------------------------

  group('getOrCreateConversation', () {
    test('returns existing conversation when found', () async {
      final pairId = aliceBobPairId();
      final existing = conversationDoc(
        conversationId: pairId,
        participantIds: [aliceUid, bobUid],
      );
      await seedConversation(existing);

      final result = await repository.getOrCreateConversation(
        uid: aliceUid,
        otherUid: bobUid,
      );

      expect(result.conversationId, pairId);
      expect(result.participantIds, containsAll([aliceUid, bobUid]));
    });

    test('creates new conversation when not found (idempotent)', () async {
      final pairId = aliceBobPairId();

      final result = await repository.getOrCreateConversation(
        uid: aliceUid,
        otherUid: bobUid,
      );

      expect(result.conversationId, pairId);
      expect(result.type, ConversationType.direct);
      expect(result.participantIds, containsAll([aliceUid, bobUid]));

      // Verify doc was created in Firestore
      final doc = await firestore.collection('conversations').doc(pairId).get();
      expect(doc.exists, isTrue);
    });

    test('returns same conversation on repeated calls (idempotent)', () async {
      final first = await repository.getOrCreateConversation(
        uid: aliceUid,
        otherUid: bobUid,
      );
      final second = await repository.getOrCreateConversation(
        uid: aliceUid,
        otherUid: bobUid,
      );

      expect(second.conversationId, first.conversationId);
    });

    test('pairId is deterministic regardless of uid order', () async {
      final r1 = await repository.getOrCreateConversation(
        uid: aliceUid,
        otherUid: bobUid,
      );
      final r2 = await repository.getOrCreateConversation(
        uid: bobUid,
        otherUid: aliceUid,
      );

      expect(r2.conversationId, r1.conversationId);
    });
  });

  // --- sendMessage ---------------------------------------------------------

  group('sendMessage', () {
    test('writes message doc and updates conversation (atomic batch)',
        () async {
      final pairId = aliceBobPairId();
      await seedConversation(
        conversationDoc(
          conversationId: pairId,
          participantIds: [aliceUid, bobUid],
        ),
      );

      await repository.sendMessage(
        conversationId: pairId,
        senderId: aliceUid,
        text: 'Chào bạn!',
      );

      // Verify message was created
      final messagesSnap = await firestore
          .collection('conversations')
          .doc(pairId)
          .collection('messages')
          .get();
      expect(messagesSnap.docs.length, 1);
      final msgData = messagesSnap.docs.first.data();
      expect(msgData['text'], 'Chào bạn!');
      expect(msgData['senderId'], aliceUid);

      // Verify conversation was updated
      final convDoc =
          await firestore.collection('conversations').doc(pairId).get();
      expect(convDoc.data()!['lastMessage'], 'Chào bạn!');
      expect(convDoc.data()!['lastSenderId'], aliceUid);
    });

    test('throws ValidationError on empty text', () async {
      final pairId = aliceBobPairId();
      await seedConversation(
        conversationDoc(
          conversationId: pairId,
          participantIds: [aliceUid, bobUid],
        ),
      );

      expect(
        () => repository.sendMessage(
          conversationId: pairId,
          senderId: aliceUid,
          text: '',
        ),
        throwsA(isA<ValidationError>()),
      );
    });

    test('throws ValidationError on whitespace-only text', () async {
      final pairId = aliceBobPairId();
      await seedConversation(
        conversationDoc(
          conversationId: pairId,
          participantIds: [aliceUid, bobUid],
        ),
      );

      expect(
        () => repository.sendMessage(
          conversationId: pairId,
          senderId: aliceUid,
          text: '   ',
        ),
        throwsA(isA<ValidationError>()),
      );
    });

    test('throws ValidationError on text > 500 chars', () async {
      final pairId = aliceBobPairId();
      await seedConversation(
        conversationDoc(
          conversationId: pairId,
          participantIds: [aliceUid, bobUid],
        ),
      );

      expect(
        () => repository.sendMessage(
          conversationId: pairId,
          senderId: aliceUid,
          text: 'A' * 501,
        ),
        throwsA(isA<ValidationError>()),
      );
    });

    test('trims whitespace from text', () async {
      final pairId = aliceBobPairId();
      await seedConversation(
        conversationDoc(
          conversationId: pairId,
          participantIds: [aliceUid, bobUid],
        ),
      );

      await repository.sendMessage(
        conversationId: pairId,
        senderId: aliceUid,
        text: '  Hello  ',
      );

      final messagesSnap = await firestore
          .collection('conversations')
          .doc(pairId)
          .collection('messages')
          .get();
      expect(messagesSnap.docs.first.data()['text'], 'Hello');
    });

    test('throws when conversation does not exist', () async {
      // No seedConversation — the batch update on a missing doc must fail.
      expect(
        () => repository.sendMessage(
          conversationId: 'does-not-exist',
          senderId: aliceUid,
          text: 'hello',
        ),
        throwsA(isA<AppError>()),
      );
    });
  });

  // --- watchMessages -------------------------------------------------------

  group('watchMessages', () {
    test('returns messages chronological ASC (oldest first)', () async {
      final pairId = aliceBobPairId();
      await seedConversation(
        conversationDoc(
          conversationId: pairId,
          participantIds: [aliceUid, bobUid],
        ),
      );
      await seedMessage(
        conversationId: pairId,
        senderId: aliceUid,
        text: 'First',
        createdAt: DateTime(2026, 6, 1, 10, 0),
        messageId: 'msg-1',
      );
      await seedMessage(
        conversationId: pairId,
        senderId: bobUid,
        text: 'Second',
        createdAt: DateTime(2026, 6, 1, 11, 0),
        messageId: 'msg-2',
      );
      await seedMessage(
        conversationId: pairId,
        senderId: aliceUid,
        text: 'Third',
        createdAt: DateTime(2026, 6, 1, 12, 0),
        messageId: 'msg-3',
      );

      final messages = await repository.watchMessages(pairId).first;

      expect(messages.length, 3);
      expect(messages[0].text, 'First');
      expect(messages[1].text, 'Second');
      expect(messages[2].text, 'Third');
    });

    test('returns empty when no messages', () async {
      final pairId = aliceBobPairId();
      await seedConversation(
        conversationDoc(
          conversationId: pairId,
          participantIds: [aliceUid, bobUid],
        ),
      );

      final messages = await repository.watchMessages(pairId).first;

      expect(messages, isEmpty);
    });

    test('respects limit parameter', () async {
      final pairId = aliceBobPairId();
      await seedConversation(
        conversationDoc(
          conversationId: pairId,
          participantIds: [aliceUid, bobUid],
        ),
      );
      for (var i = 0; i < 10; i++) {
        await seedMessage(
          conversationId: pairId,
          senderId: aliceUid,
          text: 'Msg $i',
          createdAt: DateTime(2026, 6, 1, 10, i),
          messageId: 'msg-$i',
        );
      }

      final messages = await repository.watchMessages(pairId, limit: 3).first;

      // Should return newest 3, reversed to ASC
      expect(messages.length, 3);
      expect(messages[0].text, 'Msg 7');
      expect(messages[1].text, 'Msg 8');
      expect(messages[2].text, 'Msg 9');
    });
  });
}
