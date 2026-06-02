import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/space/application/space_controller.dart';
import 'package:meep/features/space/data/space.dart';
import 'package:meep/features/space/presentation/widgets/delete_space_dialog.dart';
import 'package:meep/features/space/presentation/widgets/kick_member_dialog.dart';
import 'package:meep/features/space/presentation/widgets/leave_space_dialog.dart';
import 'package:meep/shared/widgets/app_bottom_sheet.dart';

/// Bottom sheet quản lý Space — hiện theo role:
/// - Member thường: chỉ "Rời khỏi Space"
/// - Creator: "Rời khỏi Space" (qua transfer) + "Xoá thành viên" + "Xoá Space"
///
/// Mở qua "..." icon trên topbar khi user đang xem `HomeScreen(spaceId)`
/// (Feed per Space).
class SpaceManagementSheet extends ConsumerWidget {
  const SpaceManagementSheet({super.key, required this.spaceId});

  final String spaceId;

  /// Helper mở sheet — gọi từ "..." icon.
  static Future<void> show(BuildContext context, String spaceId) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SpaceManagementSheet(spaceId: spaceId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceAsync = ref.watch(spaceByIdProvider(spaceId));
    final currentUid = ref.watch(currentUidProvider).valueOrNull;

    return AppBottomSheet(
      child: spaceAsync.when(
        loading: () => const _LoadingBody(),
        error: (_, __) => const _ErrorBody(),
        data: (space) {
          if (space == null) {
            return const _DeletedBody();
          }
          if (currentUid == null) {
            return const _NotSignedInBody();
          }
          final isCreator = space.creatorId == currentUid;
          return _Body(
            space: space,
            currentUid: currentUid,
            isCreator: isCreator,
          );
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.space,
    required this.currentUid,
    required this.isCreator,
  });

  final Space space;
  final String currentUid;
  final bool isCreator;

  Future<void> _handleLeave(BuildContext context, WidgetRef ref) async {
    // Member thường: confirm + leaveSpace.
    if (!isCreator) {
      final confirmed = await showLeaveSpaceDialog(
        context,
        spaceName: space.name,
      );
      if (!confirmed || !context.mounted) return;
      await ref
          .read(spaceControllerProvider(currentUid).notifier)
          .leaveSpace(space.spaceId);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      _showStateError(context, ref);
      return;
    }

    // Creator: chọn member mới làm creator trước → transfer → leave.
    final members = ref.read(spaceMembersProvider(space.spaceId)).valueOrNull;
    if (members == null) return;
    final picked = await showCreatorLeaveDialog(
      context,
      space: space,
      members: members,
      displayNames: const {}, // TODO(SP/T10b/ThienPDM): inject userRepository lookup khi wire end-to-end
      avatarUrls: const {},
    );
    if (picked == null || !context.mounted) return;

    final notifier = ref.read(spaceControllerProvider(currentUid).notifier);
    await notifier.transferOwnership(space.spaceId, picked);
    final transferError =
        ref.read(spaceControllerProvider(currentUid)).errorMessage;
    if (transferError != null) {
      if (!context.mounted) return;
      _showStateError(context, ref);
      return;
    }
    await notifier.leaveSpace(space.spaceId);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    _showStateError(context, ref);
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDeleteSpaceDialog(
      context,
      spaceName: space.name,
    );
    if (!confirmed || !context.mounted) return;
    await ref
        .read(spaceControllerProvider(currentUid).notifier)
        .deleteSpace(space.spaceId);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    // Navigate về Home — Space đã soft-deleted, KHÔNG quay lại HomeScreen
    // (spaceId) cũ vì watchMySpaces sẽ filter out.
    context.go('/home');
    _showStateError(context, ref);
  }

  Future<void> _handleKick(BuildContext context, WidgetRef ref) async {
    final members = ref.read(spaceMembersProvider(space.spaceId)).valueOrNull;
    if (members == null) return;
    final picked = await showKickMemberDialog(
      context,
      space: space,
      members: members,
      displayNames: const {}, // TODO(SP/T10b/ThienPDM): inject userRepository lookup khi wire end-to-end
      avatarUrls: const {},
    );
    if (picked == null || !context.mounted) return;
    await ref
        .read(spaceControllerProvider(currentUid).notifier)
        .kickMember(space.spaceId, picked);
    if (!context.mounted) return;
    _showStateError(context, ref);
  }

  /// Show errorMessage từ SpaceController nếu mutation thất bại.
  /// Caller gọi sau mỗi mutation — KHÔNG block flow nếu success.
  void _showStateError(BuildContext context, WidgetRef ref) {
    final err = ref.read(spaceControllerProvider(currentUid)).errorMessage;
    if (err == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quản lý ${space.name}',
            style: AppTextStyles.baseBold.copyWith(color: AppColors.bw100),
          ),
          const SizedBox(height: 16),
          if (isCreator) ...[
            _ActionRow(
              icon: Icons.person_remove_outlined,
              label: 'Xoá thành viên',
              onTap: () => _handleKick(context, ref),
            ),
            const _Divider(),
          ],
          _ActionRow(
            icon: Icons.logout,
            label: 'Rời khỏi Space',
            destructive: true,
            onTap: () => _handleLeave(context, ref),
          ),
          if (isCreator) ...[
            const _Divider(),
            _ActionRow(
              icon: Icons.delete_outline,
              label: 'Xoá Space',
              destructive: true,
              onTap: () => _handleDelete(context, ref),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error700 : AppColors.bw100;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.mdSemiBold.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(color: AppColors.bw700, height: 1);
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.turquoise500),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Không tải được Space. Thử lại sau.',
        style: TextStyle(color: AppColors.bw300),
      ),
    );
  }
}

class _DeletedBody extends StatelessWidget {
  const _DeletedBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Space đã bị xoá hoặc bạn không còn quyền truy cập.',
        style: TextStyle(color: AppColors.bw300),
      ),
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
