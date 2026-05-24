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
      body: Stack(
        children: [
          // ── Beam background (teal glow ở nửa trên) ───────────────────
          const _Beam(),
          // ── Content ───────────────────────────────────────────────────
          SafeArea(
            child: _Content(),
          ),
        ],
      ),
    );
  }
}

// Gradient overlay tái tạo hiệu ứng "Beam" của Figma
class _Beam extends StatelessWidget {
  const _Beam();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        alignment: Alignment.topCenter,
        child: Container(
          width: 900,
          height: 750,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.15, -0.2),
              radius: 0.75,
              colors: [
                const Color(0xFFB8F5F8).withValues(alpha: 0.85),
                const Color(0xFF5FE8EC).withValues(alpha: 0.55),
                const Color(0xFF00C9E3).withValues(alpha: 0.25),
                AppColors.bw900.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.35, 0.6, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Proportions from Figma (frame 412×917):
    // Logo top: 414, Meep: 511, Tagline: 565, Btn1: 674, Btn2: 744
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        return SizedBox(
          height: h,
          child: Column(
            children: [
              // gap trước logo: 414/917 ≈ 45.1%
              SizedBox(height: h * 0.451),
              // ── Logo ──────────────────────────────────────────────
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
              // gap logo → Meep: (511-504) ≈ 7px
              const SizedBox(height: 7),
              // ── App name ──────────────────────────────────────────
              Text(
                'Meep',
                style: AppTextStyles.xl2Bold.copyWith(
                  color: Colors.white,
                  height: 42 / 32,
                ),
                textAlign: TextAlign.center,
              ),
              // gap Meep → tagline: (565-553) ≈ 12px
              const SizedBox(height: 12),
              // ── Tagline ───────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Bắt trọn từng khoảnh khắc,\nlưu giữ ký ức cùng những người thân yêu',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.bw300,
                    height: 24 / 18,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // gap tagline → btn1: (674-613) ≈ 61px
              const SizedBox(height: 61),
              // ── Tạo tài khoản mới ─────────────────────────────────
              SizedBox(
                width: 249,
                height: 56,
                child: _IntroButton(
                  label: 'Tạo tài khoản mới',
                  fillColor: AppColors.bw700,
                  textColor: AppColors.bw200,
                  onTap: () => context.push('/signup/email'),
                ),
              ),
              // gap btn1 → btn2: (744-730) ≈ 14px
              const SizedBox(height: 14),
              // ── Đăng nhập ─────────────────────────────────────────
              SizedBox(
                width: 198,
                height: 56,
                child: _IntroButton(
                  label: 'Đăng nhập',
                  fillColor: Colors.transparent,
                  textColor: Colors.white,
                  onTap: () => context.push('/login/email'),
                ),
              ),
            ],
          ),
        );
      },
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
