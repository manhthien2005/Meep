import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/chat/application/chat_controller.dart';
import 'package:meep/features/chat/application/chat_providers.dart';
import 'package:meep/features/chat/data/conversation.dart';
import 'package:meep/features/chat/presentation/chat_thread_view.dart';
import 'package:meep/features/chat/presentation/widgets/chat_confirm_dialogs.dart';
import 'package:meep/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:meep/features/chat/presentation/widgets/chat_menu_sheet.dart';
import 'package:meep/features/friend/application/friend_controller.dart';
import 'package:meep/features/settings/application/settings_controller.dart';
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
    final peerUid =
        conversation?.participantIds.where((id) => id != myUid).firstOrNull;
    final peerAsync = ref.watch(chatUserProfileProvider(peerUid ?? ''));
    final peer = peerAsync.valueOrNull;

    final messagesAsync = ref.watch(messagesProvider(conversationId));
    final sendStatus = ref.watch(chatControllerProvider);
    final quotedPost =
        ref.watch(chatQuotedPostProvider(conversation?.quotedPostId));

    // status-driven readonly: blocked/unfriended → input ẩn + banner hiện.
    final status = conversation?.status ?? ConversationStatus.active;
    final isReadonly = status != ConversationStatus.active;

    // No composer for a brand-new conversation with no shared Meep: the only way
    // to start is by replying to a Meep (Figma `769:3019` has no input bar).
    final hasMessages = messagesAsync.valueOrNull?.isNotEmpty ?? false;
    final canCompose = !isReadonly && (hasMessages || quotedPost != null);

    return Scaffold(
      backgroundColor: AppColors.bw900,
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(
              title: peer?.displayName ?? 'Trò chuyện',
              avatarUrl: peer?.avatarUrl,
              onMenu: () => _onMenu(
                context,
                ref,
                peer?.displayName ?? 'người này',
                peerUid,
              ),
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
            if (isReadonly) _ReadonlyBanner(status: status),
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

  Future<void> _onMenu(
    BuildContext context,
    WidgetRef ref,
    String name,
    String? peerUid,
  ) async {
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
    if (action == null || !context.mounted || peerUid == null) return;

    switch (action) {
      case ChatMenuAction.unfriend:
        final confirmed = await showUnfriendDialog(context, name);
        if (!confirmed || !context.mounted) return;
        // FriendController là family on myUid — đọc từ currentChatUidProvider.
        final myUid = ref.read(currentChatUidProvider);
        await ref
            .read(friendControllerProvider(myUid).notifier)
            .unfriend(peerUid);
        if (!context.mounted) return;
        // Controller catch error → errorMessage trong state. Chỉ navigate khi sạch.
        final unfriendErr =
            ref.read(friendControllerProvider(myUid)).errorMessage;
        if (unfriendErr == null) {
          context.go('/inbox');
        }

      case ChatMenuAction.block:
        final confirmed = await showBlockSheet(context, name);
        if (!confirmed || !context.mounted) return;
        await ref.read(settingsControllerProvider.notifier).blockUser(peerUid);
        if (!context.mounted) return;
        final blockErr = ref.read(settingsControllerProvider).errorMessage;
        if (blockErr == null) {
          context.go('/inbox');
        }
    }
  }
}

/// Overflow-menu actions for a 1-1 chat.
enum ChatMenuAction { unfriend, block }

/// Banner thay input bar khi conversation `status != active`.
/// - `unfriended`: 2 user không còn là bạn → "Hãy thêm bạn lại để nhắn tin".
/// - `blocked`: 1 phía đã block → "Bạn không thể nhắn tin với người này".
class _ReadonlyBanner extends StatelessWidget {
  const _ReadonlyBanner({required this.status});

  final ConversationStatus status;

  @override
  Widget build(BuildContext context) {
    final text = switch (status) {
      ConversationStatus.unfriended => 'Hãy thêm bạn lại để nhắn tin',
      ConversationStatus.blocked => 'Bạn không thể nhắn tin với người này',
      ConversationStatus.active => '',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.smRegular.copyWith(color: AppColors.bw500),
      ),
    );
  }
}

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
