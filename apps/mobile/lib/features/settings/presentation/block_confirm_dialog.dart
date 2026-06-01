import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/shared/widgets/app_bottom_sheet.dart';

class BlockConfirmDialog extends StatefulWidget {
  const BlockConfirmDialog({super.key, required this.targetName});

  final String targetName;

  static Future<bool?> show(BuildContext context, String targetName) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BlockConfirmDialog(targetName: targetName),
      );

  @override
  State<BlockConfirmDialog> createState() => _BlockConfirmDialogState();
}

class _BlockConfirmDialogState extends State<BlockConfirmDialog> {
  bool _blocked = false;

  @override
  Widget build(BuildContext context) {
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
              child: GestureDetector(
                onTap: _blocked
                    ? null
                    : () {
                        setState(() => _blocked = true);
                        // TODO(T4/NganTNK): SettingsController.blockUser(uid)
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _blocked
                        ? AppColors.turquoise500.withValues(alpha: 0.7)
                        : AppColors.turquoise500,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _blocked ? 'Đã chặn!' : 'Chặn',
                      style: AppTextStyles.mdSemiBold.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(_blocked),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  'Bỏ qua',
                  style: AppTextStyles.mdRegular.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
