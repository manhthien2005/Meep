import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/chat/application/chat_controller.dart';
import 'package:meep/features/chat/application/chat_providers.dart';
import 'package:meep/features/chat/data/message.dart';
import 'package:meep/features/chat/presentation/chat_thread_view.dart';
import 'package:meep/features/chat/presentation/widgets/chat_confirm_dialogs.dart';
import 'package:meep/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:meep/features/chat/presentation/widgets/chat_menu_sheet.dart';
import 'package:meep/features/chat/presentation/widgets/mark_as_read_listener.dart';
import 'package:meep/features/chat/presentation/widgets/space_members_sheet.dart';
import 'package:meep/features/space/application/space_controller.dart';
import 'package:meep/features/space/presentation/space_edit_sheet.dart';
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
    final spaceAsync = ref.watch(chatSpaceProvider(spaceId));
    final space = spaceAsync.valueOrNull;

    final myUid = ref.watch(currentChatUidProvider);
    final isCreator = space != null && space.creatorId == myUid;
    final messagesAsync = ref.watch(messagesProvider(conversationId));
    final sendStatus = ref.watch(chatControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bw900,
      // Default true nhưng explicit để rõ intent: keyboard mở → Scaffold tự
      // shrink body height → Column compresses → ChatInputBar lift lên trên.
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Side-effect listener (no render) — auto markAsRead on mount +
            // mỗi khi messages stream emit msg mới. Debounce 500ms.
            MarkAsReadListener(conversationId: conversationId),
            _GroupHeader(
              title: space?.name ?? 'Space',
              emoji: space?.iconEmoji ?? '👥',
              colorHex: space?.colorHex ?? '#00DEEE',
              onMenu: () => _onMenu(context, ref, spaceId, isCreator),
            ),
            Expanded(
              child: _GroupMessageList(
                messagesAsync: messagesAsync,
                myUid: myUid,
                spaceName: space?.name ?? '',
              ),
            ),
            AnimatedPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
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
    bool isCreator,
  ) async {
    // Action set gating: viewMembers + leaveSpace cho mọi member; editSpace
    // chỉ creator (UI guard layer 1, defense in depth với rules + CF).
    final action = await showSettingMenu<GroupMenuAction>(context, [
      const SettingMenuItem(
        icon: Icons.group_outlined,
        label: 'Xem thành viên',
        value: GroupMenuAction.viewMembers,
      ),
      if (isCreator)
        const SettingMenuItem(
          icon: Icons.edit_outlined,
          label: 'Chỉnh sửa Space',
          value: GroupMenuAction.editSpace,
        ),
      const SettingMenuItem(
        icon: Icons.logout,
        label: 'Rời khỏi Space',
        value: GroupMenuAction.leaveSpace,
        isDestructive: true,
      ),
    ]);
    if (action == null || !context.mounted) return;

    switch (action) {
      case GroupMenuAction.viewMembers:
        await SpaceMembersSheet.show(context, spaceId);
      case GroupMenuAction.editSpace:
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => SpaceEditSheet(spaceId: spaceId),
        );
      case GroupMenuAction.leaveSpace:
        final confirmed = await showLeaveSpaceDialog(context);
        if (!confirmed || !context.mounted) return;
        // SpaceController là family on myUid — đọc từ currentChatUidProvider.
        final myUid = ref.read(currentChatUidProvider);
        await ref
            .read(spaceControllerProvider(myUid).notifier)
            .leaveSpace(spaceId);
        if (!context.mounted) return;
        // Controller catch error → errorMessage trong state. Chỉ navigate khi sạch.
        final leaveErr = ref.read(spaceControllerProvider(myUid)).errorMessage;
        if (leaveErr == null) {
          context.go('/inbox');
        }
    }
  }
}

/// Overflow-menu actions for a Space group chat.
/// `editSpace` chỉ visible cho creator — gating ở `_onMenu` build action list.
enum GroupMenuAction { viewMembers, editSpace, leaveSpace }

/// Render group messages giữ last value qua loading-on-reload — tránh flicker
/// spinner khi user send message. Xem doc trong `chat_screen.dart::_MessageList`
/// để biết lý do KHÔNG dùng `messagesAsync.when`.
class _GroupMessageList extends StatelessWidget {
  const _GroupMessageList({
    required this.messagesAsync,
    required this.myUid,
    required this.spaceName,
  });

  final AsyncValue<List<Message>> messagesAsync;
  final String myUid;
  final String spaceName;

  @override
  Widget build(BuildContext context) {
    final messages = messagesAsync.valueOrNull;
    if (messages != null) {
      return ChatThreadView(
        messages: messages,
        myUid: myUid,
        peerName: spaceName,
        isGroup: true,
      );
    }
    if (messagesAsync.hasError) {
      return const Center(child: Text('Không tải được tin nhắn.'));
    }
    return const Center(
      child: CircularProgressIndicator(color: AppColors.turquoise500),
    );
  }
}

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
