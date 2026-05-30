import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/chat/application/chat_providers.dart';
import 'package:meep/features/chat/data/conversation_repository.dart';

part 'chat_controller.g.dart';

@Riverpod(keepAlive: true)
ConversationRepository conversationRepository(Ref ref) =>
    throw UnimplementedError(
      'conversationRepositoryProvider must be overridden — '
      'wire FirestoreConversationRepository in main.dart (TODO: C/T1/TBD)',
    );

/// Drives message sending. UI watches this for in-flight/error feedback;
/// the message list itself comes from `messagesProvider` (a StreamProvider),
/// so this controller only owns the transient send status.
@riverpod
class ChatController extends _$ChatController {
  @override
  ChatSendStatus build() => const ChatSendStatus();

  Future<void> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    state = const ChatSendStatus(isSending: true);
    try {
      await ref.read(conversationRepositoryProvider).sendMessage(
            conversationId: conversationId,
            senderId: ref.read(currentChatUidProvider),
            text: text,
          );
      state = const ChatSendStatus();
    } catch (e) {
      state = ChatSendStatus(errorMessage: AppError.fromUnknown(e).message);
    }
  }

  /// Reply to a feed post — get/create the 1-1 conversation then send.
  /// Returns the conversation id so the caller can navigate to the thread.
  Future<String?> sendMessageFromFeed({
    required String postId,
    required String authorId,
    required String text,
  }) async {
    state = const ChatSendStatus(isSending: true);
    try {
      final repo = ref.read(conversationRepositoryProvider);
      final conversation = await repo.getOrCreateConversation(
        uid: ref.read(currentChatUidProvider),
        otherUid: authorId,
      );
      await repo.sendMessage(
        conversationId: conversation.conversationId,
        senderId: ref.read(currentChatUidProvider),
        text: text,
      );
      state = const ChatSendStatus();
      return conversation.conversationId;
    } catch (e) {
      state = ChatSendStatus(errorMessage: AppError.fromUnknown(e).message);
      return null;
    }
  }

  void clearError() => state = const ChatSendStatus();
}

/// Transient send status for the chat input bar.
class ChatSendStatus {
  const ChatSendStatus({this.isSending = false, this.errorMessage});

  final bool isSending;
  final String? errorMessage;
}
