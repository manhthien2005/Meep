import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/settings/application/blocked_user_view.dart';
import 'package:meep/features/settings/application/blocked_users_provider.dart';
import 'package:meep/features/settings/application/settings_controller.dart';
import 'package:meep/features/settings/presentation/unblock_confirm_dialog.dart';
import 'package:meep/features/settings/presentation/widgets/settings_scaffold.dart';
import 'package:meep/shared/widgets/app_avatar.dart';

class BlockedAccountsPage extends ConsumerWidget {
  const BlockedAccountsPage({super.key});

  Future<void> _onUnblock(
    BuildContext context,
    WidgetRef ref,
    BlockedUserView user,
  ) async {
    // Bỏ chặn cần xác nhận trước (Figma 1441:3341 — state 3).
    final confirmed = await UnblockConfirmDialog.show(context);
    if (!confirmed) return;
    await ref.read(settingsControllerProvider.notifier).unblockUser(user.uid);
    // Stream provider auto re-emits sau unblock → list refresh tự động.
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(blockedUsersProvider);
    return SettingsScaffold(
      title: 'Tài khoản bị chặn',
      body: blocked.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.turquoise500),
        ),
        error: (_, __) => const _ErrorState(),
        data: (users) => users.isEmpty
            ? const _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.xl,
                ),
                itemCount: users.length,
                itemBuilder: (_, i) => _BlockedUserItem(
                  user: users[i],
                  onUnblock: () => _onUnblock(context, ref, users[i]),
                ),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        child: Text(
          'Không thể tải danh sách. Kiểm tra kết nối và thử lại.',
          style: AppTextStyles.mdRegular.copyWith(color: AppColors.bw400),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _BlockedUserItem extends StatelessWidget {
  const _BlockedUserItem({
    required this.user,
    required this.onUnblock,
  });

  final BlockedUserView user;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        children: [
          AppAvatar(
            size: 50,
            imageUrl: user.avatarUrl,
            fallbackText: user.username.isNotEmpty
                ? user.username[0].toUpperCase()
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              user.username,
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
