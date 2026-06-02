import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/chat/application/chat_providers.dart';
import 'package:meep/features/chat/data/message.dart';
import 'package:meep/features/chat/presentation/chat_time_format.dart';
import 'package:meep/features/chat/presentation/widgets/message_bubble.dart';
import 'package:meep/features/chat/presentation/widgets/quoted_photo_block.dart';
import 'package:meep/shared/widgets/app_avatar.dart';

/// Scrollable message list for a thread (shared by 1-1 + group).
///
/// Shows the originating quoted photo at the top when [quotedPostId] resolves,
/// the empty-thread CTA (`769:3019`) when there are no messages, otherwise the
/// chronological bubble list. Auto-scrolls to the newest message on open, when
/// a message is added, and as the keyboard opens (Messenger-style).
class ChatThreadView extends ConsumerStatefulWidget {
  const ChatThreadView({
    super.key,
    required this.messages,
    required this.myUid,
    required this.peerName,
    this.peerAvatarUrl,
    this.quotedPostId,
  });

  final List<Message> messages;
  final String myUid;
  final String peerName;
  final String? peerAvatarUrl;
  final String? quotedPostId;

  @override
  ConsumerState<ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends ConsumerState<ChatThreadView>
    with WidgetsBindingObserver {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  @override
  void didUpdateWidget(ChatThreadView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
    }
  }

  // Keyboard open/close changes the bottom inset over several frames; pin the
  // list to the newest message so the composer never covers it.
  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  void _jumpToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final quoted = ref.watch(chatQuotedPostProvider(widget.quotedPostId));

    if (widget.messages.isEmpty && quoted == null) {
      return _EmptyThread(
        peerName: widget.peerName,
        peerAvatarUrl: widget.peerAvatarUrl,
      );
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      children: [
        if (quoted != null)
          QuotedPhotoBlock(
            imageUrl: quoted.coverImageUrl,
            caption: quoted.caption,
            createdAt: quoted.createdAt,
          ),
        for (var i = 0; i < widget.messages.length; i++) ...[
          if (_showSeparatorBefore(i))
            _TimeSeparator(time: widget.messages[i].createdAt),
          MessageBubble(
            text: widget.messages[i].text,
            isMine: widget.messages[i].senderId == widget.myUid,
            avatarUrl: widget.peerAvatarUrl,
          ),
        ],
      ],
    );
  }

  // First message always carries a separator; later ones only when the gap
  // from the previous message reaches [threadSeparatorGap] (1 hour).
  bool _showSeparatorBefore(int i) {
    if (i == 0) return true;
    final gap = widget.messages[i].createdAt
        .difference(widget.messages[i - 1].createdAt);
    return gap >= threadSeparatorGap;
  }
}

class _TimeSeparator extends StatelessWidget {
  const _TimeSeparator({required this.time});

  final DateTime time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          formatThreadSeparator(time),
          style: AppTextStyles.xsSemiBold.copyWith(color: AppColors.bw500),
        ),
      ),
    );
  }
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread({required this.peerName, this.peerAvatarUrl});

  final String peerName;
  final String? peerAvatarUrl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppAvatar(
              imageUrl: peerAvatarUrl,
              size: 95,
              ringColor: AppColors.bw600,
            ),
            const SizedBox(height: 32),
            Text(
              'Bắt đầu cuộc hội thoại!',
              textAlign: TextAlign.center,
              style: AppTextStyles.lgBold.copyWith(color: AppColors.bw100),
            ),
            const SizedBox(height: 13),
            Text(
              'Trả lời một Meep của $peerName để bắt đầu trò chuyện',
              textAlign: TextAlign.center,
              // text-base/SemiBold (18 w600) — override weight off baseBold.
              style: AppTextStyles.baseBold.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.bw600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
