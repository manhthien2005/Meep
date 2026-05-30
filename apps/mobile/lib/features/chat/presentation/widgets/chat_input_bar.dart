import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';

/// Chat composer with two states (Figma `564:6935` ActText):
///  - blurred: placeholder + 3 quick-send emoji + emoji-picker icon
///  - focused: text field + emoji-picker icon + send button (quick-send hidden)
///
/// Quick-send emoji send immediately; the send button sends the typed text.
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    this.isSending = false,
    this.quickEmojis = const ['🩵', '🤣', '🥰'],
  });

  final void Function(String text) onSend;
  final bool isSending;
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

  void _submit() {
    if (!_canSend) return;
    widget.onSend(_controller.text.trim());
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0x66252627),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: AppTextStyles.mdRegular.copyWith(color: AppColors.bw100),
              cursorColor: AppColors.turquoise500,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Gửi tin nhắn...',
                hintStyle:
                    AppTextStyles.mdRegular.copyWith(color: AppColors.bw400),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_isExpanded) ..._expandedActions() else ..._collapsedActions(),
        ],
      ),
    );
  }

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
        const Icon(
          Icons.add_reaction_outlined,
          size: 24,
          color: AppColors.bw100,
        ),
      ];

  List<Widget> _expandedActions() => [
        const Icon(
          Icons.add_reaction_outlined,
          size: 24,
          color: AppColors.bw100,
        ),
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
