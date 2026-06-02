import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/shared/widgets/app_back_button.dart';

/// Scaffold chuẩn cho các sub-page của Settings (Tài khoản bị chặn, Điều khoản,
/// Chính sách, Quyền riêng tư): nền [AppColors.bw900] + AppBar trong suốt với
/// [AppBackButton] và tiêu đề canh giữa.
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
      appBar: AppBar(
        backgroundColor: AppColors.bw900,
        elevation: 0,
        leading: const AppBackButton(),
        title: Text(
          title,
          style: AppTextStyles.lgBold.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: body,
    );
  }
}
