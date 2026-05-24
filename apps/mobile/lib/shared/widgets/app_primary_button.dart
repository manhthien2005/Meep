import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    // TODO(A/HanDHG): implement per Figma — 338×57, radius=30, Nunito Bold 16
    return SizedBox(
      width: 338,
      height: 57,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? AppColors.turquoise300 : AppColors.bw700,
          foregroundColor: enabled ? AppColors.turquoise800 : AppColors.bw400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.turquoise800,
                  strokeWidth: 2,
                ),
              )
            : Text(label),
      ),
    );
  }
}
