import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/friend/presentation/friend_sheet.dart';
import 'package:meep/features/settings/presentation/share_profile_sheet.dart';

/// Hàng 2 nút nhanh trong SettingsSheet: [Bạn bè] mở FriendSheet,
/// [Chia sẻ] mở ShareProfileSheet.
class SettingsQuickActions extends StatelessWidget {
  const SettingsQuickActions({
    super.key,
    required this.friendCount,
    required this.username,
  });

  final int friendCount;
  final String username;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.group_outlined,
            label: '$friendCount người bạn',
            onTap: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (_) => const FriendSheet(),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.ios_share_outlined,
            label: 'Chia sẻ',
            onTap: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: false,
              builder: (_) => ShareProfileSheet(username: username),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.bw700,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.mdBold.copyWith(color: AppColors.bw300),
            ),
          ],
        ),
      ),
    );
  }
}
