import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_proportions.dart';

/// Capture button: 82×82 turquoise outer ring, 70×70 white inner circle.
/// Animated scale on press.
///
/// `size` defaults to Figma 82×82 but can be overridden when scaling to
/// device width. Inner circle is always 85.4% of outer (Figma 70/82).
class AppCameraButton extends StatefulWidget {
  const AppCameraButton({
    super.key,
    this.onPressed,
    this.size = 82,
  });

  final VoidCallback? onPressed;
  final double size;

  @override
  State<AppCameraButton> createState() => _AppCameraButtonState();
}

class _AppCameraButtonState extends State<AppCameraButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _anim.forward();
  Future<void> _onTapUp(_) async {
    await _anim.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() => _anim.reverse();

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final outer = widget.size;
    final inner = outer * AppProportions.captureInnerToOuterRatio;

    return GestureDetector(
      onTapDown: enabled ? _onTapDown : null,
      onTapUp: enabled ? _onTapUp : null,
      onTapCancel: enabled ? _onTapCancel : null,
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: outer,
          height: outer,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: outer,
                height: outer,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: enabled ? AppColors.turquoise500 : AppColors.bw600,
                    width: AppProportions.captureRingWidth,
                  ),
                ),
              ),
              Container(
                width: inner,
                height: inner,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bw100,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
