import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/settings/presentation/widgets/settings_scaffold.dart';

class PrivacyDataPage extends StatefulWidget {
  const PrivacyDataPage({super.key});

  @override
  State<PrivacyDataPage> createState() => _PrivacyDataPageState();
}

class _PrivacyDataPageState extends State<PrivacyDataPage> {
  bool _isSearchable = true;

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Quyền riêng tư và dữ liệu',
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToggleCard(),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Khi tắt, người dùng Meep khác không thể tìm bạn bằng tên người dùng. Chỉ những người nhận được liên kết mời trực tiếp mới có thể thêm bạn.',
              style: AppTextStyles.smRegular.copyWith(
                color: AppColors.bw500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: AppColors.bw700,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Mọi người có thể thêm tôi bằng tên người dùng',
              style: AppTextStyles.smSemiBold.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: _isSearchable,
              onChanged: (v) {
                setState(() => _isSearchable = v);
                // TODO(SE/Profile/ThienPDM): wire isSearchable persist
                // Firestore. Block bởi UserRepository thiếu method
                // updatePrivacyFields. Rule firestore.rules đã cho phép
                // update field này (không trong blocklist). State hiện tại:
                // toggle UI work nhưng KHÔNG persist Firestore.
              },
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.turquoise500,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: AppColors.bw300,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
