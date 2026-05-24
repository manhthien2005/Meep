import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_radii.dart';
import 'package:meep/core/theme/app_text_styles.dart';

class AppGoogleButton extends StatelessWidget {
  const AppGoogleButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 19, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            side: const BorderSide(color: AppColors.bw200),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/ic_google.svg',
              width: 18,
              height: 18,
            ),
            const SizedBox(width: 10),
            Text(
              'Tiếp tục với Google',
              style: AppTextStyles.mdBold.copyWith(color: AppColors.bw900),
            ),
          ],
        ),
      ),
    );
  }
}
