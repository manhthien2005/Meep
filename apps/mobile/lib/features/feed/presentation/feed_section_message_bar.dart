part of 'feed_section.dart';

/// Friend message bar — 2-state inline composer trên Feed:
/// - **Collapsed** (mặc định): text "Gửi tin nhắn..." + 3 emoji quick-react
///   (💙🤣🥰 — Figma 472:2252) + smile-plus picker. Tap text trái → expand
///   sang modal composer. Tap emoji → `ReactionController.toggleReact`
///   (optimistic + in-flight lock). Tap smile-plus → `EmojiPickerSheet`.
/// - **Expanded:** TextField focused + send button. Tap-outside hoặc submit →
///   collapse. Submit gọi `ChatController.sendMessageFromFeed(postId, authorId)`
///   để tạo/lookup direct conversation rồi append message.
class FriendMessageBar extends ConsumerStatefulWidget {
  const FriendMessageBar({
    super.key,
    required this.postId,
    required this.authorId,
    this.spaceId,
  });

  /// postId — context cho `sendMessageFromFeed` (lưu quotedPostId tương lai)
  /// và cho `reactionControllerProvider(postId)`.
  final String postId;

  /// authorId — peer uid để `getOrCreateConversation` tính pairId.
  /// Khi [spaceId] != null, authorId chỉ dùng tham chiếu — message forward
  /// sang space chat thay vì 1-1.
  final String authorId;

  /// spaceId — nếu post được share trong Space, reply forward sang group
  /// conversation của Space (`conversationId == spaceId`). Null = post
  /// all-friends → forward 1-1 với author.
  final String? spaceId;

  @override
  ConsumerState<FriendMessageBar> createState() => _FriendMessageBarState();
}

class _FriendMessageBarState extends ConsumerState<FriendMessageBar> {
  bool _isSending = false;
  final math.Random _rng = math.Random();

  // 💙 (U+1F499) ổn định cross-Android; tránh 🩵 (U+1FA75 — Unicode 14.0) bị
  // tofu trên Android < 12. Khớp chat_input_bar.quickEmojis default.
  static const _defaultPresets = ['💙', '🤣', '🥰'];

  // 1 GlobalKey per slot — dùng để lấy global position khi spawn bubble float
  // animation (Overlay cần absolute position, không phải local của widget).
  final List<GlobalKey> _slotKeys = List.generate(3, (_) => GlobalKey());
  final GlobalKey _smilePlusKey = GlobalKey();

  /// Nếu user đã pick emoji custom (qua EmojiPickerSheet, không thuộc 3
  /// default presets), replace slot 0 (💙) bằng emoji đó. Giúp user thấy
  /// rõ mình đã chọn gì — nếu không sẽ "lost" sau khi đóng picker.
  List<String> _displayPresets(String? myEmoji) {
    if (myEmoji == null || _defaultPresets.contains(myEmoji)) {
      return _defaultPresets;
    }
    return [myEmoji, _defaultPresets[1], _defaultPresets[2]];
  }

  /// Spawn 3 emoji bubbles staggered từ vị trí button được tap, float lên
  /// kiểu Locket. Mỗi bubble drift X random + fade out 1.5s.
  void _spawnBubbles(String emoji, GlobalKey slotKey) {
    final box = slotKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final centerLocal = Offset(box.size.width / 2, box.size.height / 2);
    final centerGlobal = box.localToGlobal(centerLocal);
    final overlay = Overlay.of(context);
    // 3 bubbles spawn delayed (150ms gap) → wave effect rõ kiểu Locket.
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: 150 * i), () {
        if (!mounted) return;
        late OverlayEntry entry;
        entry = OverlayEntry(
          builder: (_) => _EmojiBubble(
            emoji: emoji,
            startGlobal: centerGlobal,
            driftX: (_rng.nextDouble() - 0.5) * 80, // -40 → +40
            onComplete: () => entry.remove(),
          ),
        );
        overlay.insert(entry);
      });
    }
  }

  /// Mở modal bottom sheet composer thay vì inline TextField.
  ///
  /// **Lý do:** HomeFeed scaffold có camera fixed + taskbar pinned bottom.
  /// Inline TextField + keyboard mở → Scaffold cố resize body → overflow
  /// (camera không shrink) + taskbar lift theo keyboard. Modal sheet có own
  /// scaffold context → keyboard handling tự nhiên, KHÔNG ảnh hưởng layout
  /// home. Pattern Locket / Instagram story reply.
  Future<void> _openComposer() async {
    if (_isSending) return;
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Cho phép sheet ngập keyboard area — sheet content tự padding bottom
      // bằng MediaQuery.viewInsets.
      builder: (sheetContext) => _ComposerSheet(
        onSend: (text) async {
          if (text.isEmpty) return false;
          setState(() => _isSending = true);
          final conversationId = await ref
              .read(chatControllerProvider.notifier)
              .sendMessageFromFeed(
                postId: widget.postId,
                authorId: widget.authorId,
                text: text,
                spaceId: widget.spaceId,
              );
          if (!mounted) return false;
          setState(() => _isSending = false);
          if (conversationId != null) {
            // Pattern Locket: navigate to chat screen với quoted photo block
            // ở đầu thread. Group → /group-chat, else 1-1 /chat.
            final isSpace =
                widget.spaceId != null && widget.spaceId!.isNotEmpty;
            final route = isSpace
                ? '/group-chat/$conversationId'
                : '/chat/$conversationId';
            if (sheetContext.mounted) Navigator.of(sheetContext).pop(true);
            unawaited(context.push(route));
            return true;
          } else {
            // Controller đã set errorMessage trong state — read để show.
            final err = ref.read(chatControllerProvider).errorMessage;
            if (sheetContext.mounted) {
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                SnackBar(
                  content: Text(err ?? 'Không gửi được tin nhắn'),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            return false;
          }
        },
      ),
    );
  }

  /// Safe toggle reaction — spawn bubble animation trước (instant UX feedback,
  /// không đợi network), rồi gọi controller toggle. Bắt lỗi → toast message.
  ///
  /// displayName + avatarUrl lấy từ UserProfile (Firestore /users/{uid}) thay
  /// vì chỉ FirebaseAuth.currentUser — đảm bảo có data đúng cho mọi auth method
  /// (Google / email signup). uid lấy từ currentUidProvider (auth abstraction)
  /// thay vì Firebase Auth singleton trực tiếp — giữ layering UI → repository.
  void _toggleReaction(String emoji, [GlobalKey? sourceKey]) {
    if (sourceKey != null) _spawnBubbles(emoji, sourceKey);
    try {
      final uid = ref.read(currentUidProvider).valueOrNull;
      if (uid == null) return;
      final profile = ref.read(currentUserProfileProvider).valueOrNull;
      final displayName = (profile?.displayName.isNotEmpty ?? false)
          ? profile!.displayName
          : '';
      final avatarUrl = profile?.avatarUrl;
      ref.read(reactionControllerProvider(widget.postId).notifier).toggleReact(
            uid: uid,
            displayName: displayName,
            avatarUrl: avatarUrl,
            emoji: emoji,
          );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thả cảm xúc thất bại — thử lại'),
          backgroundColor: AppColors.bw700,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final screenH = MediaQuery.sizeOf(context).height;
    final reactionState = ref.watch(reactionControllerProvider(widget.postId));

    // Show error toast nếu reaction controller có errorMessage.
    if (reactionState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reactionState.errorMessage!),
            backgroundColor: AppColors.bw700,
            duration: const Duration(seconds: 2),
          ),
        );
        ref
            .read(reactionControllerProvider(widget.postId).notifier)
            .clearError();
      });
    }

    return Container(
      height: screenH * 0.07,
      width: screenW * 0.8,
      decoration: BoxDecoration(
        color: AppColors.bw800,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openComposer,
              child: Text(
                'Gửi tin nhắn...',
                style: TextStyle(
                  color: AppColors.bw100,
                  fontSize: screenW * 0.042,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ),
          for (var i = 0; i < 3; i++)
            _EmojiButton(
              key: _slotKeys[i],
              emoji: _displayPresets(reactionState.myEmoji)[i],
              isActive: reactionState.myEmoji ==
                  _displayPresets(reactionState.myEmoji)[i],
              onTap: () => _toggleReaction(
                _displayPresets(reactionState.myEmoji)[i],
                _slotKeys[i],
              ),
            ),
          const SizedBox(width: 10),
          GestureDetector(
            key: _smilePlusKey,
            onTap: () => EmojiPickerSheet.show(
              context,
              (emoji) => _toggleReaction(emoji, _smilePlusKey),
            ),
            child: const Icon(
              Icons.add_reaction_outlined,
              color: AppColors.bw500,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

/// Emoji preset button — subtle opacity feedback active/inactive.
/// Visual chính khi user thả reaction = bubble float animation
/// (spawn từ _FriendMessageBarState._spawnBubbles), + replace slot 0 nếu
/// emoji custom (xem _displayPresets).
/// KHÔNG set fontFamily — để platform emoji font render glyph, tránh tofu
/// (theo pattern chat_input_bar).
class _EmojiButton extends StatelessWidget {
  const _EmojiButton({
    super.key,
    required this.emoji,
    required this.isActive,
    required this.onTap,
  });

  final String emoji;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isActive ? 1.0 : 0.6,
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 22),
          ),
        ),
      ),
    );
  }
}

/// Locket-style bubble float — emoji nổi lên + drift X + scale + fade out.
/// Spawn từ Overlay nên không bị clip bởi ActText container.
/// Tự remove khỏi overlay khi animation complete (1.5s).
class _EmojiBubble extends StatefulWidget {
  const _EmojiBubble({
    required this.emoji,
    required this.startGlobal,
    required this.driftX,
    required this.onComplete,
  });

  final String emoji;
  final Offset startGlobal;
  final double driftX;
  final VoidCallback onComplete;

  @override
  State<_EmojiBubble> createState() => _EmojiBubbleState();
}

class _EmojiBubbleState extends State<_EmojiBubble>
    with SingleTickerProviderStateMixin {
  static const _emojiSize = 32.0;
  static const _riseDistance = 160.0;

  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      // 2.4s — đủ thong thả để mắt theo dõi quỹ đạo, không cảm giác "vọt".
      duration: const Duration(milliseconds: 3000),
    )
      ..forward()
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onComplete();
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        // EaseOutQuad: 1 - (1-t)² — distribution đều hơn easeOutCubic.
        // Tại t=0.5 đi 75% distance (vs cubic 87.5%) → mắt theo dõi
        // mượt, không cảm giác "vọt lên rồi đứng".
        final tEase = 1 - (1 - t) * (1 - t);
        final dy = -_riseDistance * tEase;
        // Drift X theo sine wave nhẹ — wobble bồng bềnh kiểu bong bóng.
        final dx = widget.driftX * tEase + math.sin(t * math.pi * 2) * 6.0;
        // Fade tuyến tính 30% → 100% → bubble vẫn nhìn thấy được suốt
        // phần lớn animation, chỉ mờ dần ở cuối.
        final opacity = (1.0 - math.max(0.0, (t - 0.3) / 0.7)).clamp(0.0, 1.0);
        final scale = 1.0 + (0.2 * t);

        return Positioned(
          left: widget.startGlobal.dx - _emojiSize / 2 + dx,
          top: widget.startGlobal.dy - _emojiSize / 2 + dy,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                // Overlay không có DefaultTextStyle → Flutter debug fallback
                // render Text với gạch chân vàng + chữ đỏ. Phải set explicit
                // decoration + color + textDirection để tắt fallback đó.
                child: Text(
                  widget.emoji,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: _emojiSize,
                    decoration: TextDecoration.none,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Modal bottom sheet composer — kẹp keyboard, không ảnh hưởng home layout.
class _ComposerSheet extends StatefulWidget {
  const _ComposerSheet({required this.onSend});

  /// Returns true if message sent successfully.
  final Future<bool> Function(String text) onSend;

  @override
  State<_ComposerSheet> createState() => _ComposerSheetState();
}

class _ComposerSheetState extends State<_ComposerSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    // Defer focus để bottom sheet render xong trước khi keyboard mở.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    await widget.onSend(text);
    if (!mounted) return;
    setState(() => _isSending = false);
    // Send fail → onSend callback đã show snackbar. Controller text giữ
    // nguyên (mặc định) → user thử lại được.
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      // Padding bottom = keyboard height → sheet lift above keyboard.
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bw800,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !_isSending,
                maxLength: 500,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Gửi tin nhắn...',
                  hintStyle: TextStyle(
                    color: AppColors.bw500,
                    fontSize: screenW * 0.042,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Nunito',
                  ),
                  border: InputBorder.none,
                  isCollapsed: true,
                  counterText: '',
                ),
                style: TextStyle(
                  color: AppColors.bw100,
                  fontSize: screenW * 0.042,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
            if (_controller.text.trim().isNotEmpty)
              GestureDetector(
                onTap: _send,
                child: Icon(
                  Icons.send_rounded,
                  color: _isSending ? AppColors.bw500 : AppColors.turquoise500,
                  size: 22,
                ),
              )
            else
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.close,
                  color: AppColors.bw500,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
