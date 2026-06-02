import 'dart:async';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/core/utils/pair_id.dart';
import 'package:meep/features/chat/data/chat_seed_data.dart';
import 'package:meep/features/chat/data/conversation.dart';
import 'package:meep/features/chat/data/conversation_repository.dart';
import 'package:meep/features/chat/data/message.dart';

/// In-memory [ConversationRepository] for the FE-first round (#142).
///
/// Holds seed conversations + messages in memory and re-emits the full list on
/// every mutation through broadcast controllers. No Firestore. Swap for
/// `FirebaseConversationRepository` via provider override once the backend is
/// wired (see plan §wire-point).
class FakeConversationRepository implements ConversationRepository {
  FakeConversationRepository() {
    _conversations = ChatSeed.seedConversations();
    _messages = ChatSeed.seedMessages();
  }

  /// Max message length — mirrors `Message.text` "Max 500 chars." contract.
  static const _maxTextLength = 500;

  late List<Conversation> _conversations;
  late Map<String, List<Message>> _messages;

  final _conversationsCtrl = StreamController<List<Conversation>>.broadcast();

  /// One message controller per conversation, created on first watch.
  final _messageCtrls = <String, StreamController<List<Message>>>{};

  // --- Reads -------------------------------------------------------------

  @override
  Stream<List<Conversation>> watchConversations(String uid) async* {
    // Emit current snapshot on listen (broadcast controllers don't replay),
    // then forward live updates.
    yield _sortedFor(uid, _conversations);
    yield* _conversationsCtrl.stream.map((list) => _sortedFor(uid, list));
  }

  @override
  Stream<List<Message>> watchMessages(
    String conversationId, {
    int limit = 50,
  }) async* {
    // Long-lived controller, reused across re-subscriptions and closed in
    // [dispose]; not closed per-listen by design.
    // ignore: close_sinks
    final ctrl = _messageCtrls.putIfAbsent(
      conversationId,
      () => StreamController<List<Message>>.broadcast(),
    );
    yield _windowed(_messagesOf(conversationId), limit);
    yield* ctrl.stream.map((list) => _windowed(list, limit));
  }

  // --- Writes ------------------------------------------------------------

  @override
  Future<Conversation> getOrCreateConversation({
    required String uid,
    required String otherUid,
  }) async {
    final existing = _conversations.where(
      (c) =>
          c.type == ConversationType.direct &&
          c.participantIds.contains(uid) &&
          c.participantIds.contains(otherUid),
    );
    if (existing.isNotEmpty) return existing.first;

    final now = DateTime.now();
    final created = Conversation(
      conversationId: pairIdOf(uid, otherUid),
      type: ConversationType.direct,
      participantIds: [uid, otherUid],
      lastMessageAt: now,
      createdAt: now,
    );
    _conversations = [..._conversations, created];
    _conversationsCtrl.add(_conversations);
    return created;
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const ValidationError(message: 'Tin nhắn không được để trống');
    }
    if (trimmed.length > _maxTextLength) {
      throw const ValidationError(
        message: 'Tin nhắn tối đa $_maxTextLength ký tự',
      );
    }
    final idx = _conversations.indexWhere(
      (c) => c.conversationId == conversationId,
    );
    if (idx == -1) throw NotFoundError('Conversation');

    final now = DateTime.now();
    final msg = Message(
      messageId: 'm-${now.microsecondsSinceEpoch}',
      senderId: senderId,
      text: trimmed,
      createdAt: now,
    );

    _messages = {
      ..._messages,
      conversationId: [..._messagesOf(conversationId), msg],
    };
    _conversations = [..._conversations]..[idx] = _conversations[idx].copyWith(
        lastMessage: trimmed,
        lastMessageAt: now,
        lastSenderId: senderId,
      );

    _messageCtrls[conversationId]?.add(_messagesOf(conversationId));
    _conversationsCtrl.add(_conversations);
  }

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String uid,
  }) async {
    if (uid.isEmpty) return;
    final idx = _conversations.indexWhere(
      (c) => c.conversationId == conversationId,
    );
    if (idx == -1) return;
    final conv = _conversations[idx];
    final newMap = Map<String, DateTime>.from(conv.lastReadAt)
      ..[uid] = DateTime.now();
    _conversations = [..._conversations]..[idx] =
        conv.copyWith(lastReadAt: newMap);
    _conversationsCtrl.add(_conversations);
  }

  // --- Helpers -----------------------------------------------------------

  List<Message> _messagesOf(String id) => _messages[id] ?? const [];

  List<Conversation> _sortedFor(String uid, List<Conversation> list) {
    final mine = list.where((c) => c.participantIds.contains(uid)).toList()
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return mine;
  }

  /// Newest [limit] messages, returned chronological ASC (oldest first).
  List<Message> _windowed(List<Message> all, int limit) {
    if (all.length <= limit) return List.unmodifiable(all);
    return List.unmodifiable(all.sublist(all.length - limit));
  }

  /// Release controllers — call from provider `onDispose`.
  void dispose() {
    _conversationsCtrl.close();
    for (final c in _messageCtrls.values) {
      c.close();
    }
  }
}
