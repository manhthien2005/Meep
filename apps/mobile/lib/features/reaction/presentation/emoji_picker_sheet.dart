import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';

/// Full emoji picker bottom sheet. Mở từ smile-plus button trong
/// FriendPostActBar (Figma 472:2252). Không có search (MVP scope).
class EmojiPickerSheet extends StatelessWidget {
  const EmojiPickerSheet({super.key, required this.onEmojiSelected});

  final ValueChanged<String> onEmojiSelected;

  static void show(BuildContext context, ValueChanged<String> onSelected) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bw800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EmojiPickerSheet(onEmojiSelected: onSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.4,
      child: Column(
        children: [
          const SizedBox(height: 14),
          Text(
            'Chọn phản ứng',
            style: AppTextStyles.baseBold.copyWith(color: AppColors.bw100),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: _emojis.length,
              itemBuilder: (context, index) {
                final emoji = _emojis[index];
                return Semantics(
                  button: true,
                  label: 'Chọn $emoji',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onEmojiSelected(emoji);
                      Navigator.of(context).pop();
                    },
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Limited emoji set cho MVP — no search, no categories.
const _emojis = [
  '😀',
  '😃',
  '😄',
  '😁',
  '😅',
  '😂',
  '🤣',
  '😊',
  '😇',
  '🙂',
  '😉',
  '😌',
  '😍',
  '🥰',
  '😘',
  '😗',
  '😋',
  '😛',
  '😜',
  '🤪',
  '😝',
  '😎',
  '🤩',
  '🥳',
  '😏',
  '😒',
  '😞',
  '😔',
  '😢',
  '😭',
  '😤',
  '😡',
  '🤬',
  '😈',
  '👿',
  '👍',
  '👎',
  '👏',
  '🙌',
  '🤝',
  '💪',
  '🫶',
  '❤️',
  '🧡',
  '💛',
  '💚',
  '💙',
  '💜',
  '🩵',
  '🔥',
  '⭐',
  '🎉',
  '💯',
  '✨',
  '💩',
  '👀',
];
