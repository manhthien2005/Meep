import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/chat/application/chat_providers.dart';
import 'package:meep/shared/widgets/app_avatar.dart';
import 'package:meep/shared/widgets/app_bottom_sheet.dart';

/// Bottom sheet listing the members of a Space. Figma `564:8865`.
/// The current user appears first, labelled "Bạn".
class SpaceMembersSheet extends ConsumerWidget {
  const SpaceMembersSheet({super.key, required this.spaceId});

  final String spaceId;

  /// Shows the members sheet for [spaceId].
  static Future<void> show(BuildContext context, String spaceId) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SpaceMembersSheet(spaceId: spaceId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(chatSpaceMembersProvider(spaceId));
    final members = membersAsync.valueOrNull ?? const [];
    final myUid = ref.watch(currentChatUidProvider);

    // Tall sheet (~75% screen) per Figma `564:8865`, not a half-height sheet.
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: AppBottomSheet(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Thành viên Space',
                    style:
                        AppTextStyles.baseBold.copyWith(color: AppColors.bw100),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Mọi người (${members.length})',
                  style:
                      AppTextStyles.xsSemiBold.copyWith(color: AppColors.bw500),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final profileAsync =
                          ref.watch(chatUserProfileProvider(member.uid));
                      final profile = profileAsync.valueOrNull;
                      final isMe = member.uid == myUid;
                      return _MemberRow(
                        name: isMe
                            ? 'Bạn'
                            : (profile?.displayName ?? 'Thành viên'),
                        avatarUrl: profile?.avatarUrl,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          AppAvatar(imageUrl: avatarUrl, size: 44),
          const SizedBox(width: 14),
          Text(
            name,
            style: AppTextStyles.mdBold.copyWith(color: AppColors.bw100),
          ),
        ],
      ),
    );
  }
}
