import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';

/// Reusable circular icon button used by camera controls, capture preview,
/// share modal etc. Loading state replaces icon with spinner.
class AppCircleIconButton extends StatelessWidget {
  const AppCircleIconButton({
    super.key,
    required this.icon,
    required this.size,
    this.onPressed,
    this.backgroundColor = AppColors.bw700,
    this.iconColor = AppColors.bw100,
    this.iconScale = 0.44,
    this.isLoading = false,
    this.transparentBackground = false,
  });

  final IconData icon;
  final double size;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color iconColor;

  /// Icon size = `size * iconScale`. Default 0.44 matches Figma 36×36 icon
  /// inside 82×82 button (36/82 ≈ 0.44).
  final double iconScale;
  final bool isLoading;

  /// When true, background is transparent (no circle fill).
  final bool transparentBackground;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: transparentBackground ? Colors.transparent : backgroundColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  width: size * 0.4,
                  height: size * 0.4,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: iconColor,
                  ),
                )
              : Icon(icon, color: iconColor, size: size * iconScale),
        ),
      ),
    );
  }
}
