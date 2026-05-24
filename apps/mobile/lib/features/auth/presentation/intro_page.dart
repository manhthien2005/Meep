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
                      // logo tại y=414/917 ≈ 45.1%
                      SizedBox(height: h * 0.451),
                      // ── Logo ──────────────────────────────────────────
                      // Frame 1461: NO fill (transparent) — beam shows through
                      // Inner Logo frame (56×49): white fill
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: Center(
                          child: Container(
                            width: 56,
                            height: 49,
                            color: Colors.white,
                            child: SvgPicture.asset(
                              'assets/icons/ic_logo.svg',
                              width: 56,
                              height: 49,
                            ),
                          ),
                        ),
                      ),
                      // logo→Meep: 7px
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
                      // Meep→tagline: 12px
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
                      // tagline→btn1: 61px
                      const SizedBox(height: 61),
                      // ── Button 1: glass pill ──────────────────────────
                      const _GlassButton(
                        label: 'Tạo tài khoản mới',
                        route: '/signup/email',
                        width: 249,
                      ),
                      // btn1→btn2: 14px
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

// ── Beam ─────────────────────────────────────────────────────────────────────
// SVG-extracted: color #85E9FF, mix-blend-mode plus-lighter,
// 2 diagonal paths with Gaussian blur 25px + 37.5px, viewBox 412×841.

class _Beam extends StatelessWidget {
  const _Beam();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      // opacity 0.65 → giảm sáng so với Figma reference screenshot
      child: Opacity(
        opacity: 0.65,
        child: CustomPaint(painter: _BeamPainter()),
      ),
    );
  }
}

class _BeamPainter extends CustomPainter {
  const _BeamPainter();

  Shader _gradient(Size size) {
    return const LinearGradient(
      begin: Alignment(1.16, -0.90),
      end: Alignment(-0.001, 0.41),
      colors: [Color(0xFF85E9FF), Color(0x3385E9FF)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sx = w / 412;
    final sy = h / 841;
    final shader = _gradient(size);

    // Path 2 — opacity 1.0, blur σ=37.5
    final path2 = Path()
      ..moveTo(400.807 * sx, -85.043 * sy)
      ..lineTo(513.076 * sx, -44.3794 * sy)
      ..lineTo(574.441 * sx, 765.157 * sy)
      ..lineTo(-164.711 * sx, 497.437 * sy)
      ..close();
    canvas.drawPath(
      path2,
      Paint()
        ..shader = shader
        ..blendMode = BlendMode.plus
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 37.5),
    );

    // Path 1 — opacity 0.5, blur σ=25
    final path1 = Path()
      ..moveTo(400.817 * sx, -85.0393 * sy)
      ..lineTo(513.086 * sx, -44.3756 * sy)
      ..lineTo(417.722 * sx, 708.393 * sy)
      ..lineTo(-7.99173 * sx, 554.2 * sy)
      ..close();
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0x80FFFFFF),
    );
    canvas.drawPath(
      path1,
      Paint()
        ..shader = shader
        ..blendMode = BlendMode.plus
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Glass button ──────────────────────────────────────────────────────────────
// btn_node.png: silver-gray gradient pill, subtle border, bottom shadow

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
                const Color(0xFFB8CCCE).withValues(alpha: 0.90),
                const Color(0xFF7A9599).withValues(alpha: 0.75),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFFD5E8EA).withValues(alpha: 0.8),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.mdBold.copyWith(color: Colors.white),
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
