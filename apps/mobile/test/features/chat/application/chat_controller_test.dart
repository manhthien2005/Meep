import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meep/features/chat/application/chat_controller.dart';
import 'package:meep/features/chat/data/chat_seed_data.dart';
import 'package:meep/features/chat/data/fake_conversation_repository.dart';

void main() {
  late ProviderContainer container;
  late FakeConversationRepository repo;

  setUp(() {
    repo = FakeConversationRepository();
    container = ProviderContainer(
      overrides: [
        conversationRepositoryProvider.overrideWithValue(repo),
      ],
    );
  });
  tearDown(() {
    container.dispose();
    repo.dispose();
  });

  ChatController controller() =>
      container.read(chatControllerProvider.notifier);

  group('sendMessage', () {
    test('happy path resets status (no error, not sending)', () async {
      await controller().sendMessage(
        conversationId: ChatSeed.convTalaki,
        text: 'Xin chào',
      );

      final status = container.read(chatControllerProvider);
      expect(status.isSending, isFalse);
      expect(status.errorMessage, isNull);
    });

    test('empty text surfaces ValidationError message in state', () async {
      await controller().sendMessage(
        conversationId: ChatSeed.convTalaki,
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
      final id = await controller().sendMessageFromFeed(
        postId: 'post-y',
        authorId: 'uid-talaki',
        text: 'reply',
      );
      expect(id, ChatSeed.convTalaki);
    });

    test('returns null and sets error on validation failure', () async {
      final id = await controller().sendMessageFromFeed(
        postId: 'post-z',
        authorId: 'uid-talaki',
        text: '',
      );
      expect(id, isNull);
      expect(container.read(chatControllerProvider).errorMessage, isNotNull);
    });
  });
}
