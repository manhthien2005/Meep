import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/core/utils/pair_id.dart';
import 'package:meep/features/chat/application/chat_controller.dart';
import 'package:meep/features/chat/application/chat_providers.dart';
import 'package:meep/features/chat/data/conversation.dart';
import 'package:meep/features/chat/data/firebase_conversation_repository.dart';

void main() {
  late ProviderContainer container;
  late FakeFirebaseFirestore firestore;
  late FirebaseConversationRepository repo;

  const testUid = 'test-user';
  const talakiUid = 'uid-talaki';
  late String talakiPairId;

  Future<void> seedConversation({
    required String conversationId,
    required List<String> participantIds,
    String lastMessage = '',
    ConversationStatus status = ConversationStatus.active,
  }) async {
    final conv = Conversation(
      conversationId: conversationId,
      type: ConversationType.direct,
      participantIds: participantIds,
      status: status,
      lastMessage: lastMessage,
      lastMessageAt: DateTime(2026, 6, 1),
      lastSenderId: '',
      createdAt: DateTime(2026, 6, 1),
    );
    await firestore.collection('conversations').doc(conversationId).set(
          conv.toJson(),
        );
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirebaseConversationRepository(firestore);
    talakiPairId = pairIdOf(testUid, talakiUid);
    container = ProviderContainer(
      overrides: [
        conversationRepositoryProvider.overrideWithValue(repo),
        currentChatUidProvider.overrideWith((ref) => testUid),
      ],
    );
  });
  tearDown(() => container.dispose());

  ChatController controller() =>
      container.read(chatControllerProvider.notifier);

  group('sendMessage', () {
    test('happy path resets status (no error, not sending)', () async {
      // Seed the conversation first
      await seedConversation(
        conversationId: talakiPairId,
        participantIds: [testUid, talakiUid],
      );

      await controller().sendMessage(
        conversationId: talakiPairId,
        text: 'Xin chào',
      );

      final status = container.read(chatControllerProvider);
      expect(status.isSending, isFalse);
      expect(status.errorMessage, isNull);
    });

    test('empty text surfaces ValidationError message in state', () async {
      await seedConversation(
        conversationId: talakiPairId,
        participantIds: [testUid, talakiUid],
      );

      await controller().sendMessage(
        conversationId: talakiPairId,
        text: '   ',
      );

      final status = container.read(chatControllerProvider);
      expect(status.isSending, isFalse);
      expect(status.errorMessage, isNotNull);
    });

    test('unknown conversation surfaces error in state', () async {
      await controller().sendMessage(
        conversationId: 'does-not-exist',
        text: 'hi',
      );
      expect(container.read(chatControllerProvider).errorMessage, isNotNull);
    });

    test('clearError resets the error', () async {
      await controller().sendMessage(
        conversationId: 'does-not-exist',
        text: 'hi',
      );
      controller().clearError();
      expect(container.read(chatControllerProvider).errorMessage, isNull);
    });
  });

  group('sendMessageFromFeed', () {
    test('creates conversation + sends, returns conversation id', () async {
      final id = await controller().sendMessageFromFeed(
        postId: 'post-x',
        authorId: 'uid-new-author',
        text: 'Trả lời từ feed',
      );

      expect(id, isNotNull);
      final msgs = await repo.watchMessages(id!).first;
      expect(msgs.single.text, 'Trả lời từ feed');
    });

    test('reuses existing conversation for known author', () async {
      // Pre-seed the conversation
      await seedConversation(
        conversationId: talakiPairId,
        participantIds: [testUid, talakiUid],
      );

      final id = await controller().sendMessageFromFeed(
        postId: 'post-y',
        authorId: talakiUid,
        text: 'reply',
      );

      expect(id, talakiPairId);
    });

    test('returns null and sets error on validation failure', () async {
      final id = await controller().sendMessageFromFeed(
        postId: 'post-z',
        authorId: talakiUid,
        text: '',
      );
      expect(id, isNull);
      expect(container.read(chatControllerProvider).errorMessage, isNotNull);
    });
  });
}
