import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';

/// Chat composer with two states (Figma `564:6935` ActText):
///  - blurred: placeholder + 3 quick-send emoji + emoji-picker icon
///  - focused: text field + emoji-picker icon + send button (quick-send hidden)
///
/// Quick-send emoji send immediately; the send button sends the typed text.
/// Tap icon emoji-picker → bottom sheet `EmojiPicker` (emoji_picker_flutter
/// v4.4.0) — chọn emoji single-fire onSend như quick-react.
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    this.isSending = false,
    this.errorText,
    this.quickEmojis = const ['💙', '🤣', '🥰'],
  });

  final Future<bool> Function(String text) onSend;
  final bool isSending;
  final String? errorText;
  final List<String> quickEmojis;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});
  void _onTextChange() => setState(() {});

  bool get _isExpanded => _focusNode.hasFocus || _controller.text.isNotEmpty;
  bool get _canSend => _controller.text.trim().isNotEmpty && !widget.isSending;

  Future<void> _submit() async {
    if (!_canSend) return;
    final sent = await widget.onSend(_controller.text.trim());
    if (sent && mounted) _controller.clear();
  }

  Future<void> _openEmojiPicker() async {
    if (widget.isSending) return;
    // Bỏ focus TextField để bottom sheet chiếm keyboard area sạch sẽ.
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.bw800,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: 320,
          child: EmojiPicker(
            onEmojiSelected: (_, emoji) =>
                Navigator.of(sheetContext).pop(emoji.emoji),
            config: const Config(
              height: 320,
              checkPlatformCompatibility: true,
              emojiViewConfig: EmojiViewConfig(
                backgroundColor: AppColors.bw800,
                columns: 7,
                emojiSizeMax: 28,
              ),
              categoryViewConfig: CategoryViewConfig(
                backgroundColor: AppColors.bw800,
                indicatorColor: AppColors.turquoise500,
                iconColorSelected: AppColors.turquoise500,
                iconColor: AppColors.bw500,
              ),
              skinToneConfig: SkinToneConfig(enabled: false),
              bottomActionBarConfig: BottomActionBarConfig(enabled: false),
            ),
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await widget.onSend(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0x66252627),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style:
                      AppTextStyles.mdRegular.copyWith(color: AppColors.bw100),
                  cursorColor: AppColors.turquoise500,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Gửi tin nhắn...',
                    hintStyle: AppTextStyles.mdRegular.copyWith(
                      color: AppColors.bw400,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_isExpanded)
                ..._expandedActions()
              else
                ..._collapsedActions(),
            ],
          ),
          if (widget.errorText != null) _SendErrorRow(onRetry: _submit),
        ],
      ),
    );
  }

  Widget _emojiPickerButton() => Semantics(
        label: 'Mở bảng chọn emoji',
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.isSending ? null : _openEmojiPicker,
          child: const Icon(
            Icons.add_reaction_outlined,
            size: 24,
            color: AppColors.bw100,
          ),
        ),
      );

  List<Widget> _collapsedActions() => [
        for (final emoji in widget.quickEmojis)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: GestureDetector(
              onTap: widget.isSending ? null : () => widget.onSend(emoji),
              // No fontFamily: let the platform emoji font render the glyph.
              // Forcing Nunito drops newer emoji (e.g. 🩵 U+1FA75) to tofu.
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
        const SizedBox(width: 4),
        _emojiPickerButton(),
      ];

  List<Widget> _expandedActions() => [
        _emojiPickerButton(),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _submit,
          child: Icon(
            Icons.send_rounded,
            size: 24,
            color: _canSend ? AppColors.turquoise500 : AppColors.bw500,
          ),
        ),
      ];
}

class _SendErrorRow extends StatelessWidget {
  const _SendErrorRow({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error500,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Chưa gửi được tin nhắn',
              style: AppTextStyles.xsRegular.copyWith(
                color: AppColors.error500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'Thử lại',
              style: AppTextStyles.xsSemiBold.copyWith(
                color: AppColors.turquoise500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
