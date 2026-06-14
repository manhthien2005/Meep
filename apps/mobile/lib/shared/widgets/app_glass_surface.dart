import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';

/// Glassmorphism surface: backdrop blur + gradient fill mờ + gradient border.
///
/// Tách riêng vì dùng cho cả 2 variant của taskbar và có thể tái dùng cho các
/// panel/overlay kính khác. `flutter_svg` KHÔNG render `backdrop-filter` của
/// SVG, nên hiệu ứng kính bắt buộc dựng bằng Flutter — đó là lý do widget này
/// tồn tại thay vì nhúng SVG khối.
class AppGlassSurface extends StatelessWidget {
  const AppGlassSurface({
    super.key,
    required this.child,
    this.height,
    this.borderRadius,
    this.blurSigma = 8,
    this.disableBlur = false,
  });

  final Widget child;
  final double? height;

  /// Mặc định = pill shape (`height / 2`) nếu có [height], ngược lại 29.
  final double? borderRadius;

  /// Cường độ blur nền. Tinh chỉnh khi xem trên device.
  final double blurSigma;

  /// Embedded legacy path: không blur, chỉ màu đơn opacity thấp.
  final bool disableBlur;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? (height != null ? height! / 2 : 29);
    final content = CustomPaint(
      foregroundPainter:
          disableBlur ? null : _GlassBorderPainter(radius: radius),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: disableBlur
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.bw800.withValues(alpha: 0.06),
                    AppColors.bw800.withValues(alpha: 0.015),
                  ],
                ),
          color: disableBlur ? AppColors.bw800.withValues(alpha: 0.08) : null,
          boxShadow: disableBlur
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x26000000),
                    offset: Offset(0, 3),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: child,
      ),
    );

    if (disableBlur) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: content,
      ),
    );
  }
}

/// Vẽ border gradient (trắng trong suốt ở trên → [AppColors.glassBorder] ở dưới).
/// `BoxDecoration.border` chỉ làm được màu đơn nên phải dùng CustomPaint.
class _GlassBorderPainter extends CustomPainter {
  const _GlassBorderPainter({required this.radius});

  final double radius;

  /// Figma ghi 0.2px — quá mảnh, gần vô hình trên device; dùng 0.5px.
  static const double _strokeWidth = 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final border = RRect.fromRectAndRadius(
      rect.deflate(_strokeWidth / 2),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.glassBorder.withValues(alpha: 0.45),
          const Color(0x00FFFFFF),
        ],
      ).createShader(rect);
    canvas.drawRRect(border, paint);
  }

  @override
  bool shouldRepaint(covariant _GlassBorderPainter oldDelegate) =>
      oldDelegate.radius != radius;
}
