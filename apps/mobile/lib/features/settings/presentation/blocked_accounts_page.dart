import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';

class BlockedAccountsPage extends StatelessWidget {
  const BlockedAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO(T4/NganTNK): replace mock list with SettingsController.watchBlockedUsers()
    const mockUsers = ['Lauren'];

    return Scaffold(
      backgroundColor: AppColors.bw900,
      appBar: AppBar(
        backgroundColor: AppColors.bw900,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tài khoản bị chặn',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: mockUsers.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.xl,
              ),
              itemCount: mockUsers.length,
              itemBuilder: (_, i) => _BlockedUserItem(
                username: mockUsers[i],
                onUnblock: () {
                  // TODO(T4/NganTNK): SettingsController.unblockUser(uid)
                },
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
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.bw600,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.bw300, width: 4),
            ),
            child: const Center(
              child: Icon(Icons.person, color: Colors.white54, size: 24),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              username,
              style: AppTextStyles.mdBold.copyWith(color: AppColors.bw100),
            ),
          ),
          GestureDetector(
            onTap: onUnblock,
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
                  color: const Color(0xFFDDDDDD),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
