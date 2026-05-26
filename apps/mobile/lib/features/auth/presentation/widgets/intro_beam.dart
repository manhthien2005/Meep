import 'package:flutter/material.dart';

/// Animated beam-of-light background dùng cho `IntroPage`.
///
/// Vẽ 2 layer gradient `#85E9FF` (blur 25 + blur 37.5) bằng `CustomPaint`.
/// [opacity] driver từ ngoài (vd `AnimationController` cho hiệu ứng breathing).
class IntroBeam extends StatelessWidget {
  const IntroBeam({super.key, this.opacity = 1.0});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: const CustomPaint(painter: _BeamPainter()),
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
      colors: [Color(0xFF85E9FF), Color(0x3385E9FF)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  // Rect 4: #85E9FF solid → #85E9FF @0% opacity, blur 37.5, group opacity 1.0
  Shader _gradientPath2(Size size) {
    return const LinearGradient(
      begin: Alignment(1.16, -0.90),
      end: Alignment(-0.001, 0.41),
      colors: [Color(0xFF85E9FF), Color(0x0085E9FF)],
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
      Paint()..color = const Color(0x80FFFFFF),
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
