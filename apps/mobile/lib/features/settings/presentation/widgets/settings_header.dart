import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:meep/core/config/app_config.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/shared/widgets/app_avatar.dart';

/// Header của SettingsSheet: avatar + username + link profile (copy được).
/// Link dùng [AppConfig.shareBaseUrl] để hiển thị và sao chép cùng một giá trị.
class SettingsHeader extends StatelessWidget {
  const SettingsHeader({
    super.key,
    required this.username,
    this.avatarUrl,
  });

  final String username;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final profileLink = '${AppConfig.shareBaseUrl}/$username';
    return Column(
      children: [
        AppAvatar(
          imageUrl: avatarUrl,
          size: 82,
          fallbackText: username.isNotEmpty ? username[0].toUpperCase() : null,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          username,
          style: AppTextStyles.lgBold.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              profileLink,
              style: AppTextStyles.mdBold.copyWith(color: AppColors.bw400),
            ),
            const SizedBox(width: AppSpacing.xs),
            Semantics(
              button: true,
              label: 'Sao chép liên kết',
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: profileLink));
                  // TODO(T3/NganTNK): show toast "Đã sao chép liên kết"
                },
                child: const Icon(Icons.link, size: 20, color: AppColors.bw400),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
