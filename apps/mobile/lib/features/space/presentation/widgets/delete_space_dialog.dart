import 'package:flutter/material.dart';

import 'package:meep/shared/widgets/app_confirm_dialog.dart';

/// Confirm dialog cho creator xoá Space (soft delete).
///
/// Returns true nếu user confirmed. Caller chịu trách nhiệm gọi
/// `SpaceController.deleteSpace(spaceId)` sau khi nhận true.
///
/// Warning text nhấn mạnh action không reversible — CF `onSpaceDeleted`
/// sẽ cleanup space_members + đánh dấu conversation status='deleted'.
/// Posts giữ lại nhưng ẩn (isMember rule fail vì members đã bị xoá).
Future<bool> showDeleteSpaceDialog(
  BuildContext context, {
  required String spaceName,
}) async {
  return showAppConfirmDialog(
    context,
    title: 'Xoá $spaceName?',
    body: 'Tất cả thành viên sẽ bị xoá khỏi Space. Tin nhắn và ảnh '
        'sẽ ẩn vĩnh viễn. Hành động này không thể hoàn tác.',
    cancelLabel: 'Huỷ',
    confirmLabel: 'Xoá Space',
  );
}
