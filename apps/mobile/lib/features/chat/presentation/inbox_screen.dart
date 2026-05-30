import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/chat/application/chat_providers.dart';
import 'package:meep/features/chat/data/conversation.dart';
import 'package:meep/features/chat/presentation/widgets/conversation_tile.dart';
import 'package:meep/shared/widgets/app_taskbar.dart';

/// Inbox — list of all conversations (1-1 + group), newest first.
/// Figma `269:942`. Tapping a row opens the matching chat thread.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.bw900,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const _InboxTopbar(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: conversationsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.turquoise500,
                        ),
                      ),
                      error: (_, __) => const _InboxMessage(
                        text: 'Không tải được tin nhắn. Thử lại sau nhé.',
                      ),
                      data: (conversations) => conversations.isEmpty
                          ? const _InboxMessage(
                              text:
                                  'Chưa có tin nhắn nào — reply một ảnh để bắt đầu',
                            )
                          : _ConversationList(conversations: conversations),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppTaskbar(
                  activeTab: TaskbarTab.chat,
                  chatBadgeCount: 2,
                  onTabSelected: (tab) {
                    if (tab != TaskbarTab.chat) Navigator.maybePop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Topbar: centered title + trailing avatar slot.
/// TODO(C/HanDHG): thay bằng shared home-feed topbar khi Khoa implement.
class _InboxTopbar extends StatelessWidget {
  const _InboxTopbar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const SizedBox(width: 40),
          const Expanded(
            child: Text(
              'Tin nhắn',
              textAlign: TextAlign.center,
              style: AppTextStyles.baseBold,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bw700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationList extends ConsumerWidget {
  const _ConversationList({required this.conversations});

  final List<Conversation> conversations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(chatUserProfilesProvider);
    final unread = ref.watch(unreadCountsProvider);
    final myUid = ref.watch(currentChatUidProvider);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 90),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conv = conversations[index];
        final isUnread = (unread[conv.conversationId] ?? 0) > 0;

        if (conv.type == ConversationType.space) {
          final space = ref.watch(chatSpaceProvider(conv.spaceId ?? ''));
          return ConversationTile.group(
            spaceName: space.name,
            emoji: space.iconEmoji,
            colorHex: space.colorHex,
            conversation: conv,
            isUnread: isUnread,
            onTap: () => context.push('/group-chat/${conv.conversationId}'),
          );
        }

        final otherUid = conv.participantIds.firstWhere(
          (id) => id != myUid,
          orElse: () => myUid,
        );
        final other = profiles[otherUid];
        return ConversationTile.direct(
          displayName: other?.displayName ?? 'Người dùng',
          avatarUrl: other?.avatarUrl,
          conversation: conv,
          isUnread: isUnread,
          onTap: () => context.push('/chat/${conv.conversationId}'),
        );
      },
    );
  }
}

class _InboxMessage extends StatelessWidget {
  const _InboxMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.smMedium.copyWith(color: AppColors.bw500),
      ),
    );
  }
}
