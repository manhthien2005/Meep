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
          const _Beam(),
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
                      SizedBox(height: h * 0.451),
                      // ── Logo ──────────────────────────────────────────
                      // Gradient từ Figma SVG: #B7FFFF→#9EFFFF→#5397A5
                      // Direction upper-right → lower-left, cornerRadius 20
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment(0.81, -1.0),
                            end: Alignment(-0.37, 1.0),
                            colors: [
                              Color(0xFFB7FFFF),
                              Color(0xFF9EFFFF),
                              Color(0xFF5397A5),
                            ],
                            stops: [0.10, 0.2115, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          'assets/icons/ic_logo.svg',
                          width: 56,
                          height: 49,
                        ),
                      ),
                      const SizedBox(height: 7),
                      // ── App name ──────────────────────────────────────
                      Text(
                        'Meep',
                        style: AppTextStyles.xl2Bold.copyWith(
                          color: Colors.white,
                          height: 42 / 32,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // ── Tagline ───────────────────────────────────────
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
                      const SizedBox(height: 61),
                      // ── Button 1 ──────────────────────────────────────
                      const _GlassButton(
                        label: 'Tạo tài khoản mới',
                        route: '/signup/email',
                        width: 249,
                      ),
                      const SizedBox(height: 14),
                      // ── Button 2 ──────────────────────────────────────
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

// ── Beam ─────────────────────────────────────────────────────────────────────

class _Beam extends StatelessWidget {
  const _Beam();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: Opacity(
        opacity: 0.65,
        child: CustomPaint(painter: _BeamPainter()),
      ),
    );
  }
}

class _BeamPainter extends CustomPainter {
  const _BeamPainter();

  // Rect 3: #85E9FF solid → #85E9FF @20% opacity, blur 25, group opacity 0.5
  Shader _gradientPath1(Size size) {
    return const LinearGradient(
      begin: Alignment(1.16, -0.90),
      end: Alignment(-0.001, 0.41),
      colors: [Color(0xFF85E9FF), Color(0x3385E9FF)], // @20%
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  // Rect 4: #85E9FF solid → #85E9FF @0% opacity, blur 37.5, group opacity 1.0
  Shader _gradientPath2(Size size) {
    return const LinearGradient(
      begin: Alignment(1.16, -0.90),
      end: Alignment(-0.001, 0.41),
      colors: [Color(0xFF85E9FF), Color(0x0085E9FF)], // @0% transparent
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sx = w / 412;

    // ── Rect 4 (nền rộng, blur σ=37.5) — vẽ trước làm background layer ──────
    final sy4 = h / 841;
    final path2 = Path()
      ..moveTo(400.807 * sx, -85.043 * sy4)
      ..lineTo(513.076 * sx, -44.3794 * sy4)
      ..lineTo(574.441 * sx, 765.157 * sy4)
      ..lineTo(-164.711 * sx, 497.437 * sy4)
      ..close();
    canvas.drawPath(
      path2,
      Paint()
        ..shader = _gradientPath2(size)
        ..blendMode = BlendMode.plus
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 37.5),
    );

    // ── Rect 3 (highlight tập trung, blur σ=25) — vẽ sau = trên cùng, sáng hơn ─
    final sy3 = h / 759;
    final path1 = Path()
      ..moveTo(400.817 * sx, -85.0393 * sy3)
      ..lineTo(513.086 * sx, -44.3756 * sy3)
      ..lineTo(417.722 * sx, 708.393 * sy3)
      ..lineTo(-7.99173 * sx, 554.2 * sy3)
      ..close();
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0x80FFFFFF), // group opacity 0.5
    );
    canvas.drawPath(
      path1,
      Paint()
        ..shader = _gradientPath1(size)
        ..blendMode = BlendMode.plus
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Glass button ──────────────────────────────────────────────────────────────
// Background = ic_btn_glass.svg (fill @20% + stroke gradient, no complex filter)
// SVG extracted trực tiếp từ Figma node 556:2139, coords adjusted to 249×56 space.

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
        child: SizedBox(
          width: width,
          height: 56,
          child: Stack(
            children: [
              // Background: SVG chính xác từ Figma
              SvgPicture.asset(
                'assets/icons/ic_btn_glass.svg',
                width: width,
                height: 56,
                fit: BoxFit.fill,
              ),
              // Text overlay
              Center(
                child: Text(
                  label,
                  style: AppTextStyles.mdBold.copyWith(
                    color: const Color(0xFFEEF2F3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Transparent button ────────────────────────────────────────────────────────

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
