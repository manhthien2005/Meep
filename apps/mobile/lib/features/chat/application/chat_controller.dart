import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/chat/data/conversation_repository.dart';

part 'chat_controller.g.dart';

@Riverpod(keepAlive: true)
ConversationRepository conversationRepository(Ref ref) =>
    throw UnimplementedError(
      'conversationRepositoryProvider must be overridden — '
      'wire FirestoreConversationRepository in main.dart (TODO: C/T1/TBD)',
    );

@riverpod
class ChatController extends _$ChatController {
  @override
  void build() {}

  Future<void> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    // TODO(C/T2/TBD): implement sendMessage
    throw UnimplementedError('sendMessage — TODO: C/T2/TBD');
  }

  Future<void> sendMessageFromFeed({
    required String postId,
    required String authorId,
    required String text,
  }) async {
    // TODO(C/T3/TBD): get/create conversation then send message
    throw UnimplementedError('sendMessageFromFeed — TODO: C/T3/TBD');
  }
}
