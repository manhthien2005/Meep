import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/shared/widgets/app_back_button.dart';
import 'package:meep/shared/widgets/app_google_button.dart';
import 'package:meep/shared/widgets/app_primary_button.dart';
import 'package:meep/shared/widgets/app_taskbar.dart';
import 'package:meep/shared/widgets/app_text_input.dart';

/// DEV ONLY — xóa route /dev/widgets trước khi merge vào develop.
class WidgetCatalogPage extends StatefulWidget {
  const WidgetCatalogPage({super.key});

  @override
  State<WidgetCatalogPage> createState() => _WidgetCatalogPageState();
}

class _WidgetCatalogPageState extends State<WidgetCatalogPage> {
  TaskbarTab _activeTab = TaskbarTab.home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1F21),
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
          _section('AppTaskbar — Floating (nổi)', [
            Stack(
              alignment: Alignment.center,
              children: [
                // Placeholder để thấy blur xuyên qua
                Container(
                  height: 100,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.turquoise600,
                        AppColors.turquoise800,
                      ],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Center(
                    child: Text(
                      'Nội dung phía sau taskbar',
                      style: AppTextStyles.mdBold.copyWith(
                        color: AppColors.bw100,
                      ),
                    ),
                  ),
                ),
                AppTaskbar(
                  activeTab: _activeTab,
                  variant: TaskbarVariant.floating,
                  chatBadgeCount: 2,
                  onTabSelected: (tab) => setState(() => _activeTab = tab),
                ),
              ],
            ),
          ]),
          _section('AppTaskbar — Embedded (chìm)', [
            Stack(
              alignment: Alignment.center,
              children: [
                // Placeholder để thấy blur xuyên qua
                Container(
                  height: 100,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.error600,
                        AppColors.error800,
                      ],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Center(
                    child: Text(
                      'Nội dung phía sau taskbar',
                      style: AppTextStyles.mdBold.copyWith(
                        color: AppColors.bw100,
                      ),
                    ),
                  ),
                ),
                AppTaskbar(
                  activeTab: _activeTab,
                  variant: TaskbarVariant.embedded,
                  onTabSelected: (tab) => setState(() => _activeTab = tab),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Embedded — vẽ bằng Flutter (AppTaskbar)',
              style: AppTextStyles.xsSemiBold.copyWith(
                color: AppColors.bw600,
                fontFamily: 'monospace',
              ),
            ),
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
