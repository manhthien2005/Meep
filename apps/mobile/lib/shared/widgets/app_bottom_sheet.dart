import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';

/// Shared bottom sheet container với handle bar + rounded top corners.
/// Dùng cho tất cả bottom sheets trong app.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.bw800,
    this.heightFactor,
  });

  final Widget child;
  final Color backgroundColor;

  /// Optional fixed height as a fraction of screen height (0.0–1.0).
  ///
  /// - `null` (default): the sheet hugs its content. The consumer controls the
  ///   height by wrapping the sheet (e.g. `SizedBox(height: ...)`) or by letting
  ///   the content size it. Use for short sheets (confirm dialogs, pickers).
  /// - set (e.g. `0.95`): the sheet is pinned to `screenHeight * heightFactor`.
  ///   Required when the content needs a bounded height of its own — e.g. a
  ///   `PageView` (SpaceCreateSheet) which cannot lay out unbounded.
  final double? heightFactor;

  @override
  Widget build(BuildContext context) {
    final height = heightFactor == null
        ? null
        : MediaQuery.of(context).size.height * heightFactor!;

    return Container(
      height: height,
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
          // Content. Flexible (loose) lets the sheet hug short content when
          // heightFactor is null, and fill the pinned height when it is set.
          Flexible(child: child),
        ],
      ),
    );
  }
}
