import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';

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
  // Logo slow rotation: 8s per revolution, starts after entry
  late final AnimationController _logoCtrl;

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

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );

    // Start entry → after done, start logo rotation
    _entryCtrl.forward().then((_) {
      if (mounted) _logoCtrl.repeat();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _beamCtrl.dispose();
    _logoCtrl.dispose();
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
      body: Stack(
        children: [
          // Beam với breathing opacity
          AnimatedBuilder(
            animation: _beamCtrl,
            builder: (_, __) => _Beam(
              // 0.85 → 1.0 breathing (±8% opacity, barely noticeable but alive)
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
                      SizedBox(height: h * 0.451),

                      // Logo: entry stagger [0.10-0.60] + rotation after entry
                      _stagger(
                        start: 0.10,
                        end: 0.60,
                        child: _AnimatedLogo(rotationCtrl: _logoCtrl),
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

class _Beam extends StatelessWidget {
  const _Beam({this.opacity = 1.0});

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

// ── Logo với rotation ─────────────────────────────────────────────────────────

class _AnimatedLogo extends StatelessWidget {
  const _AnimatedLogo({required this.rotationCtrl});

  final AnimationController rotationCtrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      // Chỉ rotate inner logomark, white container đứng yên
      child: RotationTransition(
        turns: rotationCtrl,
        child: SvgPicture.asset(
          'assets/icons/ic_logo.svg',
          width: 56,
          height: 49,
        ),
      ),
    );
  }
}

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
                      color: const Color(0xFFEEF2F3),
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
