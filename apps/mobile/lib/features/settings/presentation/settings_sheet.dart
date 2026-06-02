import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/settings/application/settings_controller.dart';
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
import 'package:meep/features/space/application/space_controller.dart';
import 'package:meep/shared/widgets/app_bottom_sheet.dart';
import 'package:meep/features/space/data/space.dart';
import 'package:meep/features/space/presentation/space_create_sheet.dart';
import 'package:meep/features/space/presentation/space_edit_sheet.dart';

/// Bottom sheet cài đặt — trigger từ avatar topbar homepage (Figma 572:4183).
class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUidProvider).valueOrNull;
    // Watch select để chỉ rebuild khi `spaces` thay đổi (không phải mỗi
    // state.copyWith do mutation khác trong controller).
    final spaces = uid == null
        ? const <Space>[]
        : ref.watch(
            spaceControllerProvider(uid).select((s) => s.spaces),
          );
    final isLoadingSpaces = uid != null &&
        ref.watch(
          spaceControllerProvider(uid).select((s) => s.isLoading),
        );

    return AppBottomSheet(
      heightFactor: 0.95,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xl),
            const SettingsHeader(),
            const SizedBox(height: AppSpacing.xl),
            const SettingsQuickActions(),
            const SizedBox(height: AppSpacing.xl),
            SpaceQuickRow(
              spaces: spaces,
              isLoading: isLoadingSpaces,
              onCreateSpace: () => _openCreateSheet(context),
              // Permission filter: chỉ creator được edit. Non-creator tap
              // card → snackbar info, không mở SpaceEditSheet. CF + rules
              // là final boundary, đây là UI hint layer 1.
              onEditSpace: (space) {
                if (uid == null) return;
                if (space.creatorId != uid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chỉ creator có quyền chỉnh sửa Space'),
                    ),
                  );
                  return;
                }
                _openEditSheet(context, space.spaceId);
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
                await ref.read(settingsControllerProvider.notifier).logout();
              },
            ),
            SettingsNavRow(
              icon: Icons.delete_outline,
              label: 'Xoá tài khoản',
              isDestructive: true,
              onTap: () async {
                final confirmed = await DeleteAccountDialog.show(context);
                if (confirmed != true) return;
                if (!context.mounted) return;
                // Pop sheet ngay → CF cascade chạy background (1-2 phút).
                // Auth listener detect uid null sau CF deleteUser → router
                // auto navigate /intro. UX: user không bị stuck nhìn sheet
                // trong khi CF chạy.
                Navigator.of(context).pop();
                unawaited(
                  ref.read(settingsControllerProvider.notifier).deleteAccount(),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Mở SpaceCreateSheet sau khi pop SettingsSheet — capture rootContext
  /// trước pop vì sheet context unmount sau pop, không show được modal
  /// mới với context cũ. Pattern PR #214.
  void _openCreateSheet(BuildContext context) {
    final rootContext = Navigator.of(context, rootNavigator: true).context;
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
  }

  /// Mở SpaceEditSheet sau khi pop SettingsSheet — cùng pattern rootContext
  /// như openCreate. Sheet build re-check creator (defense layer 2).
  void _openEditSheet(BuildContext context, String spaceId) {
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!rootContext.mounted) return;
      showModalBottomSheet<void>(
        context: rootContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SpaceEditSheet(spaceId: spaceId),
      );
    });
  }

  Widget _divider() =>
      Container(height: 1, color: Colors.white.withValues(alpha: 0.5));

  Widget _sectionLabel(String title) => Text(
        title,
        style: AppTextStyles.baseBold.copyWith(color: AppColors.bw300),
      );
}
