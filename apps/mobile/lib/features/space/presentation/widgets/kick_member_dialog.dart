import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/space/data/space.dart';
import 'package:meep/features/space/data/space_member.dart';
import 'package:meep/shared/widgets/app_avatar.dart';
import 'package:meep/shared/widgets/app_confirm_dialog.dart';

/// Picker + confirm cho creator xoá thành viên khỏi Space.
///
/// Flow: list members (trừ creator) → tap → confirm dialog → return uid
/// được kick (hoặc null nếu cancel). Caller gọi
/// `SpaceController.kickMember(spaceId, targetUid)` sau khi nhận uid.
///
/// 2-step intentional để giảm rủi ro tap nhầm vào row member.
Future<String?> showKickMemberDialog(
  BuildContext context, {
  required Space space,
  required List<SpaceMember> members,
  required Map<String, String> displayNames,
  required Map<String, String?> avatarUrls,
}) async {
  // Filter out creator — không thể kick chính creator (chỉ delete Space).
  final candidates =
      members.where((m) => m.uid != space.creatorId).toList(growable: false);

  if (candidates.isEmpty) return null;

  // Step 1: pick member.
  final pickedUid = await showDialog<String?>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: AppColors.bw800,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: AppColors.bw600.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 24, 25, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xoá thành viên',
              style: AppTextStyles.mdSemiBold.copyWith(color: AppColors.bw100),
            ),
            const SizedBox(height: 10),
            Text(
              'Chọn thành viên cần xoá khỏi ${space.name}. '
              'Họ sẽ không xem được tin nhắn và ảnh trong Space nữa.',
              style: AppTextStyles.smRegular.copyWith(color: AppColors.bw400),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: candidates.length,
                separatorBuilder: (_, __) => const Divider(
                  color: AppColors.bw700,
                  height: 1,
                ),
                itemBuilder: (_, i) {
                  final member = candidates[i];
                  return _KickPickerTile(
                    displayName:
                        displayNames[member.uid] ?? 'Thành viên ${i + 1}',
                    avatarUrl: avatarUrls[member.uid],
                    onTap: () => Navigator.pop(context, member.uid),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context, null),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    'Huỷ',
                    style: AppTextStyles.smSemiBold
                        .copyWith(color: AppColors.bw100),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  if (pickedUid == null) return null;

  // Step 2: confirm.
  final pickedName = displayNames[pickedUid] ?? 'thành viên';
  // ignore: use_build_context_synchronously
  // `showDialog` đã guard context lifecycle qua Navigator; caller chịu
  // trách nhiệm dispose nếu sheet đóng giữa chừng.
  if (!context.mounted) return null;
  final confirmed = await showAppConfirmDialog(
    context,
    title: 'Xoá $pickedName khỏi Space?',
    body: 'Họ sẽ không xem được tin nhắn và ảnh trong ${space.name} nữa. '
        'Có thể mời lại sau.',
    cancelLabel: 'Huỷ',
    confirmLabel: 'Xoá',
  );

  return confirmed ? pickedUid : null;
}

class _KickPickerTile extends StatelessWidget {
  const _KickPickerTile({
    required this.displayName,
    required this.avatarUrl,
    required this.onTap,
  });

  final String displayName;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            AppAvatar(imageUrl: avatarUrl, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayName,
                style:
                    AppTextStyles.smSemiBold.copyWith(color: AppColors.bw100),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.bw500,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
