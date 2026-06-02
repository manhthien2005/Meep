import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/settings/application/settings_controller.dart';
import 'package:meep/features/settings/presentation/_mock_data.dart';
import 'package:meep/features/settings/presentation/blocked_accounts_page.dart';
import 'package:meep/features/settings/presentation/delete_account_dialog.dart';
import 'package:meep/features/settings/presentation/logout_confirm_dialog.dart';
import 'package:meep/features/settings/presentation/privacy_data_page.dart';
import 'package:meep/features/settings/presentation/privacy_policy_page.dart';
import 'package:meep/features/settings/presentation/terms_page.dart';
import 'package:meep/features/settings/presentation/widget_confirm_sheet.dart';
import 'package:meep/features/settings/presentation/widgets/settings_header.dart';
import 'package:meep/features/settings/presentation/widgets/settings_nav_row.dart';
import 'package:meep/features/settings/presentation/widgets/settings_quick_actions.dart';
import 'package:meep/features/settings/presentation/widgets/space_quick_row.dart';
import 'package:meep/features/space/presentation/space_create_sheet.dart';

/// Bottom sheet cài đặt — trigger từ avatar topbar homepage (Figma 572:4183).
class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bw800,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          _dragHandle(),
          const SizedBox(height: AppSpacing.xl),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SettingsHeader(username: SettingsMockData.username),
                  const SizedBox(height: AppSpacing.xl),
                  const SettingsQuickActions(
                    friendCount: SettingsMockData.friendCount,
                    username: SettingsMockData.username,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SpaceQuickRow(
                    spaceNames: SettingsMockData.mockSpaces,
                    // T2/NganTNK gate: thêm hook `onCreateSpace` để Space module
                    // wire. Em (ThienPDM) wire tạm vào `SpaceCreateSheet` để
                    // unblock manual test Space — capture rootContext trước pop
                    // SettingsSheet vì sheet context unmount sau pop, không show
                    // được modal mới với context cũ.
                    onCreateSpace: () {
                      final rootContext =
                          Navigator.of(context, rootNavigator: true).context;
                      Navigator.of(context).pop();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!rootContext.mounted) return;
                        showModalBottomSheet<void>(
                          context: rootContext,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const FractionallySizedBox(
                            heightFactor: 0.9,
                            child: SpaceCreateSheet(),
                          ),
                        );
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _divider(),
                  const SizedBox(height: AppSpacing.xl),
                  _sectionLabel('Setup'),
                  const SizedBox(height: AppSpacing.md),
                  SettingsNavRow(
                    icon: Icons.widgets_outlined,
                    label: 'Thêm tiện ích',
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: false,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const WidgetConfirmSheet(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _divider(),
                  const SizedBox(height: AppSpacing.xl),
                  _sectionLabel('Riêng tư & Bảo mật'),
                  const SizedBox(height: AppSpacing.md),
                  SettingsNavRow(
                    icon: Icons.block_outlined,
                    label: 'Tài khoản đã chặn',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BlockedAccountsPage(),
                      ),
                    ),
                  ),
                  SettingsNavRow(
                    icon: Icons.lock_outline,
                    label: 'Quyền riêng tư và dữ liệu',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PrivacyDataPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _divider(),
                  const SizedBox(height: AppSpacing.xl),
                  _sectionLabel('Giới thiệu'),
                  const SizedBox(height: AppSpacing.md),
                  SettingsNavRow(
                    icon: Icons.description_outlined,
                    label: 'Điều khoản dịch vụ',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TermsPage(),
                      ),
                    ),
                  ),
                  SettingsNavRow(
                    icon: Icons.shield_outlined,
                    label: 'Chính sách quyền riêng tư',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PrivacyPolicyPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _divider(),
                  const SizedBox(height: AppSpacing.xl),
                  _sectionLabel('Tài khoản'),
                  const SizedBox(height: AppSpacing.md),
                  SettingsNavRow(
                    icon: Icons.logout,
                    label: 'Đăng xuất',
                    onTap: () async {
                      final confirmed = await LogoutConfirmDialog.show(context);
                      if (confirmed != true) return;
                      if (context.mounted) Navigator.of(context).pop();
                      // Router auth listener tự redirect /intro khi uid → null.
                      await ref
                          .read(settingsControllerProvider.notifier)
                          .logout();
                    },
                  ),
                  SettingsNavRow(
                    icon: Icons.delete_outline,
                    label: 'Xoá tài khoản',
                    isDestructive: true,
                    onTap: () async {
                      final confirmed = await DeleteAccountDialog.show(context);
                      if (confirmed == true && context.mounted) {
                        Navigator.of(context).pop();
                        // TODO(T6/NganTNK): SettingsController.deleteAccount()
                      }
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dragHandle() => Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.bw600,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _divider() =>
      Container(height: 1, color: Colors.white.withValues(alpha: 0.5));

  Widget _sectionLabel(String title) => Text(
        title,
        style: AppTextStyles.baseBold.copyWith(color: AppColors.bw300),
      );
}
