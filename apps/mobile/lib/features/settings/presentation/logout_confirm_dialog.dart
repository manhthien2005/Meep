import 'package:flutter/material.dart';
import 'package:meep/shared/widgets/app_confirm_dialog.dart';

class LogoutConfirmDialog {
  static Future<bool> show(BuildContext context) => showAppConfirmDialog(
        context,
        title: 'Bạn có chắc bạn muốn đăng xuất?',
        body: 'Bạn sẽ cần đăng nhập lại để tiếp tục sử dụng Meep.',
        cancelLabel: 'Huỷ',
        confirmLabel: 'Đăng xuất',
      );
}
