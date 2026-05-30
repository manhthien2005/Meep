import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/chat/data/conversation.dart';
import 'package:meep/features/chat/presentation/chat_time_format.dart';
import 'package:meep/features/chat/presentation/widgets/chat_avatar.dart';

/// One row in the inbox list — 1-1 or group conversation.
///
/// Unread conversations render name/preview in a brighter tone (bw100/bw300)
/// per Figma; read ones dim to bw300/bw500.
class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.title,
    required this.preview,
    required this.timestamp,
    required this.onTap,
    this.avatarUrl,
    this.spaceEmoji,
    this.spaceColorHex,
    this.isUnread = false,
  });

  /// Build a tile for a direct (1-1) conversation.
  factory ConversationTile.direct({
    required String displayName,
    String? avatarUrl,
    required Conversation conversation,
    required bool isUnread,
    required VoidCallback onTap,
  }) {
    return ConversationTile(
      title: displayName,
      avatarUrl: avatarUrl,
      preview: conversation.lastMessage,
      timestamp: formatInboxTimestamp(conversation.lastMessageAt),
      isUnread: isUnread,
      onTap: onTap,
    );
  }

  /// Build a tile for a space (group) conversation.
  factory ConversationTile.group({
    required String spaceName,
    required String emoji,
    required String colorHex,
    required Conversation conversation,
    required bool isUnread,
    required VoidCallback onTap,
  }) {
    return ConversationTile(
      title: spaceName,
      spaceEmoji: emoji,
      spaceColorHex: colorHex,
      preview: conversation.lastMessage,
      timestamp: formatInboxTimestamp(conversation.lastMessageAt),
      isUnread: isUnread,
      onTap: onTap,
    );
  }

  final String title;
  final String preview;
  final String timestamp;
  final VoidCallback onTap;
  final String? avatarUrl;
  final String? spaceEmoji;
  final String? spaceColorHex;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    final titleColor = isUnread ? AppColors.bw100 : AppColors.bw300;
    final previewColor = isUnread ? AppColors.bw100 : AppColors.bw500;
    final timeColor = isUnread ? AppColors.bw300 : AppColors.bw500;
    final ringColor = isUnread ? AppColors.turquoise500 : AppColors.bw700;
    final isGroup = spaceEmoji != null && spaceColorHex != null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isGroup)
              SpaceAvatar(
                emoji: spaceEmoji!,
                colorHex: spaceColorHex!,
                ringColor: ringColor,
              )
            else
              ChatAvatar(imageUrl: avatarUrl, ringColor: ringColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style:
                              AppTextStyles.mdBold.copyWith(color: titleColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timestamp,
                        style:
                            AppTextStyles.xsSemiBold.copyWith(color: timeColor),
                      ),
                    ],
                  ),
                  if (preview.isNotEmpty)
                    Text(
                      preview,
                      style: AppTextStyles.xsSemiBold
                          .copyWith(color: previewColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.bw500,
            ),
          ],
        ),
      ),
    );
  }
}
