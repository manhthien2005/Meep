import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_radii.dart';
import 'package:meep/core/theme/app_text_styles.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.showTrailingIcon = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool showTrailingIcon;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: _enabled ? onPressed : null,
        style: TextButton.styleFrom(
          backgroundColor: _enabled ? AppColors.turquoise300 : AppColors.bw700,
          foregroundColor: _enabled ? AppColors.turquoise800 : AppColors.bw400,
          disabledBackgroundColor: AppColors.bw700,
          disabledForegroundColor: AppColors.bw400,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        ),
        child: isLoading ? _loadingIndicator() : _content(),
      ),
    );
  }

  Widget _content() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.mdBold.copyWith(
            color: _enabled ? AppColors.turquoise800 : AppColors.bw400,
          ),
        ),
        if (showTrailingIcon) ...[
          const SizedBox(width: 8),
          SvgPicture.asset(
            'assets/icons/ic_move_right.svg',
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              _enabled ? AppColors.turquoise800 : AppColors.bw400,
              BlendMode.srcIn,
            ),
          ),
        ],
      ],
    );
  }

  Widget _loadingIndicator() {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        color: AppColors.turquoise800,
        strokeWidth: 2,
      ),
    );
  }
}
