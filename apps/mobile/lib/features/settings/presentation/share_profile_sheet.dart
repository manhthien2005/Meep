import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/shared/widgets/app_bottom_sheet.dart';

/// Bottom sheet hiện khi user tap "Chia sẻ" trong SettingsSheet.
/// Cho phép chia sẻ profile link qua Messenger hoặc sao chép liên kết.
class ShareProfileSheet extends StatelessWidget {
  const ShareProfileSheet({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    final profileLink = 'meep.cam/$username';
    return AppBottomSheet(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.screenHorizontal,
          right: AppSpacing.screenHorizontal,
          top: AppSpacing.xl,
          bottom: AppSpacing.xl + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(profileLink),
            const SizedBox(height: AppSpacing.lg),
            _buildOption(
              icon: Icons.chat_bubble_outline,
              label: 'Gửi qua Messenger',
              onTap: () {
                Navigator.of(context).pop();
                // TODO(T3/NganTNK): share qua Messenger SDK / share_plus
              },
            ),
            _buildOption(
              icon: Icons.link,
              label: 'Sao chép liên kết',
              onTap: () {
                Clipboard.setData(ClipboardData(text: profileLink));
                Navigator.of(context).pop();
                // TODO(T3/NganTNK): show toast "Đã sao chép liên kết"
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String profileLink) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SvgPicture.asset('assets/icons/ic_logo_full.svg'),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Kết bạn với tôi trên Meep nhé!',
                style: AppTextStyles.mdBold.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                profileLink,
                style: AppTextStyles.smRegular.copyWith(
                  color: const Color(0xFFBABABA),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: AppTextStyles.mdRegular.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
