part of 'diary_canvas_screen.dart';

/// Dot-grid background painter — FigJam-style canvas.
///
/// Dots nhỏ, đều, spacing chuẩn → sắc nét ở mọi kích thước (vector, không
/// blur như PNG export). Repaint chỉ khi size đổi.
class _DotGridPainter extends CustomPainter {
  static const double _spacing = 22;
  static const double _radius = 1.1;
  static const Color _dotColor = AppColors.bw300;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _dotColor;
    for (double y = _spacing; y < size.height; y += _spacing) {
      for (double x = _spacing; x < size.width; x += _spacing) {
        canvas.drawCircle(Offset(x, y), _radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => false;
}
