import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/space/data/space.dart';
import 'package:meep/features/space/data/space_member.dart';
import 'package:meep/shared/widgets/app_avatar.dart';
import 'package:meep/shared/widgets/app_confirm_dialog.dart';

/// Confirm dialog cho member thường rời khỏi Space.
///
/// Returns true nếu user confirmed. Caller chịu trách nhiệm gọi
/// `SpaceController.leaveSpace(spaceId)` sau khi nhận true.
Future<bool> showLeaveSpaceDialog(
  BuildContext context, {
  required String spaceName,
}) async {
  return showAppConfirmDialog(
    context,
    title: 'Rời khỏi $spaceName?',
    body: 'Bạn sẽ không còn xem được ảnh và tin nhắn trong Space này. '
        'Có thể được mời lại sau.',
    cancelLabel: 'Huỷ',
    confirmLabel: 'Rời khỏi',
  );
}

/// Dialog dành cho creator rời Space — phải chọn member mới làm creator
/// trước. Returns uid của member được chọn, hoặc null nếu cancel.
///
/// Caller chịu trách nhiệm gọi `transferOwnership(spaceId, newCreatorUid)`
/// rồi `leaveSpace(spaceId)` theo thứ tự (transfer phải success trước).
Future<String?> showCreatorLeaveDialog(
  BuildContext context, {
  required Space space,
  required List<SpaceMember> members,
  required Map<String, String> displayNames,
  required Map<String, String?> avatarUrls,
}) {
  // Filter out creator (caller) — không được chuyển cho chính mình.
  final candidates =
      members.where((m) => m.uid != space.creatorId).toList(growable: false);

  return showDialog<String?>(
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
              'Chuyển quyền quản trị',
              style: AppTextStyles.mdSemiBold.copyWith(color: AppColors.bw100),
            ),
            const SizedBox(height: 10),
            Text(
              'Chọn người quản trị mới trước khi rời ${space.name}. '
              'Người được chọn sẽ có quyền xoá Space và xoá thành viên.',
              style: AppTextStyles.smRegular.copyWith(color: AppColors.bw400),
            ),
            const SizedBox(height: 16),
            if (candidates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Không còn thành viên khác để chuyển quyền. '
                  'Hãy xoá Space thay vì rời.',
                  style:
                      AppTextStyles.smRegular.copyWith(color: AppColors.bw300),
                ),
              )
            else
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
                    return _MemberPickerTile(
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
}

class _MemberPickerTile extends StatelessWidget {
  const _MemberPickerTile({
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
