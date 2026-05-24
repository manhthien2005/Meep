import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/shared/widgets/app_back_button.dart';
import 'package:meep/shared/widgets/app_google_button.dart';
import 'package:meep/shared/widgets/app_primary_button.dart';
import 'package:meep/shared/widgets/app_text_input.dart';

/// DEV ONLY — xóa route /dev/widgets trước khi merge vào develop.
class WidgetCatalogPage extends StatelessWidget {
  const WidgetCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bw900,
      appBar: AppBar(
        backgroundColor: AppColors.bw800,
        title: Text(
          'Widget Catalog',
          style: AppTextStyles.mdBold.copyWith(color: AppColors.bw100),
        ),
        leading: const AppBackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.xl,
        ),
        children: [
          _section('AppPrimaryButton', [
            const AppPrimaryButton(label: 'Tiếp tục', onPressed: _noop),
            const SizedBox(height: 12),
            const AppPrimaryButton(
              label: 'Tiếp tục',
              showTrailingIcon: false,
              onPressed: _noop,
            ),
            const SizedBox(height: 12),
            const AppPrimaryButton(label: 'Disabled'),
            const SizedBox(height: 12),
            const AppPrimaryButton(
              label: 'Loading',
              isLoading: true,
              onPressed: _noop,
            ),
          ]),
          _section('AppBackButton', [
            const Row(children: [AppBackButton()]),
          ]),
          _section('AppGoogleButton', [
            const AppGoogleButton(onPressed: _noop),
          ]),
          _section('AppTextInput — Normal', [
            const AppTextInput(inputType: AppTextInputType.email),
            const SizedBox(height: 12),
            const AppTextInput(inputType: AppTextInputType.username),
          ]),
          _section('AppTextInput — Active', [
            const AppTextInput(
              inputType: AppTextInputType.email,
              status: AppTextInputStatus.active,
            ),
          ]),
          _section('AppTextInput — Error', [
            const AppTextInput(
              inputType: AppTextInputType.email,
              status: AppTextInputStatus.error,
              errorText: 'Địa chỉ email không hợp lệ!',
            ),
          ]),
          _section('AppTextInput — Success', [
            const AppTextInput(
              inputType: AppTextInputType.username,
              status: AppTextInputStatus.success,
            ),
          ]),
          _section('AppTextInput — Password', [
            const AppTextInput(inputType: AppTextInputType.password),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.smSemiBold.copyWith(color: AppColors.bw500),
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }

  static void _noop() {}
}
