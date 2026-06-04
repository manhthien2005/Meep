import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Empty state cho StreakScreen (chưa post lần nào).
///
/// Match Figma `269:1985`:
/// - Subtitle: "Gửi khoảnh khắc đầu tiên của bạn tại Meep !"
///   (Nunito Bold 14, color `#ffffff7a`, center)
/// - Vector 3 (curved arrow): chỉ TỪ subtitle XUỐNG → lên Taskbar send icon
/// - Vector 4 (curved arrow): chỉ TỪ calendar XUỐNG → pill stats
/// - 2 vectors render via CustomPainter — dashed curve stroke `#ffffff7a`
///
/// Widget chỉ render text + arrows; calendar + pill là phần khác của
/// StreakScreen (vẫn render bình thường, overlay này nổi trên).
class EmptyStateOverlay extends StatelessWidget {
  const EmptyStateOverlay({super.key});

  static const _muted = Color(0x7AFFFFFF);
  static const _labelStyle = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 18 / 14,
    color: _muted,
  );

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Gửi khoảnh khắc đầu tiên của bạn tại Meep !',
              textAlign: TextAlign.center,
              style: _labelStyle,
            ),
            const SizedBox(height: 12),
            // Arrow lên: subtitle → Taskbar send icon (icon nhỏ ở dưới)
            // Render send icon + curved arrow chỉ về phía Taskbar.
            Center(
              child: SizedBox(
                width: 80,
                height: 85,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 0,
                      child: SvgPicture.asset(
                        'assets/icons/ic_send.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          _muted,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    CustomPaint(
                      size: const Size(40, 85),
                      painter: _CurvedArrowPainter(direction: _Direction.down),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Arrow XUỐNG (chỉ về pill stats ở dưới) — render riêng vì position
/// khác overlay topbar (Stack alignment trong [StreakScreen]).
class StreakArrowDown extends StatelessWidget {
  const StreakArrowDown({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: const Size(30, 65),
        painter: _CurvedArrowPainter(direction: _Direction.up),
      ),
    );
  }
}

enum _Direction { up, down }

class _CurvedArrowPainter extends CustomPainter {
  _CurvedArrowPainter({required this.direction});

  final _Direction direction;

  static const _stroke = Color(0x7AFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (direction == _Direction.down) {
      // Curve loop xuống dưới, kết thúc bằng arrow head
      // (mock dashed curve — vẽ đoạn cong cơ bản)
      path.moveTo(size.width / 2, 24);
      path.quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.35,
        size.width * 0.55,
        size.height * 0.55,
      );
      path.quadraticBezierTo(
        size.width * 0.15,
        size.height * 0.78,
        size.width * 0.5,
        size.height - 4,
      );
    } else {
      // Curve loop lên trên
      path.moveTo(size.width / 2, size.height - 4);
      path.quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.65,
        size.width * 0.55,
        size.height * 0.45,
      );
      path.quadraticBezierTo(
        size.width * 0.15,
        size.height * 0.22,
        size.width * 0.5,
        4,
      );
    }

    // Render dashed
    _drawDashed(canvas, path, paint, dashLength: 5, gapLength: 4);
  }

  void _drawDashed(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dashLength,
    required double gapLength,
  }) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CurvedArrowPainter old) =>
      old.direction != direction;
}
