import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/shared/widgets/app_bottom_sheet.dart';

class WidgetConfirmSheet extends StatelessWidget {
  const WidgetConfirmSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.screenHorizontal,
            right: AppSpacing.screenHorizontal,
            top: AppSpacing.md,
            bottom: AppSpacing.lg + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Thêm vào màn hình chờ?',
                style: AppTextStyles.baseBold.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Thêm và giữ Widget hoặc ấn Thêm để thêm vào màn hình chờ',
                style: AppTextStyles.smMedium.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildWidgetPreview(),
              const SizedBox(height: AppSpacing.md),
              _buildButton(
                label: 'Thêm',
                bg: AppColors.turquoise600,
                textColor: AppColors.turquoise900,
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO(T4/NganTNK): requestPinAppWidget() Android intent
                  _showSuccessToast(context);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildButton(
                label: 'Huỷ',
                bg: AppColors.bw700,
                textColor: Colors.white,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required Color bg,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.mdBold.copyWith(color: textColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWidgetPreview() {
    return Center(
      child: Container(
        width: 160,
        height: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bw700,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bw800,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildOverlappingAvatars(),
                  const SizedBox(height: 4),
                  Text(
                    '15 người bạn',
                    style: AppTextStyles.xsRegular.copyWith(
                      color: AppColors.bw200,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Meep Widget\n2 x 2',
              style: AppTextStyles.mdBold.copyWith(
                color: AppColors.turquoise600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlappingAvatars() {
    const double avatarSize = 32;
    const double overlap = 10;

    return SizedBox(
      width: avatarSize * 3 - overlap * 2,
      height: avatarSize,
      child: Stack(
        children: [
          Positioned(left: 0, child: _avatar(avatarSize)),
          Positioned(left: avatarSize - overlap, child: _avatar(avatarSize)),
          Positioned(
            left: (avatarSize - overlap) * 2,
            child: _avatar(avatarSize),
          ),
        ],
      ),
    );
  }

  Widget _avatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.bw600,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.bw800, width: 2),
      ),
    );
  }

  void _showSuccessToast(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.bw900.withValues(alpha: 0.45),
      builder: (dialogContext) {
        // Tự đóng sau 3 giây
        final navigator = Navigator.of(dialogContext);
        Future.delayed(const Duration(seconds: 3), () {
          if (navigator.canPop()) {
            navigator.pop();
          }
        });
        return Dialog(
          backgroundColor: AppColors.bw800,
          insetPadding: const EdgeInsets.symmetric(horizontal: 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 28,
                ),
                child: Text(
                  'Đã thêm tiện ích vào màn hình chờ thành công!',
                  style: AppTextStyles.mdBold.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              Positioned(
                top: 12,
                left: 13,
                child: GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: AppColors.bw500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
