import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';

/// Shared bottom sheet container với handle bar + rounded top corners.
/// Dùng cho tất cả bottom sheets trong app.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.bw800,
  });

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 55,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.bw700,
                borderRadius: BorderRadius.circular(6.5),
              ),
            ),
          ),
          // Content
          Expanded(child: child),
        ],
      ),
    );
  }
}
