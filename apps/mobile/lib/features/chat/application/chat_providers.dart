import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/chat/data/chat_seed_data.dart';
import 'package:meep/features/chat/data/conversation.dart';
import 'package:meep/features/chat/application/chat_controller.dart';
import 'package:meep/features/chat/data/message.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/feed/data/post.dart';
import 'package:meep/features/space/data/space.dart';
import 'package:meep/features/space/data/space_member.dart';

part 'chat_providers.g.dart';

/// Current logged-in uid for the Chat module.
///
/// FE-first round returns a mock uid (matches [ChatSeed.currentUid]).
/// TODO(C/wire): read from `currentUidProvider` (auth) once integrated.
@riverpod
String currentChatUid(Ref ref) => ChatSeed.currentUid;

/// Live conversations for the inbox, sorted by lastMessageAt DESC.
@riverpod
Stream<List<Conversation>> conversations(Ref ref) {
  final uid = ref.watch(currentChatUidProvider);
  return ref.watch(conversationRepositoryProvider).watchConversations(uid);
}

/// Per-conversation message-window limit. Increase to load older messages
/// (re-subscribes `messages` with a larger limit). See [ConversationRepository].
@riverpod
class MessageLimit extends _$MessageLimit {
  @override
  int build(String conversationId) => 50;

  void loadMore() => state += 50;
}

/// Live messages for [conversationId], chronological ASC, windowed by limit.
@riverpod
Stream<List<Message>> messages(Ref ref, String conversationId) {
  final limit = ref.watch(messageLimitProvider(conversationId));
  return ref
      .watch(conversationRepositoryProvider)
      .watchMessages(conversationId, limit: limit);
}

/// Unread counts per conversation — NOT in [Conversation] model yet
/// (contract-pending, see plan). FE renders the inbox badge from this.
/// TODO(C/wire): derive from `lastReadAt` once the field lands on the model.
@riverpod
Map<String, int> unreadCounts(Ref ref) => ChatSeed.seedUnreadCounts();

/// User profiles keyed by uid, for resolving 1-1 conversation display info.
/// TODO(C/wire): replace seed lookup with `userRepository` reads.
@riverpod
Map<String, UserProfile> chatUserProfiles(Ref ref) => ChatSeed.usersByUid;

/// The single demo space backing group chat.
/// TODO(C/wire): replace with `spaceRepository.watchSpace(spaceId)`.
@riverpod
Space chatSpace(Ref ref, String spaceId) => ChatSeed.seedSpace();

/// Members of the demo space.
/// TODO(C/wire): replace with `spaceRepository.watchMembers(spaceId)`.
@riverpod
List<SpaceMember> chatSpaceMembers(Ref ref, String spaceId) =>
    ChatSeed.seedMembers();

/// The post that a 1-1 conversation was started from (quoted photo header).
/// Returns null when the conversation has no originating post.
/// TODO(C/wire): replace with `postRepository.getPost(quotedPostId)`.
@riverpod
Post? chatQuotedPost(Ref ref, String? quotedPostId) {
  if (quotedPostId == null) return null;
  final post = ChatSeed.quotedPost();
  return post.postId == quotedPostId ? post : null;
}
