import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/core/config/app_config.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/shared/widgets/app_avatar.dart';

/// Header của SettingsSheet: avatar + username + link profile (copy được).
/// Đọc trực tiếp [currentUserProfileProvider] để hiển thị real user data.
/// Profile null (signed-out / loading) → render empty fallback strings, không
/// hiển thị spinner (match home_screen pattern).
class SettingsHeader extends ConsumerWidget {
  const SettingsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final username = profile?.username ?? '';
    final avatarUrl = profile?.avatarUrl;
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
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: profileLink));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã sao chép liên kết'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                // TODO(A/Router/ThienPDM): deeplink meep://profile/{username}
                // chưa có route handler. Copy link OK nhưng tap link không mở
                // app. Cần add handler trong app_router resolve
                // username → uid → /profile.
                child: const Icon(Icons.link, size: 20, color: AppColors.bw400),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
