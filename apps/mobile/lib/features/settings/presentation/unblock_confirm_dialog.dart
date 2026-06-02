import 'package:flutter/material.dart';
import 'package:meep/shared/widgets/app_confirm_dialog.dart';

/// Confirm dialog hiện trước khi bỏ chặn một tài khoản.
///
/// Figma: "Trang settings_TK bị chặn 3" (1441:3341) — Popup overlay trên
/// danh sách tài khoản bị chặn. Dùng lại [showAppConfirmDialog] (bw800 fill,
/// radius 30, nút "Xác nhận" màu error).
///
/// Trả `true` khi user xác nhận bỏ chặn, `false` khi huỷ hoặc dismiss.
class UnblockConfirmDialog {
  static Future<bool> show(BuildContext context) => showAppConfirmDialog(
        context,
        title: 'Bạn có chắc muốn bỏ chặn tài khoản này không?',
        body: 'Tài khoản này sẽ được gỡ khỏi danh sách chặn. Việc bỏ chặn sẽ '
            'không tự động khôi phục trạng thái bạn bè trước đây.',
        cancelLabel: 'Huỷ',
        confirmLabel: 'Xác nhận',
      );
}
