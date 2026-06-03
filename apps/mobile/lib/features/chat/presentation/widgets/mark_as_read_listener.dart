import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/features/chat/application/chat_controller.dart';
import 'package:meep/features/chat/application/chat_providers.dart';

/// Auto-trigger `markAsRead` cho [conversationId]:
/// - **On mount:** fire 1 lần ngay khi widget mounted (postFrameCallback)
///   — KHÔNG đợi messages stream emit. Lý do: `ref.listen` của Riverpod
///   không fire on initial value của StreamProvider khi cached, nên nếu
///   chỉ dùng listener thì user mở conversation có tin chưa đọc sẽ KHÔNG
///   reset badge cho đến khi reply.
/// - **On new message từ peer/member:** detect message mới có `senderId !=
///   myUid` (qua diff stream emit) → fire lại để badge reset realtime
///   mà KHÔNG cần đóng/mở screen.
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
  bool _initialFired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fireInitial());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _fireInitial() {
    if (!mounted || _initialFired) return;
    _initialFired = true;
    // Sync `_lastSeenMessageId` với snapshot hiện tại để listener KHÔNG
    // fire trùng cho cùng tin nhắn vừa load.
    final msgs = ref.read(messagesProvider(widget.conversationId)).valueOrNull;
    if (msgs != null && msgs.isNotEmpty) {
      _lastSeenMessageId = msgs.last.messageId;
    }
    // Fire bất kể có message hay không — mark conversation as "đã mở".
    _scheduleMarkAsRead();
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
      if (!_initialFired) return; // initState đã fire — bỏ qua replay đầu tiên
      final msgs = next.valueOrNull;
      if (msgs == null || msgs.isEmpty) return;
      final newest = msgs.last;
      if (_lastSeenMessageId != newest.messageId) {
        _lastSeenMessageId = newest.messageId;
        _scheduleMarkAsRead();
      }
    });
    return const SizedBox.shrink();
  }
}
