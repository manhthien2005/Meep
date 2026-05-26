import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/auth/presentation/widgets/intro_beam.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with TickerProviderStateMixin {
  // Staggered entry: 1.0s total
  late final AnimationController _entryCtrl;
  // Beam "breathing": 6s per cycle
  late final AnimationController _beamCtrl;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Beam starts immediately with breathing
    _beamCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat(reverse: true);

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _beamCtrl.dispose();
    super.dispose();
  }

  // Helper: fade + slide-up with interval
  Widget _stagger({
    required double start,
    required double end,
    required Widget child,
  }) {
    final anim = CurvedAnimation(
      parent: _entryCtrl,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.22),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bw900,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Beam với breathing opacity
          AnimatedBuilder(
            animation: _beamCtrl,
            builder: (_, __) => IntroBeam(
              opacity: 0.85 + 0.15 * _beamCtrl.value,
            ),
          ),
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
                      // Figma: logo tại y=414/917 ≈ 45.1%
                      // Dùng flexible spacer tránh overflow màn hình nhỏ
                      const Flexible(
                        flex: 451,
                        child: SizedBox.expand(),
                      ),

                      // Logo: entry stagger [0.10-0.60]
                      _stagger(
                        start: 0.10,
                        end: 0.60,
                        child: SvgPicture.asset(
                          'assets/icons/ic_logo_full.svg',
                          width: 90,
                          height: 90,
                        ),
                      ),
                      const SizedBox(height: 7),

                      // "Meep": [0.25-0.70]
                      _stagger(
                        start: 0.25,
                        end: 0.70,
                        child: Text(
                          'Meep',
                          style: AppTextStyles.xl2Bold.copyWith(
                            color: Colors.white,
                            height: 42 / 32,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tagline: [0.35-0.80]
                      _stagger(
                        start: 0.35,
                        end: 0.80,
                        child: const Padding(
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
                      ),
                      const SizedBox(height: 61),

                      // Button 1: [0.50-0.90]
                      _stagger(
                        start: 0.50,
                        end: 0.90,
                        child: const _GlassButton(
                          label: 'Tạo tài khoản mới',
                          route: '/signup/email',
                          width: 249,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Button 2: [0.62-1.00]
                      _stagger(
                        start: 0.62,
                        end: 1.00,
                        child: const _TransparentButton(
                          label: 'Đăng nhập',
                          route: '/login/email',
                          width: 198,
                        ),
                      ),
                      const Flexible(
                        flex: 60,
                        child: SizedBox.expand(),
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
// Painter + wrapper moved to widgets/intro_beam.dart for re-use + line cap.

// ── Glass button (StatefulWidget cho press state) ─────────────────────────────

class _GlassButton extends StatefulWidget {
  const _GlassButton({
    required this.label,
    required this.route,
    required this.width,
  });

  final String label;
  final String route;
  final double width;

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _pressed = true);
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () => context.push(widget.route),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          // Down: fast (80ms) | Up: slight overshoot spring (220ms)
          duration: Duration(milliseconds: _pressed ? 80 : 220),
          curve: _pressed ? Curves.easeIn : Curves.easeOutBack,
          child: SizedBox(
            width: widget.width,
            height: 56,
            child: Stack(
              children: [
                SvgPicture.asset(
                  'assets/icons/ic_btn_glass.svg',
                  width: widget.width,
                  height: 56,
                  fit: BoxFit.fill,
                ),
                Center(
                  child: Text(
                    widget.label,
                    style: AppTextStyles.mdBold.copyWith(
                      color: AppColors.bw200,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Transparent button (StatefulWidget cho press state) ───────────────────────

class _TransparentButton extends StatefulWidget {
  const _TransparentButton({
    required this.label,
    required this.route,
    required this.width,
  });

  final String label;
  final String route;
  final double width;

  @override
  State<_TransparentButton> createState() => _TransparentButtonState();
}

class _TransparentButtonState extends State<_TransparentButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () => context.push(widget.route),
        child: AnimatedOpacity(
          opacity: _pressed ? 0.55 : 1.0,
          duration: Duration(milliseconds: _pressed ? 60 : 180),
          child: SizedBox(
            width: widget.width,
            height: 56,
            child: Center(
              child: Text(
                widget.label,
                style: AppTextStyles.mdBold.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
