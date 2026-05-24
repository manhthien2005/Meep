import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // TODO(A/HanDHG): implement per Figma — 40×40, radius=22.5, bg=#656C6D, chevron-left
    return SizedBox(
      width: 40,
      height: 40,
      child: ElevatedButton(
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bw600,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22.5),
          ),
        ),
        child: const Icon(
          Icons.chevron_left,
          color: AppColors.bw400,
          size: 24,
        ),
      ),
    );
  }
}
