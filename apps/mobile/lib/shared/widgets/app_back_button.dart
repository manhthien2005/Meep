import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_radii.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Quay lại',
      button: true,
      child: SizedBox(
        width: 40,
        height: 40,
        child: TextButton(
          onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
          style: TextButton.styleFrom(
            backgroundColor: AppColors.bw600,
            padding: EdgeInsets.zero,
            minimumSize: const Size(40, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.circle),
            ),
          ),
          child: const Icon(
            Icons.chevron_left,
            color: AppColors.bw400,
            size: 24,
          ),
        ),
      ),
    );
  }
}
