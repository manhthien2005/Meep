import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/core/theme/hex_color.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/friend/application/friend_controller.dart';
import 'package:meep/features/space/application/space_controller.dart';
import 'package:meep/features/space/data/space.dart';
import 'package:meep/shared/widgets/app_avatar.dart';

/// Feed filter dropdown — "Mọi người" / "Bạn" / per-friend / per-Space.
/// Mirrors Figma "ListFriend" (269:1667): rounded card, dark rows với dividers.
/// Spaces section render dưới friends list khi user thuộc Space nào.
///
/// Dùng từ cả HomeScreen (Feed PageView) và GridViewScreen (Task 2+3 —
/// mỗi screen tự handle side-effect như jumpToPage hoặc scroll).
class FeedFilterDropdown extends ConsumerWidget {
  const FeedFilterDropdown({
    super.key,
    required this.currentUid,
    required this.selectedLabel,
    required this.onFilterSelected,
    required this.onSpaceFilterSelected,
  });

  final String currentUid;
  final String selectedLabel;

  /// Called với (authorUid, label). `authorUid == null` = "Mọi người".
  /// Khi `authorUid == currentUid` = "Bạn".
  final void Function(String? authorUid, String label) onFilterSelected;

  /// Called khi user chọn 1 Space — caller mutate filter provider + side-effect.
  final void Function(Space space) onSpaceFilterSelected;

  void _select(BuildContext context, String? authorUid, String label) {
    Navigator.of(context).pop();
    onFilterSelected(authorUid, label);
  }

  void _selectSpace(BuildContext context, Space space) {
    Navigator.of(context).pop();
    onSpaceFilterSelected(space);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendControllerProvider(currentUid)).friends;
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final spaces = ref.watch(
      spaceControllerProvider(currentUid).select((s) => s.spaces),
    );

    final screenH = MediaQuery.sizeOf(context).height;
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 265,
            height: screenH * 0.4,
            decoration: BoxDecoration(
              color: AppColors.bw600,
              borderRadius: BorderRadius.circular(25),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FilterRow(
                    label: 'Mọi người',
                    leading: _iconCircle('assets/icons/ic_users_round.svg'),
                    onTap: () => _select(context, null, 'Mọi người'),
                  ),
                  _FilterRow(
                    label: 'Bạn',
                    leading: AppAvatar(
                      imageUrl: profile?.avatarUrl,
                      size: 25,
                      fallbackText: (profile?.displayName.isNotEmpty ?? false)
                          ? profile!.displayName[0].toUpperCase()
                          : null,
                    ),
                    onTap: () => _select(context, currentUid, 'Bạn'),
                  ),
                  ...friends.map(
                    (friend) => _FilterRow(
                      label: friend.displayName,
                      leading: AppAvatar(
                        imageUrl: friend.avatarUrl,
                        size: 25,
                        fallbackText: friend.displayName.isNotEmpty
                            ? friend.displayName[0].toUpperCase()
                            : null,
                      ),
                      onTap: () => _select(
                        context,
                        friend.uid,
                        friend.displayName,
                      ),
                    ),
                  ),
                  if (spaces.isNotEmpty) ...[
                    const _SpacesSectionHeader(),
                    ...spaces.map(
                      (space) => _FilterRow(
                        label: space.name,
                        leading: _SpaceLeadingCircle(space: space),
                        onTap: () => _selectSpace(context, space),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconCircle(String iconPath) {
    return Container(
      width: 25,
      height: 25,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bw600,
      ),
      padding: const EdgeInsets.all(6),
      child: SvgPicture.asset(
        iconPath,
        colorFilter: const ColorFilter.mode(AppColors.bw100, BlendMode.srcIn),
      ),
    );
  }
}

class _SpacesSectionHeader extends StatelessWidget {
  const _SpacesSectionHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.bw700,
        border: Border(bottom: BorderSide(color: AppColors.bw800)),
      ),
      child: Text(
        'SPACES',
        style: AppTextStyles.xsSemiBold.copyWith(
          color: AppColors.bw400,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SpaceLeadingCircle extends StatelessWidget {
  const _SpaceLeadingCircle({required this.space});

  final Space space;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: hexToColor(space.colorHex),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        space.iconEmoji,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.label,
    required this.leading,
    required this.onTap,
  });

  final String label;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.bw700,
          border: Border(
            bottom: BorderSide(color: AppColors.bw800),
          ),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.mdBold.copyWith(color: AppColors.bw100),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.bw500,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
