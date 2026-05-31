import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_proportions.dart';

/// Pagination dot row used by camera mode (2 dots) and caption preview (7 dots).
///
/// Figma `442:2354` — outer dots shrink (8 → 6 → 4) for caption preview.
class AppDotsIndicator extends StatelessWidget {
  const AppDotsIndicator({
    super.key,
    required this.count,
    required this.current,
    this.shrinkOuter = false,
  });

  final int count;
  final int current;

  /// When true (caption preview), dots far from current shrink proportionally.
  final bool shrinkOuter;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final activeSize = AppProportions.dotActiveSize(screenW);
    final spacing = AppProportions.dotSpacing(screenW);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final size = _sizeFor(i, activeSize, screenW);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing / 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: i == current ? AppColors.bw100 : AppColors.bw500,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }

  double _sizeFor(int i, double activeSize, double screenW) {
    if (!shrinkOuter) return activeSize;
    final dist = (i - current).abs();
    // Figma 442:2354: dist≥3 → 4px, dist==2 → 6px, else 8px (on 412px frame)
    if (dist >= 3) return screenW * (4 / AppProportions.figmaFrameWidth);
    if (dist == 2) return screenW * (6 / AppProportions.figmaFrameWidth);
    return activeSize;
  }
}
