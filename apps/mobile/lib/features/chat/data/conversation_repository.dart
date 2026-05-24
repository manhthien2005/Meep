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

  /// Stream of messages for [conversationId], chronological ASC.
  Stream<List<Message>> watchMessages(String conversationId);
}
