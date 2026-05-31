import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/chat/application/chat_controller.dart';
import 'package:meep/features/chat/application/chat_providers.dart';
import 'package:meep/features/chat/data/conversation.dart';
import 'package:meep/features/chat/presentation/chat_thread_view.dart';
import 'package:meep/features/chat/presentation/widgets/chat_confirm_dialogs.dart';
import 'package:meep/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:meep/features/chat/presentation/widgets/chat_menu_sheet.dart';
import 'package:meep/shared/widgets/app_avatar.dart';

/// 1-1 direct chat thread. Figma `564:6934` (+ empty `769:3019`).
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final conversation = conversationsAsync.valueOrNull
        ?.where((c) => c.conversationId == conversationId)
        .firstOrNull;

    final myUid = ref.watch(currentChatUidProvider);
    final profiles = ref.watch(chatUserProfilesProvider);
    final peer = _resolvePeer(conversation, myUid, profiles);

    final messagesAsync = ref.watch(messagesProvider(conversationId));
    final sendStatus = ref.watch(chatControllerProvider);
    final quotedPost =
        ref.watch(chatQuotedPostProvider(conversation?.quotedPostId));

    // No composer for a brand-new conversation with no shared Meep: the only way
    // to start is by replying to a Meep (Figma `769:3019` has no input bar).
    final hasMessages = messagesAsync.valueOrNull?.isNotEmpty ?? false;
    final canCompose = hasMessages || quotedPost != null;

    return Scaffold(
      backgroundColor: AppColors.bw900,
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(
              title: peer?.displayName ?? 'Trò chuyện',
              avatarUrl: peer?.avatarUrl,
              onMenu: () =>
                  _onMenu(context, ref, peer?.displayName ?? 'người này'),
            ),
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.turquoise500,
                  ),
                ),
                error: (_, __) => const Center(
                  child: Text('Không tải được tin nhắn.'),
                ),
                data: (messages) => ChatThreadView(
                  messages: messages,
                  myUid: myUid,
                  peerAvatarUrl: peer?.avatarUrl,
                  quotedPostId: conversation?.quotedPostId,
                  peerName: peer?.displayName ?? '',
                ),
              ),
            ),
            if (canCompose)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: ChatInputBar(
                  isSending: sendStatus.isSending,
                  onSend: (text) => ref
                      .read(chatControllerProvider.notifier)
                      .sendMessage(conversationId: conversationId, text: text),
                ),
              ),
          ],
        ),
      ),
    );
  }

  UserProfile? _resolvePeer(
    Conversation? conversation,
    String myUid,
    Map<String, UserProfile> profiles,
  ) {
    if (conversation == null) return null;
    final otherUid =
        conversation.participantIds.where((id) => id != myUid).firstOrNull;
    return otherUid == null ? null : profiles[otherUid];
  }

  Future<void> _onMenu(BuildContext context, WidgetRef ref, String name) async {
    final action = await showSettingMenu<ChatMenuAction>(context, const [
      SettingMenuItem(
        icon: Icons.person_remove_outlined,
        label: 'Xóa bạn',
        value: ChatMenuAction.unfriend,
      ),
      SettingMenuItem(
        icon: Icons.block,
        label: 'Chặn',
        value: ChatMenuAction.block,
        isDestructive: true,
      ),
    ]);
    if (action == null || !context.mounted) return;

    switch (action) {
      case ChatMenuAction.unfriend:
        final confirmed = await showUnfriendDialog(context, name);
        if (confirmed) {
          // TODO(C/wire): ref.read(friendControllerProvider.notifier).unfriend(uid)
        }
      case ChatMenuAction.block:
        final confirmed = await showBlockSheet(context, name);
        if (confirmed) {
          // TODO(C/wire): ref.read(settingsControllerProvider.notifier).blockUser(uid)
        }
    }
  }
}

/// Overflow-menu actions for a 1-1 chat.
enum ChatMenuAction { unfriend, block }

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.title,
    required this.onMenu,
    this.avatarUrl,
  });

  final String title;
  final VoidCallback onMenu;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(
              Icons.chevron_left,
              size: 28,
              color: AppColors.bw100,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppAvatar(imageUrl: avatarUrl, size: 30),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    title,
                    style: AppTextStyles.baseBold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onMenu,
            child:
                const Icon(Icons.more_horiz, size: 24, color: AppColors.bw100),
          ),
        ],
      ),
    );
  }
}
