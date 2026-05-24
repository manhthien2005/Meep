import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';

// TODO(T8/HanDHG): implement IntroPage per Figma — Trang giới thiệu
class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bw900,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/icons/ic_logo.svg', width: 56, height: 49),
            const SizedBox(height: 16),
            Text(
              'Meep',
              style:
                  AppTextStyles.xl3Bold.copyWith(color: AppColors.turquoise300),
            ),
          ],
        ),
      ),
    );
  }
}
