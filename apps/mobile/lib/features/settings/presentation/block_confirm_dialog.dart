import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/settings/application/settings_controller.dart';
import 'package:meep/shared/widgets/app_bottom_sheet.dart';

/// Confirm dialog cho block user (Figma 605:1991 + state "Đã chặn!" 624:1906).
/// Trigger từ `PhotoActionSheet` ở feed module (KhoaLND) khi user tap "Chặn".
///
/// Flow:
/// - User tap "Chặn" → controller.blockUser(targetUid)
/// - Success → button đổi "Đã chặn!" (disabled, hơi mờ)
/// - Error → giữ button "Chặn" (errorMessage trong SettingsState, caller có
///   thể inspect nếu muốn show toast)
/// - User tap "Bỏ qua" → pop dialog với kết quả `_blocked` (bool)
class BlockConfirmDialog extends ConsumerStatefulWidget {
  const BlockConfirmDialog({
    super.key,
    required this.targetUid,
    required this.targetName,
  });

  final String targetUid;
  final String targetName;

  static Future<bool?> show(
    BuildContext context, {
    required String targetUid,
    required String targetName,
  }) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BlockConfirmDialog(
          targetUid: targetUid,
          targetName: targetName,
        ),
      );

  @override
  ConsumerState<BlockConfirmDialog> createState() => _BlockConfirmDialogState();
}

class _BlockConfirmDialogState extends ConsumerState<BlockConfirmDialog> {
  bool _blocked = false;
  bool _isBlocking = false;

  Future<void> _onBlockTap() async {
    setState(() => _isBlocking = true);
    await ref
        .read(settingsControllerProvider.notifier)
        .blockUser(widget.targetUid);
    if (!mounted) return;
    final errorMsg = ref.read(settingsControllerProvider).errorMessage;
    if (errorMsg != null) {
      // Error: cho phép retry, errorMessage đã set trong state cho caller inspect.
      setState(() => _isBlocking = false);
      return;
    }
    setState(() {
      _blocked = true;
      _isBlocking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isBusyOrDone = _blocked || _isBlocking;
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
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.error600.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.block,
                color: AppColors.error600,
                size: 30,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Chặn ${widget.targetName}?',
              style: AppTextStyles.lgBold.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Họ sẽ không thể nhắn tin cho bạn, xem các khoảnh khắc của bạn hoặc gửi lời mời kết bạn. Hai người vẫn có thể được thêm vào cùng một nhóm, nhưng sẽ không thể xem tin nhắn hoặc khoảnh khắc của nhau.',
              style: AppTextStyles.smRegular.copyWith(color: AppColors.bw400),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Họ sẽ không được thông báo rằng mình đã bị chặn',
              style: AppTextStyles.xsRegular.copyWith(color: AppColors.bw500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: Semantics(
                button: true,
                label: _blocked ? 'Đã chặn!' : 'Chặn',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: isBusyOrDone ? null : _onBlockTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isBusyOrDone
                          ? AppColors.turquoise500.withValues(alpha: 0.7)
                          : AppColors.turquoise500,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: _isBlocking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _blocked ? 'Đã chặn!' : 'Chặn',
                              style: AppTextStyles.mdSemiBold.copyWith(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              button: true,
              label: 'Bỏ qua',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(_blocked),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    'Bỏ qua',
                    style:
                        AppTextStyles.mdRegular.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
