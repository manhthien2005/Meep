import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/chat/application/chat_providers.dart';
import 'package:meep/features/chat/data/message.dart';
import 'package:meep/features/chat/presentation/chat_time_format.dart';
import 'package:meep/features/chat/presentation/widgets/message_bubble.dart';
import 'package:meep/features/chat/presentation/widgets/message_quoted_post.dart';
import 'package:meep/shared/widgets/app_avatar.dart';

/// Scrollable message list for a thread (shared by 1-1 + group).
///
/// Empty thread → CTA (`769:3019`). Messages → chronological bubble list,
/// mỗi message reply post gắn 1 mini quoted card phía trên bubble (FB story
/// reply pattern). Auto-scrolls to the newest message on open, when a message
/// is added, and as the keyboard opens (Messenger-style).
class ChatThreadView extends ConsumerStatefulWidget {
  const ChatThreadView({
    super.key,
    required this.messages,
    required this.myUid,
    required this.peerName,
    this.peerAvatarUrl,
    this.isGroup = false,
  });

  final List<Message> messages;
  final String myUid;
  final String peerName;
  final String? peerAvatarUrl;

  /// True khi đang render group chat (Space). Khi true: hiển thị tên sender
  /// phía trên message bubble cho "theirs" để phân biệt members.
  final bool isGroup;

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
    if (widget.messages.isEmpty) {
      return _EmptyThread(
        peerName: widget.peerName,
        peerAvatarUrl: widget.peerAvatarUrl,
      );
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      children: [
        for (var i = 0; i < widget.messages.length; i++) ...[
          if (_showSeparatorBefore(i))
            _TimeSeparator(time: widget.messages[i].createdAt),
          _ThreadMessageRow(
            message: widget.messages[i],
            isMine: widget.messages[i].senderId == widget.myUid,
            isLastInGroup: _isLastInGroup(i),
            showSenderName: widget.isGroup && _isFirstInGroup(i),
            // 1-1: peer avatar đã có sẵn từ header — pass thẳng tránh extra
            // lookup. Group: resolve per-sender qua chatUserProfileProvider.
            fallbackAvatarUrl: widget.peerAvatarUrl,
            resolvePerSender: widget.isGroup,
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

  // True khi message [i] là cuối cùng trong chuỗi consecutive cùng sender.
  // Pattern Messenger: chỉ message cuối của chuỗi mới render avatar — các
  // message trước render spacer 40px để giữ alignment.
  bool _isLastInGroup(int i) {
    if (i == widget.messages.length - 1) return true;
    return widget.messages[i].senderId != widget.messages[i + 1].senderId;
  }

  // True khi message [i] là đầu tiên trong chuỗi consecutive cùng sender.
  // Dùng để render senderName label 1 lần cho cả chuỗi (group chat).
  bool _isFirstInGroup(int i) {
    if (i == 0) return true;
    return widget.messages[i].senderId != widget.messages[i - 1].senderId;
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

/// Bọc [MessageBubble] + resolve sender name/avatar realtime.
///
/// **Group chat:** [resolvePerSender] = true → watch `chatUserProfileProvider`
/// theo `message.senderId` để lấy displayName + avatarUrl từ Firestore user
/// doc (real-time). KHÔNG dùng `message.senderDisplayName` denormalized vì:
/// 1. Messages cũ trước Bug #2 schema fix KHÔNG có field → hiển thị fallback.
/// 2. Sau khi user đổi displayName, denormalized field stale.
/// Riverpod tự dedupe — mỗi unique senderId chỉ 1 Firestore read.
///
/// **1-1 chat:** [resolvePerSender] = false → dùng [fallbackAvatarUrl] (peer
/// avatar đã có sẵn từ header). KHÔNG lookup vì peer đã resolve ở screen level.
class _ThreadMessageRow extends ConsumerWidget {
  const _ThreadMessageRow({
    required this.message,
    required this.isMine,
    required this.isLastInGroup,
    required this.showSenderName,
    required this.resolvePerSender,
    this.fallbackAvatarUrl,
  });

  final Message message;
  final bool isMine;
  final bool isLastInGroup;
  final bool showSenderName;
  final bool resolvePerSender;
  final String? fallbackAvatarUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1-1 — không cần lookup, dùng peer avatar đã có. Group — watch profile
    // theo senderId (Riverpod dedupe per uid).
    final profile = resolvePerSender
        ? ref.watch(chatUserProfileProvider(message.senderId)).valueOrNull
        : null;

    // senderName: ưu tiên realtime profile → denormalized field → null (UI
    // hide label thay vì render "Người dùng" — clean cho messages cũ).
    final senderName = profile?.displayName ?? message.senderDisplayName;
    final avatarUrl = resolvePerSender ? profile?.avatarUrl : fallbackAvatarUrl;

    // FB story reply pattern: mini quoted card phía trên bubble cho message
    // có quotedPostId. Lookup post real-time qua chatQuotedPostProvider —
    // Riverpod dedupe per postId nếu nhiều message cùng reply 1 post.
    final quotedPost = message.quotedPostId != null
        ? ref.watch(chatQuotedPostProvider(message.quotedPostId)).valueOrNull
        : null;

    return Column(
      crossAxisAlignment:
          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (quotedPost != null)
          MessageQuotedPost(
            imageUrl: quotedPost.coverImageUrl,
            caption: quotedPost.caption,
            isMine: isMine,
          ),
        MessageBubble(
          text: message.text,
          isMine: isMine,
          avatarUrl: avatarUrl,
          isLastInGroup: isLastInGroup,
          senderName: senderName,
          showSenderName: showSenderName,
        ),
      ],
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
              fallbackText: avatarFallbackFromName(peerName),
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
