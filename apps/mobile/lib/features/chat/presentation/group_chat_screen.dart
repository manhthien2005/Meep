import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/chat/application/chat_controller.dart';
import 'package:meep/features/chat/application/chat_providers.dart';
import 'package:meep/features/chat/presentation/chat_thread_view.dart';
import 'package:meep/features/chat/presentation/widgets/chat_confirm_dialogs.dart';
import 'package:meep/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:meep/features/chat/presentation/widgets/chat_menu_sheet.dart';
import 'package:meep/features/chat/presentation/widgets/space_members_sheet.dart';
import 'package:meep/shared/widgets/app_avatar.dart';

/// Space group chat thread. Figma `564:8603` (+ menu `564:8733`).
class GroupChatScreen extends ConsumerWidget {
  const GroupChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversation = ref
        .watch(conversationsProvider)
        .valueOrNull
        ?.where((c) => c.conversationId == conversationId)
        .firstOrNull;
    final spaceId = conversation?.spaceId ?? '';
    final space = ref.watch(chatSpaceProvider(spaceId));

    final myUid = ref.watch(currentChatUidProvider);
    final messagesAsync = ref.watch(messagesProvider(conversationId));
    final sendStatus = ref.watch(chatControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bw900,
      body: SafeArea(
        child: Column(
          children: [
            _GroupHeader(
              title: space.name,
              emoji: space.iconEmoji,
              colorHex: space.colorHex,
              onMenu: () => _onMenu(context, ref, spaceId),
            ),
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.turquoise500,
                  ),
                ),
                error: (_, __) =>
                    const Center(child: Text('Không tải được tin nhắn.')),
                data: (messages) => ChatThreadView(
                  messages: messages,
                  myUid: myUid,
                  peerName: space.name,
                ),
              ),
            ),
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
    String spaceId,
  ) async {
    final action = await showSettingMenu<GroupMenuAction>(context, const [
      SettingMenuItem(
        icon: Icons.palette_outlined,
        label: 'Chỉnh sửa theme',
        value: GroupMenuAction.editTheme,
      ),
      SettingMenuItem(
        icon: Icons.group_outlined,
        label: 'Xem thành viên',
        value: GroupMenuAction.viewMembers,
      ),
      SettingMenuItem(
        icon: Icons.logout,
        label: 'Rời khỏi Space',
        value: GroupMenuAction.leaveSpace,
        isDestructive: true,
      ),
    ]);
    if (action == null || !context.mounted) return;

    switch (action) {
      case GroupMenuAction.editTheme:
        // TODO(C/wire): open Space theme editor (Space module).
        break;
      case GroupMenuAction.viewMembers:
        await SpaceMembersSheet.show(context, spaceId);
      case GroupMenuAction.leaveSpace:
        final confirmed = await showLeaveSpaceDialog(context);
        if (confirmed) {
          // TODO(C/wire): ref.read(spaceControllerProvider.notifier).leaveSpace(spaceId)
        }
    }
  }
}

/// Overflow-menu actions for a Space group chat.
enum GroupMenuAction { editTheme, viewMembers, leaveSpace }

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.title,
    required this.emoji,
    required this.colorHex,
    required this.onMenu,
  });

  final String title;
  final String emoji;
  final String colorHex;
  final VoidCallback onMenu;

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
                AppSpaceAvatar(emoji: emoji, colorHex: colorHex, size: 30),
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
