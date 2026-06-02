import 'package:meep/features/chat/data/conversation.dart';
import 'package:meep/features/chat/data/message.dart';

/// Chat does NOT define its own BlockRepository.
/// Import from settings/data/block_repository.dart instead.
abstract class ConversationRepository {
  /// Stream of conversations for [uid], sorted by lastMessageAt DESC.
  Stream<List<Conversation>> watchConversations(String uid);

  /// Get or create a direct conversation for the pair.
  /// Returns existing if found, creates empty otherwise.
  Future<Conversation> getOrCreateConversation({
    required String uid,
    required String otherUid,
  });

  /// Send a message to [conversationId].
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  });

  /// Stream of the most recent [limit] messages for [conversationId],
  /// ordered chronological ASC (oldest first) for display.
  ///
  /// Impl: query `orderBy('createdAt', descending: true).limit(limit)` to take
  /// the newest [limit] messages, then reverse client-side to ASC.
  /// To load older messages, re-subscribe with a larger [limit] (50 → 100 → …).
  Stream<List<Message>> watchMessages(
    String conversationId, {
    int limit = 50,
  });

  /// Mark [conversationId] as read up to now for [uid].
  ///
  /// Update `lastReadAt[uid] = serverTimestamp()` trên conversation doc.
  /// Caller bắt buộc verify [uid] là participant — repo KHÔNG check (rule
  /// Firestore enforce).
  Future<void> markAsRead({
    required String conversationId,
    required String uid,
  });
}
