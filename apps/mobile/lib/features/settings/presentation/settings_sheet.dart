import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/settings/presentation/blocked_accounts_page.dart';
import 'package:meep/features/settings/presentation/delete_account_dialog.dart';
import 'package:meep/features/settings/presentation/logout_confirm_dialog.dart';
import 'package:meep/features/settings/presentation/privacy_data_page.dart';
import 'package:meep/features/settings/presentation/privacy_policy_page.dart';
import 'package:meep/features/settings/presentation/share_profile_sheet.dart';
import 'package:meep/features/friend/presentation/friend_sheet.dart';
import 'package:meep/features/settings/presentation/terms_page.dart';
import 'package:meep/features/settings/presentation/widget_confirm_sheet.dart';

const _sheetBg = AppColors.bw800; // #252627 - Design System
const _cardBg = AppColors.bw800; // #252627 - Design System
const _quickActionBg = AppColors.bw700; // #394041 - Design System
const _dividerColor = Color(0x80FFFFFF); // white 50% opacity - Figma

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _sheetBg,
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
                  _buildHeader(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildQuickActions(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSpaceSection(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildDivider(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionHeader('Setup'),
                  const SizedBox(height: AppSpacing.md),
                  _buildNavRow(
                    icon: Icons.widgets_outlined,
                    label: 'Thêm tiện ích',
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const WidgetConfirmSheet(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildDivider(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionHeader('Riêng tư & Bảo mật'),
                  const SizedBox(height: AppSpacing.md),
                  _buildNavRow(
                    icon: Icons.block_outlined,
                    label: 'Tài khoản đã chặn',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BlockedAccountsPage(),
                      ),
                    ),
                  ),
                  _buildNavRow(
                    icon: Icons.lock_outline,
                    label: 'Quyền riêng tư và dữ liệu',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PrivacyDataPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildDivider(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionHeader('Giới thiệu'),
                  const SizedBox(height: AppSpacing.md),
                  _buildNavRow(
                    icon: Icons.description_outlined,
                    label: 'Điều khoản dịch vụ',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TermsPage(),
                      ),
                    ),
                  ),
                  _buildNavRow(
                    icon: Icons.shield_outlined,
                    label: 'Chính sách quyền riêng tư',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PrivacyPolicyPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildDivider(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionHeader('Tài khoản'),
                  const SizedBox(height: AppSpacing.md),
                  _buildNavRow(
                    icon: Icons.logout,
                    label: 'Đăng xuất',
                    onTap: () async {
                      final confirmed = await LogoutConfirmDialog.show(context);
                      if (confirmed == true && context.mounted) {
                        Navigator.of(context).pop();
                        // TODO(T3/NganTNK): SettingsController.logout()
                      }
                    },
                  ),
                  _buildNavRow(
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
            color: const Color(0xFF48484A),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: _cardBg,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF48484A), width: 1.5),
          ),
          child: const Center(
            child: Icon(Icons.person, color: Colors.white54, size: 38),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'username',
          style: AppTextStyles.lgBold.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'meep.cam/username',
              style:
                  AppTextStyles.mdBold.copyWith(color: const Color(0xFFBABABA)),
            ),
            const SizedBox(width: AppSpacing.xs),
            GestureDetector(
              onTap: () {
                Clipboard.setData(
                  const ClipboardData(text: 'meep://profile/username'),
                );
                // TODO(T3/NganTNK): show toast "Đã sao chép liên kết"
              },
              child: const Icon(Icons.link, size: 20, color: Color(0xFFBABABA)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _quickActionBtn(
            icon: Icons.group_outlined,
            label: '15 người bạn',
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => const FriendSheet(),
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _quickActionBtn(
            icon: Icons.ios_share_outlined,
            label: 'Chia sẻ',
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => const ShareProfileSheet(username: 'username'),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _quickActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: _quickActionBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style:
                  AppTextStyles.mdBold.copyWith(color: const Color(0xFFDDDDDD)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpaceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.favorite_border, size: 20, color: Colors.white),
            SizedBox(width: AppSpacing.xs),
            Text(
              'Space',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 115,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _spaceCard('Gia đình'),
              const SizedBox(width: AppSpacing.md),
              _spaceCard('Hội đồng quản trị'),
              const SizedBox(width: AppSpacing.md),
              _createSpaceCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _spaceCard(String name) {
    return Container(
      width: 115,
      height: 115,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bw700,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.bw600.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: AppColors.bw600,
              borderRadius: BorderRadius.circular(21.5),
              border: Border.all(
                color: AppColors.bw500,
                width: 2,
              ),
            ),
          ),
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          GestureDetector(
            onTap: () {
              // TODO(T2/NganTNK): navigate to Space edit
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.bw600,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Sửa',
                style: AppTextStyles.xsSemiBold.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _createSpaceCard() {
    return GestureDetector(
      onTap: () {
        // TODO(T2/NganTNK): navigate to Space creation
      },
      child: Container(
        width: 115,
        height: 115,
        decoration: BoxDecoration(
          color: AppColors.bw700,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: AppColors.bw600.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: AppColors.turquoise500.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.turquoise500,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.turquoise500,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tạo',
              style: AppTextStyles.xsSemiBold.copyWith(
                color: AppColors.turquoise500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Container(height: 1, color: _dividerColor);

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFFDDDDDD),
      ),
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.error800 : Colors.white;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.mdRegular.copyWith(color: color),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDestructive ? AppColors.error800 : AppColors.bw500,
            ),
          ],
        ),
      ),
    );
  }
}
