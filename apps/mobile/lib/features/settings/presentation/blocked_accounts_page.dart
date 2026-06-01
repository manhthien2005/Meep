import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/settings/presentation/_mock_data.dart';
import 'package:meep/features/settings/presentation/unblock_confirm_dialog.dart';
import 'package:meep/features/settings/presentation/widgets/settings_scaffold.dart';
import 'package:meep/shared/widgets/app_avatar.dart';

class BlockedAccountsPage extends StatefulWidget {
  const BlockedAccountsPage({super.key});

  @override
  State<BlockedAccountsPage> createState() => _BlockedAccountsPageState();
}

class _BlockedAccountsPageState extends State<BlockedAccountsPage> {
  // TODO(T4/NganTNK): replace mock list with SettingsController.watchBlockedUsers()
  late final List<Map<String, String>> _blockedUsers =
      List<Map<String, String>>.from(SettingsMockData.mockBlockedUsers);

  Future<void> _onUnblock(int index) async {
    // Bỏ chặn cần xác nhận trước (Figma 1441:3341 — state 3).
    final confirmed = await UnblockConfirmDialog.show(context);
    if (!confirmed || !mounted) return;
    // TODO(T4/NganTNK): SettingsController.unblockUser(uid)
    setState(() => _blockedUsers.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Tài khoản bị chặn',
      body: _blockedUsers.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.xl,
              ),
              itemCount: _blockedUsers.length,
              itemBuilder: (_, i) => _BlockedUserItem(
                username: _blockedUsers[i]['username']!,
                onUnblock: () => _onUnblock(i),
              ),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Không có tài khoản bị chặn nào',
            style: AppTextStyles.lgBold.copyWith(color: AppColors.bw100),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Bạn có thể chặn một ai đó từ trang Bạn bè',
            style: AppTextStyles.mdRegular.copyWith(color: AppColors.bw500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BlockedUserItem extends StatelessWidget {
  const _BlockedUserItem({
    required this.username,
    required this.onUnblock,
  });

  final String username;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        children: [
          AppAvatar(
            size: 50,
            fallbackText:
                username.isNotEmpty ? username[0].toUpperCase() : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              username,
              style: AppTextStyles.mdBold.copyWith(color: AppColors.bw100),
            ),
          ),
          Semantics(
            button: true,
            label: 'Bỏ chặn',
            child: GestureDetector(
              onTap: onUnblock,
              behavior: HitTestBehavior.opaque,
              // minHeight 48: đảm bảo vùng chạm >= 48px (a11y) trong khi pill
              // vẫn giữ kích thước thị giác ban đầu.
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Center(
                  widthFactor: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bw700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Bỏ chặn',
                      style: AppTextStyles.smSemiBold.copyWith(
                        color: AppColors.bw300,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
