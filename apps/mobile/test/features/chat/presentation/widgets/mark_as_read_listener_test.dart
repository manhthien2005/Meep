import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/features/chat/application/chat_controller.dart';
import 'package:meep/features/chat/application/chat_providers.dart';
import 'package:meep/features/chat/data/conversation.dart';
import 'package:meep/features/chat/data/conversation_repository.dart';
import 'package:meep/features/chat/data/message.dart';
import 'package:meep/features/chat/presentation/widgets/mark_as_read_listener.dart';

void main() {
  const myUid = 'me';
  const peerUid = 'peer';
  const convId = 'me_peer';

  testWidgets('fires markAsRead once on mount via post-frame callback',
      (tester) async {
    // ignore: close_sinks
    final repo = _SpyConversationRepository();
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          conversationRepositoryProvider.overrideWithValue(repo),
          currentChatUidProvider.overrideWith((ref) => myUid),
        ],
        child: const _Host(conversationId: convId),
      ),
    );

    // Đợi post-frame callback + debounce 500ms.
    await tester.pump(const Duration(milliseconds: 600));

    expect(repo.markAsReadCalls, 1);
    expect(repo.lastConversationId, convId);
    expect(repo.lastUid, myUid);
  });

  testWidgets('does NOT fire when current uid empty (defensive)',
      (tester) async {
    // ignore: close_sinks
    final repo = _SpyConversationRepository();
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          conversationRepositoryProvider.overrideWithValue(repo),
          currentChatUidProvider.overrideWith((ref) => ''),
        ],
        child: const _Host(conversationId: convId),
      ),
    );

    await tester.pump(const Duration(milliseconds: 600));
    expect(repo.markAsReadCalls, 0);
  });

  testWidgets('fires again when new message arrives from peer', (tester) async {
    // ignore: close_sinks
    final repo = _SpyConversationRepository();
    addTearDown(repo.dispose);
    // ignore: close_sinks — owned by repo, closed in repo.dispose() via addTearDown.
    final messagesCtrl = repo.messagesController(convId);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          conversationRepositoryProvider.overrideWithValue(repo),
          currentChatUidProvider.overrideWith((ref) => myUid),
        ],
        child: const _Host(conversationId: convId),
      ),
    );

    // Mount fire #1
    await tester.pump(const Duration(milliseconds: 600));
    expect(repo.markAsReadCalls, 1);

    // Peer gửi msg mới → stream emit → listener trigger fire #2
    messagesCtrl.add([
      Message(
        messageId: 'm1',
        senderId: peerUid,
        text: 'hi',
        createdAt: DateTime(2026, 6, 1, 12),
      ),
    ]);
    await tester.pump(const Duration(milliseconds: 600));

    expect(repo.markAsReadCalls, 2);
  });
}

class _Host extends StatelessWidget {
  const _Host({required this.conversationId});
  final String conversationId;
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MarkAsReadListener(conversationId: conversationId),
    );
  }
}

/// Minimal spy repository — chỉ implement những method MarkAsReadListener
/// thực sự gọi. Các method khác throw UnsupportedError để fail-fast nếu
/// listener gọi nhầm.
class _SpyConversationRepository implements ConversationRepository {
  int markAsReadCalls = 0;
  String? lastConversationId;
  String? lastUid;

  final _msgControllers = <String, StreamController<List<Message>>>{};

  StreamController<List<Message>> messagesController(String id) =>
      _msgControllers.putIfAbsent(
        id,
        () => StreamController<List<Message>>.broadcast(),
      );

  void dispose() {
    for (final c in _msgControllers.values) {
      c.close();
    }
  }

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String uid,
  }) async {
    markAsReadCalls++;
    lastConversationId = conversationId;
    lastUid = uid;
  }

  @override
  Stream<List<Message>> watchMessages(
    String conversationId, {
    int limit = 50,
  }) {
    // ignore: close_sinks — owned by this repo, closed in dispose().
    final ctrl = messagesController(conversationId);
    // Yield initial empty + forward updates.
    return Stream.multi((listener) {
      listener.add(const []);
      final sub = ctrl.stream.listen(listener.add);
      listener.onCancel = sub.cancel;
    });
  }

  // Unused — fail loudly if called.
  @override
  Stream<List<Conversation>> watchConversations(String uid) =>
      throw UnsupportedError('watchConversations');

  @override
  Future<Conversation> getOrCreateConversation({
    required String uid,
    required String otherUid,
  }) =>
      throw UnsupportedError('getOrCreateConversation');

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
    String? senderDisplayName,
  }) =>
      throw UnsupportedError('sendMessage');
}
