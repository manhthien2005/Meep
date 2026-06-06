import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/core/theme/hex_color.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/settings/presentation/settings_sheet.dart';

/// Ring thickness around avatars.
const double _kRingWidth = 2;

/// Gap between the ring and the avatar image.
const double _kRingGap = 2;

/// First-letter fallback từ displayName cho avatar. Empty/null → null (giữ
/// solid gray circle như behavior cũ). Uppercase để Material consistent.
String? avatarFallbackFromName(String? name) {
  if (name == null) return null;
  final trimmed = name.trim();
  if (trimmed.isEmpty) return null;
  return trimmed.characters.first.toUpperCase();
}

/// Circular avatar for user profile pictures.
///
/// [ringColor] draws an optional ring with a small gap to the photo.
/// Pass null (default) for a plain avatar with no ring.
///
/// [fallbackText] shows when [imageUrl] is null/empty — typically the user's
/// first initial. If null, shows a solid gray circle.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.size = 50,
    this.ringColor,
    this.fallbackText,
  });

  final String? imageUrl;
  final double size;
  final Color? ringColor;
  final String? fallbackText;

  @override
  Widget build(BuildContext context) {
    final inset = ringColor != null ? (_kRingWidth + _kRingGap) : 0.0;
    final inner = size - inset * 2;
    // CachedNetworkImage thay NetworkImage trong DecorationImage: avatar được
    // cache trên disk → mở lại bất cứ screen nào (inbox, chat, members sheet,
    // ...) hiện instant thay vì flash + reload.
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final avatar = ClipOval(
      child: Container(
        width: inner,
        height: inner,
        color: AppColors.bw700,
        child: hasImage
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                width: inner,
                height: inner,
                fit: BoxFit.cover,
                // Placeholder = empty container (giữ màu bw700 nền) — KHÔNG
                // spinner để tránh flicker spinner ngắn ngủi khi cache hit.
                placeholder: (_, __) => const SizedBox.shrink(),
                errorWidget: (_, __, ___) => fallbackText != null
                    ? Center(
                        child: Text(
                          fallbackText!,
                          style: AppTextStyles.mdBold.copyWith(
                            color: AppColors.bw100,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              )
            : fallbackText != null
                ? Center(
                    child: Text(
                      fallbackText!,
                      style: AppTextStyles.mdBold.copyWith(
                        color: AppColors.bw100,
                      ),
                    ),
                  )
                : null,
      ),
    );

    if (ringColor == null) return avatar;

    // Ring (outer) → dark gap → avatar: two nested circles create the gap.
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: ringColor),
      padding: const EdgeInsets.all(_kRingWidth),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bw900,
        ),
        padding: const EdgeInsets.all(_kRingGap),
        child: avatar,
      ),
    );
  }
}

/// Avatar showing a Space's emoji on its themed color (group conversations).
/// [ringColor] behaves like [AppAvatar.ringColor].
class AppSpaceAvatar extends StatelessWidget {
  const AppSpaceAvatar({
    super.key,
    required this.emoji,
    required this.colorHex,
    this.size = 50,
    this.ringColor,
  });

  final String emoji;
  final String colorHex;
  final double size;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final inset = ringColor != null ? (_kRingWidth + _kRingGap) : 0.0;
    final inner = size - inset * 2;
    final disc = Container(
      width: inner,
      height: inner,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hexToColor(colorHex),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: AppTextStyles.mdBold),
    );

    if (ringColor == null) return disc;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: ringColor),
      padding: const EdgeInsets.all(_kRingWidth),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bw900,
        ),
        padding: const EdgeInsets.all(_kRingGap),
        child: disc,
      ),
    );
  }
}

/// Shared top-bar avatar dùng chung cho HomeFeed, Chat (Inbox), Diary, Streak.
/// Tự watch [currentUserProfileProvider] để lấy avatar + displayName, hiển thị
/// [AppAvatar] size 40, tap mở [SettingsSheet]. Đảm bảo đồng bộ avatar giữa
/// các trang và cùng route đến Settings.
class AppTopAvatar extends ConsumerWidget {
  const AppTopAvatar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    return Semantics(
      button: true,
      label: 'Cài đặt',
      child: GestureDetector(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const SettingsSheet(),
        ),
        child: AppAvatar(
          imageUrl: profile?.avatarUrl,
          size: 40,
          fallbackText: avatarFallbackFromName(profile?.displayName),
        ),
      ),
    );
  }
}
