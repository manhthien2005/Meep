import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/chat/presentation/widgets/chat_avatar.dart';

/// A single chat message bubble.
///
/// Mine (right): light bw200 fill, dark text, no avatar.
/// Theirs (left): translucent dark fill, light text, avatar leading.
/// Figma `564:6945` (theirs) / `564:6947` (mine).
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.text,
    required this.isMine,
    this.avatarUrl,
  });

  final String text;
  final bool isMine;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: isMine ? AppColors.bw200 : const Color(0x6E585754),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        text,
        style: AppTextStyles.smSemiBold.copyWith(
          color: isMine ? AppColors.turquoise900 : AppColors.bw100,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            ChatAvatar(imageUrl: avatarUrl, size: 40),
            const SizedBox(width: 6),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }
}
