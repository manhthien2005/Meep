import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/chat/application/chat_controller.dart';
import 'package:meep/features/chat/data/chat_seed_data.dart';
import 'package:meep/features/chat/data/conversation.dart';
import 'package:meep/features/chat/data/message.dart';
import 'package:meep/features/feed/data/post.dart';
import 'package:meep/features/space/application/space_controller.dart';
import 'package:meep/features/space/data/space.dart';
import 'package:meep/features/space/data/space_member.dart';

part 'chat_providers.g.dart';

/// Current logged-in uid for the Chat module.
@riverpod
String currentChatUid(Ref ref) {
  return ref.watch(currentUidProvider).valueOrNull ?? '';
}

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

/// Per-conversation unread indicator (1 = có unread, 0 = không).
///
/// Đếm "1" thay vì exact message count — không cần subcollection query phụ.
/// Badge taskbar = số conversations đang có unread (fold sum). UX hiện tại
/// chỉ cần "có chấm đỏ hay không", chưa cần con số chính xác.
///
/// Rule unread:
/// 1. `lastSenderId == uid` → mình là người gửi cuối → KHÔNG unread.
/// 2. `lastReadAt[uid] == null` → chưa từng đọc → unread nếu có msg
///    (lastMessageAt > createdAt).
/// 3. Có `lastReadAt[uid]` → unread khi `lastMessageAt > lastReadAt[uid]`.
@riverpod
Map<String, int> unreadCounts(Ref ref) {
  final uid = ref.watch(currentChatUidProvider);
  if (uid.isEmpty) return const <String, int>{};
  final convs = ref.watch(conversationsProvider).valueOrNull ?? const [];
  final result = <String, int>{};
  for (final c in convs) {
    if (c.lastSenderId == uid) continue; // mình gửi → không unread
    final lastRead = c.lastReadAt[uid];
    final hasUnread = lastRead == null
        ? c.lastMessageAt.isAfter(c.createdAt)
        : c.lastMessageAt.isAfter(lastRead);
    if (hasUnread) result[c.conversationId] = 1;
  }
  return result;
}

/// Resolve a single [UserProfile] by [uid] for display in chat tiles,
/// headers, and member lists.
///
/// Uses [UserRepository.getProfile] (auth module). Riverpod auto-deduplicates
/// when multiple widgets watch the same uid — only one Firestore read per uid.
@riverpod
Future<UserProfile?> chatUserProfile(Ref ref, String uid) async {
  if (uid.isEmpty) return null;
  return ref.watch(userRepositoryProvider).getProfile(uid);
}

/// Live Space document for a group conversation header / tile.
///
/// Delegates to [SpaceRepository.watchSpace] (space module). Empty spaceId →
/// emits null without hitting Firestore (defensive cho conversation 1-1).
@riverpod
Stream<Space?> chatSpace(Ref ref, String spaceId) {
  if (spaceId.isEmpty) return Stream.value(null);
  return ref.watch(spaceRepositoryProvider).watchSpace(spaceId);
}

/// Live member list for [SpaceMembersSheet].
///
/// Delegates to [SpaceRepository.watchMembers] (space module).
@riverpod
Stream<List<SpaceMember>> chatSpaceMembers(Ref ref, String spaceId) {
  if (spaceId.isEmpty) return Stream.value(const []);
  return ref.watch(spaceRepositoryProvider).watchMembers(spaceId);
}

/// The post that a 1-1 conversation was started from (quoted photo header).
/// Returns null when the conversation has no originating post.
/// TODO(C/wire): replace with `postRepository.getPost(quotedPostId)`.
@riverpod
Post? chatQuotedPost(Ref ref, String? quotedPostId) {
  if (quotedPostId == null) return null;
  final post = ChatSeed.quotedPost();
  return post.postId == quotedPostId ? post : null;
}
