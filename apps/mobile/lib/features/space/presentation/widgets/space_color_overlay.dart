import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';

/// 12 màu cơ bản cho overlay "Màu nền" — Figma 600:3498 source of truth.
const kColorPalette = <String>[
  '#FF0000',
  '#FF8800',
  '#FFEA00',
  '#4DFF00',
  '#00FF77',
  '#1AFFD1',
  '#00C8FF',
  '#0015FF',
  '#6200FF',
  '#CC00FF',
  '#FF00D9',
  '#706C6C',
];

/// Overlay chọn màu nền cho icon Space. Tap màu → chọn, kéo slider → chỉnh
/// sắc độ (lightness). Mỗi thay đổi fire [onColorChanged] để preview phía sau
/// sync trực tiếp (live). Bấm X → đóng (màu đã sync, không cần trả về).
class SpaceColorOverlay extends StatefulWidget {
  const SpaceColorOverlay({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  final String initialColor;
  final ValueChanged<String> onColorChanged;

  @override
  State<SpaceColorOverlay> createState() => _SpaceColorOverlayState();
}

class _SpaceColorOverlayState extends State<SpaceColorOverlay> {
  late Color _base = _hexToColor(widget.initialColor);
  double _lightness = 0.5;

  Color get _result {
    final hsl = HSLColor.fromColor(_base);
    return hsl.withLightness(_lightness.clamp(0.0, 1.0)).toColor();
  }

  String get _resultHex {
    final argb = _result.toARGB32();
    final rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '#${rgb.toUpperCase()}';
  }

  void _notify() => widget.onColorChanged(_resultHex);

  void _selectColor(String hex) {
    setState(() {
      _base = _hexToColor(hex);
      _lightness = HSLColor.fromColor(_base).lightness;
    });
    _notify();
  }

  void _onLightnessChanged(double v) {
    setState(() => _lightness = v);
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bw800,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0x8073706E)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: title center + X close
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'Màu nền',
                  style: AppTextStyles.baseBold.copyWith(color: Colors.white),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: _CloseButton(
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Color grid 4 cột
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 22,
              crossAxisSpacing: 30,
              children: [
                for (final hex in kColorPalette)
                  _ColorDot(
                    hex: hex,
                    isSelected: _hexToColor(hex).toARGB32() == _base.toARGB32(),
                    onTap: () => _selectColor(hex),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            // Shade slider
            _ShadeSlider(
              base: _base,
              lightness: _lightness,
              onChanged: _onLightnessChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.bw700,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.close, size: 22, color: AppColors.bw500),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.hex,
    required this.isSelected,
    required this.onTap,
  });

  final String hex;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _hexToColor(hex),
          border: isSelected ? Border.all(color: Colors.white, width: 4) : null,
        ),
      ),
    );
  }
}

class _ShadeSlider extends StatelessWidget {
  const _ShadeSlider({
    required this.base,
    required this.lightness,
    required this.onChanged,
  });

  final Color base;
  final double lightness;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(base);
    return SizedBox(
      height: 35,
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: 35,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 15),
          thumbColor: Colors.white,
          overlayShape: SliderComponentShape.noOverlay,
          trackShape: _GradientTrackShape(
            colors: [
              hsl.withLightness(0.15).toColor(),
              hsl.withLightness(0.5).toColor(),
              hsl.withLightness(0.9).toColor(),
            ],
          ),
        ),
        child: Slider(
          value: lightness.clamp(0.0, 1.0),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Custom track vẽ gradient theo shade của màu đang chọn.
class _GradientTrackShape extends RoundedRectSliderTrackShape {
  const _GradientTrackShape({required this.colors});

  final List<Color> colors;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));
    final paint = Paint()
      ..shader = LinearGradient(colors: colors).createShader(rect);
    context.canvas.drawRRect(rrect, paint);
  }
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
