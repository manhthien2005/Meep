import 'package:flutter_test/flutter_test.dart';
import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/chat/data/chat_seed_data.dart';
import 'package:meep/features/chat/data/fake_conversation_repository.dart';

void main() {
  late FakeConversationRepository repo;

  setUp(() => repo = FakeConversationRepository());
  tearDown(() => repo.dispose());

  group('watchConversations', () {
    test('emits seeded conversations sorted by lastMessageAt DESC', () async {
      final list = await repo.watchConversations(ChatSeed.currentUid).first;

      expect(list.length, 3);
      // convTalaki (2 min ago) is most recent → first.
      expect(list.first.conversationId, ChatSeed.convTalaki);
      for (var i = 0; i < list.length - 1; i++) {
        expect(
          list[i].lastMessageAt.isAfter(list[i + 1].lastMessageAt) ||
              list[i].lastMessageAt == list[i + 1].lastMessageAt,
          isTrue,
        );
      }
    });

    test('only returns conversations the uid participates in', () async {
      final list = await repo.watchConversations('stranger-uid').first;
      expect(list, isEmpty);
    });
  });

  group('watchMessages', () {
    test('returns chronological ASC (oldest first)', () async {
      final msgs = await repo.watchMessages(ChatSeed.convTalaki).first;

      expect(msgs.length, 3);
      for (var i = 0; i < msgs.length - 1; i++) {
        expect(msgs[i].createdAt.isBefore(msgs[i + 1].createdAt), isTrue);
      }
    });

    test('empty conversation yields empty list (empty-thread state)', () async {
      final msgs = await repo.watchMessages(ChatSeed.convMinh).first;
      expect(msgs, isEmpty);
    });

    test('respects limit — returns newest N', () async {
      final msgs =
          await repo.watchMessages(ChatSeed.convTalaki, limit: 2).first;

      expect(msgs.length, 2);
      // Newest 2 of 3 → drops the oldest ('m1').
      expect(msgs.map((m) => m.messageId), ['m2', 'm3']);
    });
  });

  group('sendMessage', () {
    test('appends message and re-emits on the stream', () async {
      final emissions = <int>[];
      final sub = repo
          .watchMessages(ChatSeed.convTalaki)
          .listen((m) => emissions.add(m.length));

      // Let the subscription attach + receive the initial snapshot before
      // sending (mirrors StreamProvider: UI is subscribed before send is tapped).
      await Future<void>.delayed(Duration.zero);
      expect(emissions, [3]);

      await repo.sendMessage(
        conversationId: ChatSeed.convTalaki,
        senderId: ChatSeed.currentUid,
        text: 'Tin mới',
      );
      await Future<void>.delayed(Duration.zero);

      expect(emissions, [3, 4]);
      await sub.cancel();
    });

    test('updates conversation lastMessage + reorders inbox', () async {
      await repo.sendMessage(
        conversationId: ChatSeed.convGroup,
        senderId: ChatSeed.currentUid,
        text: 'Bump group lên đầu',
      );
      final list = await repo.watchConversations(ChatSeed.currentUid).first;

      expect(list.first.conversationId, ChatSeed.convGroup);
      expect(list.first.lastMessage, 'Bump group lên đầu');
      expect(list.first.lastSenderId, ChatSeed.currentUid);
    });

    test('trims whitespace before storing', () async {
      await repo.sendMessage(
        conversationId: ChatSeed.convMinh,
        senderId: ChatSeed.currentUid,
        text: '  hi  ',
      );
      final msgs = await repo.watchMessages(ChatSeed.convMinh).first;
      expect(msgs.single.text, 'hi');
    });

    test('throws ValidationError on empty/whitespace text', () async {
      expect(
        () => repo.sendMessage(
          conversationId: ChatSeed.convTalaki,
          senderId: ChatSeed.currentUid,
          text: '   ',
        ),
        throwsA(isA<ValidationError>()),
      );
    });

    test('throws ValidationError when text exceeds 500 chars', () async {
      expect(
        () => repo.sendMessage(
          conversationId: ChatSeed.convTalaki,
          senderId: ChatSeed.currentUid,
          text: 'a' * 501,
        ),
        throwsA(isA<ValidationError>()),
      );
    });

    test('throws NotFoundError for unknown conversation', () async {
      expect(
        () => repo.sendMessage(
          conversationId: 'nope',
          senderId: ChatSeed.currentUid,
          text: 'hi',
        ),
        throwsA(isA<NotFoundError>()),
      );
    });
  });

  group('getOrCreateConversation', () {
    test('returns existing direct conversation (idempotent)', () async {
      final c = await repo.getOrCreateConversation(
        uid: ChatSeed.currentUid,
        otherUid: 'uid-talaki',
      );
      expect(c.conversationId, ChatSeed.convTalaki);
    });

    test('creates a new empty conversation when none exists', () async {
      final c = await repo.getOrCreateConversation(
        uid: ChatSeed.currentUid,
        otherUid: 'uid-new-friend',
      );
      expect(c.type.name, 'direct');
      expect(
        c.participantIds,
        containsAll([ChatSeed.currentUid, 'uid-new-friend']),
      );

      final list = await repo.watchConversations(ChatSeed.currentUid).first;
      expect(list.any((x) => x.conversationId == c.conversationId), isTrue);
    });
  });
}
