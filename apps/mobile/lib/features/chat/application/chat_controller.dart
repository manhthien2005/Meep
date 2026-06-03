import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
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
    final myUid = ref.read(currentChatUidProvider);
    if (myUid.isEmpty) {
      state = const ChatSendStatus(
        errorMessage: 'Đang khởi tạo phiên đăng nhập, thử lại sau giây lát',
      );
      return;
    }
    state = const ChatSendStatus(isSending: true);
    try {
      await ref.read(conversationRepositoryProvider).sendMessage(
            conversationId: conversationId,
            senderId: myUid,
            text: text,
            senderDisplayName: _resolveDisplayName(),
          );
      state = const ChatSendStatus();
    } catch (e, s) {
      developer.log(
        'sendMessage failed',
        name: 'chat',
        error: e,
        stackTrace: s,
      );
      state = ChatSendStatus(errorMessage: AppError.fromUnknown(e).message);
    }
  }

  /// Reply to a feed post — get/create the conversation rồi send.
  /// Returns the conversation id (1-1 pairId hoặc spaceId).
  ///
  /// **Routing logic:**
  /// - Post có `spaceId != null` (post được share trong Space) → forward sang
  ///   group conversation của Space đó (`conversationId == spaceId`).
  /// - Post không có spaceId (all-friends post) → forward 1-1 conversation với
  ///   author (pairId = sorted uid pair).
  ///
  /// Space conversation đã được tạo sẵn bởi CF `createSpace` — em chỉ cần gửi
  /// message vào, KHÔNG `getOrCreateConversation`.
  Future<String?> sendMessageFromFeed({
    required String postId,
    required String authorId,
    required String text,
    String? spaceId,
  }) async {
    final myUid = ref.read(currentChatUidProvider);
    if (myUid.isEmpty) {
      state = const ChatSendStatus(
        errorMessage: 'Đang khởi tạo phiên đăng nhập, thử lại sau giây lát',
      );
      return null;
    }
    final isSpacePost = spaceId != null && spaceId.isNotEmpty;
    if (!isSpacePost && (authorId.isEmpty || myUid == authorId)) {
      state = const ChatSendStatus(errorMessage: 'Không thể gửi tin nhắn');
      return null;
    }
    state = const ChatSendStatus(isSending: true);
    try {
      final repo = ref.read(conversationRepositoryProvider);
      final String conversationId;
      if (isSpacePost) {
        // Space conversation = spaceId (đã được CF createSpace tạo sẵn).
        conversationId = spaceId;
      } else {
        final conversation = await repo.getOrCreateConversation(
          uid: myUid,
          otherUid: authorId,
        );
        conversationId = conversation.conversationId;
      }
      await repo.sendMessage(
        conversationId: conversationId,
        senderId: myUid,
        text: text,
        senderDisplayName: _resolveDisplayName(),
        // FB story reply pattern: postId gắn vào message → ChatThreadView
        // render mini quoted card phía trên bubble (per-message, không phải
        // 1 header chung cho conversation).
        quotedPostId: postId,
      );
      state = const ChatSendStatus();
      return conversationId;
    } catch (e, s) {
      developer.log(
        'sendMessageFromFeed failed',
        name: 'chat',
        error: e,
        stackTrace: s,
      );
      state = ChatSendStatus(errorMessage: AppError.fromUnknown(e).message);
      return null;
    }
  }

  /// Pluck displayName từ currentUserProfileProvider — null nếu profile chưa
  /// load hoặc displayName empty. Caller pass xuống repo để denormalize cho
  /// group chat sender label.
  String? _resolveDisplayName() {
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    final name = profile?.displayName.trim();
    return (name == null || name.isEmpty) ? null : name;
  }

  void clearError() => state = const ChatSendStatus();
}

/// Transient send status for the chat input bar.
class ChatSendStatus {
  const ChatSendStatus({this.isSending = false, this.errorMessage});

  final bool isSending;
  final String? errorMessage;
}
