import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/features/chat/application/chat_controller.dart';
import 'package:meep/features/chat/application/chat_providers.dart';

/// Auto-trigger `markAsRead` cho [conversationId] khi messages stream emit data:
/// - **On mount:** lần đầu data đến → fire 1 lần (debounce 500ms để chặn case
///   user mở rồi back nhanh).
/// - **On new message từ người khác:** detect message mới có `senderId != myUid`
///   → fire lại để badge taskbar reset realtime.
///
/// Tự đăng ký dispose Timer + không gọi nếu widget unmounted.
///
/// Widget này KHÔNG render gì (`SizedBox.shrink()`) — chỉ chạy side effect.
/// Đặt cạnh `ChatThreadView` trong `ChatScreen` / `GroupChatScreen`.
class MarkAsReadListener extends ConsumerStatefulWidget {
  const MarkAsReadListener({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<MarkAsReadListener> createState() => _MarkAsReadListenerState();
}

class _MarkAsReadListenerState extends ConsumerState<MarkAsReadListener> {
  Timer? _debounce;
  String? _lastSeenMessageId;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleMarkAsRead() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      final uid = ref.read(currentChatUidProvider);
      if (uid.isEmpty) return;
      await ref.read(conversationRepositoryProvider).markAsRead(
            conversationId: widget.conversationId,
            uid: uid,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(messagesProvider(widget.conversationId), (prev, next) {
      final msgs = next.valueOrNull;
      if (msgs == null || msgs.isEmpty) return;
      final newest = msgs.last;
      // First emit hoặc message mới — schedule mark-as-read.
      if (_lastSeenMessageId != newest.messageId) {
        _lastSeenMessageId = newest.messageId;
        _scheduleMarkAsRead();
      }
    });
    return const SizedBox.shrink();
  }
}
