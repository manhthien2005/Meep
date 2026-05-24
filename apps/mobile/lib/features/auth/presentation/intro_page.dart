import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bw900,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 27),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 5),
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/icons/ic_logo.svg',
                    width: 56,
                    height: 49,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Meep',
                style: AppTextStyles.xl2Bold.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Bắt trọn từng khoảnh khắc,\n'
                'lưu giữ ký ức cùng những người thân yêu',
                style: AppTextStyles.mdSemiBold.copyWith(
                  color: AppColors.bw300,
                  height: 24 / 16,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              _IntroButton(
                label: 'Tạo tài khoản mới',
                fillColor: AppColors.bw700,
                textColor: AppColors.bw200,
                onTap: () => context.push('/signup/email'),
              ),
              const SizedBox(height: 16),
              _IntroButton(
                label: 'Đăng nhập',
                fillColor: Colors.transparent,
                textColor: Colors.white,
                onTap: () => context.push('/login/email'),
              ),
              const SizedBox(height: 33),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroButton extends StatelessWidget {
  const _IntroButton({
    required this.label,
    required this.fillColor,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color fillColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.mdBold.copyWith(color: textColor),
          ),
        ),
      ),
    );
  }
}
