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
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.screenHorizontal,
          right: AppSpacing.screenHorizontal,
          top: AppSpacing.lg,
          bottom: AppSpacing.xl + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Thêm vào màn hình chờ?',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Thêm và giữ Widget hoặc ấn Thêm để thêm vào màn hình chờ',
              style: AppTextStyles.smMedium.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildWidgetPreview(),
            const SizedBox(height: AppSpacing.xl),
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
            const SizedBox(height: AppSpacing.md),
            _buildButton(
              label: 'Huỷ',
              bg: AppColors.bw700,
              textColor: Colors.white,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
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
        width: 220,
        height: 220,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bw700,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 115,
              height: 115,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: AppColors.bw800,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildOverlappingAvatars(),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '15 người bạn',
                    style: AppTextStyles.xsRegular.copyWith(
                      color: AppColors.bw200,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Meep Widget\n2 x 2',
              style: AppTextStyles.mdBold.copyWith(
                color: AppColors.turquoise600,
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
      barrierColor: const Color(0x73000000),
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
