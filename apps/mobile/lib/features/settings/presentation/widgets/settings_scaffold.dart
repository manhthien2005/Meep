import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/shared/widgets/app_back_button.dart';

/// Scaffold chuẩn cho các sub-page của Settings (Tài khoản bị chặn, Điều khoản,
/// Chính sách, Quyền riêng tư): nền [AppColors.bw900], back button + title
/// match pattern auth pages — `Padding(EdgeInsets.fromLTRB(27, 49, 27, 0))` cho
/// back button, title centered ngay dưới. KHÔNG dùng `AppBar` để giữ consistent
/// positioning với auth flow.
class SettingsScaffold extends StatelessWidget {
  const SettingsScaffold({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bw900,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(27, 49, 27, 0),
              child: AppBackButton(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                title,
                style: AppTextStyles.lgBold.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
