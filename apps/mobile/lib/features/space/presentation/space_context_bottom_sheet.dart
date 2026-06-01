import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/space/application/space_controller.dart';
import 'package:meep/features/space/presentation/widgets/space_list_tile.dart';
import 'package:meep/shared/widgets/app_bottom_sheet.dart';

/// Camera context chooser — list Spaces của user + "Tất cả bạn bè".
///
/// Tap row → set [currentSpaceProvider] (null cho "All friends") + đóng sheet.
/// Mở qua long-press FriendsButton trên `HomeScreen._HomeTopBar`.
///
/// Sheet **không** nhận `spaceId` arg — là context chooser global, không
/// phải detail viewer. Watch `currentSpaceProvider` để biết tile nào đang
/// selected.
class SpaceContextBottomSheet extends ConsumerWidget {
  const SpaceContextBottomSheet({super.key});

  /// Helper mở sheet — gọi từ long-press FriendsButton.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x73000000),
      builder: (_) => const SpaceContextBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUidProvider).valueOrNull;
    final currentSpace = ref.watch(currentSpaceProvider);

    return AppBottomSheet(
      child: uid == null
          ? const _NotSignedInBody()
          : _Body(uid: uid, currentSpaceId: currentSpace?.spaceId),
    );
  }
}

class _NotSignedInBody extends StatelessWidget {
  const _NotSignedInBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Chưa đăng nhập',
        style: TextStyle(color: AppColors.bw300),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.uid, required this.currentSpaceId});

  final String uid;
  final String? currentSpaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(spaceControllerProvider(uid));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Đang gửi cho',
              style: TextStyle(
                color: AppColors.bw100,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ),
        // "Tất cả bạn bè" — luôn ở đầu danh sách.
        SpaceListTile(
          isSelected: currentSpaceId == null,
          onTap: () {
            ref.read(currentSpaceProvider.notifier).clear();
            Navigator.of(context).pop();
          },
        ),
        const Divider(
          color: AppColors.bw700,
          height: 1,
          indent: 16,
          endIndent: 16,
        ),
        if (state.spaces.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Bạn chưa tham gia Space nào',
              style: TextStyle(color: AppColors.bw400),
            ),
          )
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: state.spaces.length,
              itemBuilder: (_, i) {
                final space = state.spaces[i];
                return SpaceListTile(
                  space: space,
                  isSelected: currentSpaceId == space.spaceId,
                  onTap: () {
                    ref.read(currentSpaceProvider.notifier).select(space);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              state.errorMessage!,
              style:
                  AppTextStyles.smRegular.copyWith(color: AppColors.error500),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
