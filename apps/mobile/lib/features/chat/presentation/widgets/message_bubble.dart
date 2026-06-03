import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/shared/widgets/app_avatar.dart';

/// A single chat message bubble.
///
/// Mine (right): light bw200 fill, dark text, no avatar.
/// Theirs (left): translucent dark fill, light text, avatar leading.
/// Figma `564:6945` (theirs) / `564:6947` (mine).
///
/// Avatar dedupe: when [isLastInGroup] = false (next message từ cùng sender),
/// avatar được thay bằng spacer 40px để giữ alignment — pattern Messenger.
///
/// Group chat: when [showSenderName] = true && !isMine && senderName != null,
/// render tên sender phía trên bubble để phân biệt người gửi.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.text,
    required this.isMine,
    this.avatarUrl,
    this.isLastInGroup = true,
    this.senderName,
    this.showSenderName = false,
  });

  final String text;
  final bool isMine;
  final String? avatarUrl;

  /// True khi message này là cuối cùng trong chuỗi consecutive cùng sender.
  /// Khi false: ẩn avatar (giữ alignment qua SizedBox 40px).
  final bool isLastInGroup;

  /// Tên sender hiển thị phía trên bubble — chỉ dùng trong group chat.
  /// Null → KHÔNG render label (clean UI cho messages cũ chưa có denormalized
  /// name + chưa resolve được profile).
  final String? senderName;

  /// Bật rendering của senderName. Chỉ effect khi `!isMine` && senderName
  /// non-null/non-empty.
  final bool showSenderName;

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

    final hasName =
        showSenderName && !isMine && (senderName?.isNotEmpty ?? false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (hasName)
            // Align name với bubble (skip 46px = 40 avatar + 6 gap).
            Padding(
              padding: const EdgeInsets.only(left: 46, bottom: 4),
              child: Text(
                senderName!,
                style:
                    AppTextStyles.xsSemiBold.copyWith(color: AppColors.bw500),
              ),
            ),
          Row(
            mainAxisAlignment:
                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine) ...[
                if (isLastInGroup)
                  AppAvatar(imageUrl: avatarUrl, size: 40)
                else
                  const SizedBox(width: 40),
                const SizedBox(width: 6),
              ],
              Flexible(child: bubble),
            ],
          ),
        ],
      ),
    );
  }
}
