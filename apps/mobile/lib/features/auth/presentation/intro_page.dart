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
          // ── Beam: spotlight teal từ upper-center-right ────────────────
          const _Beam(),
          // ── Content ───────────────────────────────────────────────────
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;
                return SizedBox(
                  width: double.infinity,
                  height: h,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // top gap: logo tại y=414 / 917 ≈ 45.1%
                      SizedBox(height: h * 0.451),
                      // ── Logo ────────────────────────────────────────
                      Container(
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
                      // logo→Meep: 511-504 = 7px
                      const SizedBox(height: 7),
                      // ── App name ────────────────────────────────────
                      Text(
                        'Meep',
                        style: AppTextStyles.xl2Bold.copyWith(
                          color: Colors.white,
                          height: 42 / 32,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      // Meep→tagline: 565-553 = 12px
                      const SizedBox(height: 12),
                      // ── Tagline ─────────────────────────────────────
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Bắt trọn từng khoảnh khắc,\n'
                          'lưu giữ ký ức cùng những người thân yêu',
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
                      // tagline→btn1: 674-613 = 61px
                      const SizedBox(height: 61),
                      // ── Button 1: glass pill ─────────────────────────
                      const _GlassButton(
                        label: 'Tạo tài khoản mới',
                        route: '/signup/email',
                        width: 249,
                      ),
                      // btn1→btn2: 744-730 = 14px
                      const SizedBox(height: 14),
                      // ── Button 2: transparent ─────────────────────────
                      const _TransparentButton(
                        label: 'Đăng nhập',
                        route: '/login/email',
                        width: 198,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Beam ────────────────────────────────────────────────────────────────────

class _Beam extends StatelessWidget {
  const _Beam();

  @override
  Widget build(BuildContext context) {
    // Figma beam visible area: x=[87,412] (right 79%), y=[0,541] (top 59%).
    // Peak glow ≈ x=65%, y=18% of screen → Alignment(0.30, -0.64).
    // Màu peak = medium teal, không white. Radius nhỏ để tránh lấp kín màn hình.
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.30, -0.64),
            radius: 0.82,
            colors: [
              const Color(0xFF4CCBCB),
              const Color(0xFF22A0A4).withValues(alpha: 0.65),
              const Color(0xFF0D6366).withValues(alpha: 0.30),
              AppColors.bw900.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.30, 0.58, 0.90],
          ),
        ),
      ),
    );
  }
}

// ── Glass button (Button 1) ─────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.label,
    required this.route,
    required this.width,
  });

  final String label;
  final String route;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () => context.push(route),
        child: Container(
          width: width,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFA8C4C8).withValues(alpha: 0.80),
                const Color(0xFF6A9298).withValues(alpha: 0.65),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFFCCE8EA).withValues(alpha: 0.6),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1ABFC5).withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.mdBold.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Transparent button (Button 2) ───────────────────────────────────────────

class _TransparentButton extends StatelessWidget {
  const _TransparentButton({
    required this.label,
    required this.route,
    required this.width,
  });

  final String label;
  final String route;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () => context.push(route),
        child: SizedBox(
          width: width,
          height: 56,
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.mdBold.copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
