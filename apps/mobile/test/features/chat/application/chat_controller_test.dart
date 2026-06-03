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

    test('returns null + sets error when current uid is empty', () async {
      // Re-create container với currentChatUidProvider override '' để giả lập
      // auth state loading. Bug #10 fix expect controller fail-fast trước khi
      // chạm Firestore — tránh ghi pairId xấu vào rules.
      final emptyUidContainer = ProviderContainer(
        overrides: [
          conversationRepositoryProvider.overrideWithValue(repo),
          currentChatUidProvider.overrideWith((ref) => ''),
        ],
      );
      addTearDown(emptyUidContainer.dispose);
      final emptyController =
          emptyUidContainer.read(chatControllerProvider.notifier);

      final id = await emptyController.sendMessageFromFeed(
        postId: 'post-q',
        authorId: talakiUid,
        text: 'hi',
      );

      expect(id, isNull);
      final status = emptyUidContainer.read(chatControllerProvider);
      expect(status.errorMessage, contains('khởi tạo phiên'));
      // Repo KHÔNG nên bị chạm — Firestore vẫn empty.
      final convs = await firestore.collection('conversations').get();
      expect(convs.docs, isEmpty);
    });

    test('returns null + sets error when author is self (no echo chamber)',
        () async {
      final id = await controller().sendMessageFromFeed(
        postId: 'post-self',
        authorId: testUid, // self
        text: 'hi',
      );
      expect(id, isNull);
      expect(
        container.read(chatControllerProvider).errorMessage,
        'Không thể gửi tin nhắn',
      );
    });

    test(
        'forwards to space conversation when spaceId set, KHÔNG getOrCreate 1-1',
        () async {
      // Seed space conversation (CF createSpace sẽ tạo doc với conversationId == spaceId).
      const spaceId = 'space-abc';
      await firestore.collection('conversations').doc(spaceId).set({
        'conversationId': spaceId,
        'type': 'space',
        'participantIds': [testUid, 'member-2', 'member-3'],
        'spaceId': spaceId,
        'status': 'active',
        'lastMessage': '',
        'lastMessageAt': DateTime(2026, 6, 1),
        'lastSenderId': '',
        'createdAt': DateTime(2026, 6, 1),
      });

      final id = await controller().sendMessageFromFeed(
        postId: 'post-in-space',
        authorId: 'member-2', // author của post
        text: 'reply trong space',
        spaceId: spaceId,
      );

      // Conversation id phải = spaceId, KHÔNG phải pairId 1-1.
      expect(id, spaceId);
      // Verify message ghi vào space conversation, KHÔNG tạo conversation
      // 1-1 với author.
      final msgs = await repo.watchMessages(spaceId).first;
      expect(msgs.single.text, 'reply trong space');
      final convs = await firestore.collection('conversations').get();
      // 1 doc (space) — KHÔNG có 1-1 pairId mới được tạo.
      expect(convs.docs.length, 1);
    });

    test('forwards to space allowed even when authorId == self (own post)',
        () async {
      // Anh share own post vào Space → có thể self-reply trong group chat.
      const spaceId = 'space-own-post';
      await firestore.collection('conversations').doc(spaceId).set({
        'conversationId': spaceId,
        'type': 'space',
        'participantIds': [testUid, 'm2'],
        'spaceId': spaceId,
        'status': 'active',
        'lastMessage': '',
        'lastMessageAt': DateTime(2026, 6, 1),
        'lastSenderId': '',
        'createdAt': DateTime(2026, 6, 1),
      });

      final id = await controller().sendMessageFromFeed(
        postId: 'own-post',
        authorId: testUid, // chính mình
        text: 'own post reply',
        spaceId: spaceId,
      );

      expect(id, spaceId);
    });
  });

  group('sendMessage uid guards', () {
    test('returns early + sets error when uid empty', () async {
      final emptyUidContainer = ProviderContainer(
        overrides: [
          conversationRepositoryProvider.overrideWithValue(repo),
          currentChatUidProvider.overrideWith((ref) => ''),
        ],
      );
      addTearDown(emptyUidContainer.dispose);
      final emptyController =
          emptyUidContainer.read(chatControllerProvider.notifier);

      await emptyController.sendMessage(
        conversationId: talakiPairId,
        text: 'hi',
      );

      final status = emptyUidContainer.read(chatControllerProvider);
      expect(status.errorMessage, contains('khởi tạo phiên'));
    });
  });
}
