import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_proportions.dart';

/// Editable caption overlay pill. cornerRadius 30, semi-transparent bg.
///
/// Hug-content: the pill sizes itself to the current text instead of being
/// fixed-width. The text area is measured with [TextPainter] each rebuild,
/// then clamped to a sane min (so an empty pill is still tappable) and a max
/// (so a maxed-out 30-char caption never overflows the photo frame).
class AppNotePill extends StatefulWidget {
  const AppNotePill({
    super.key,
    required this.text,
    this.onChanged,
    this.readOnly = false,
  });

  final String text;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  /// Max length the editable pill enforces. Matches the Firestore rule cap
  /// (which is 200) but app-side we keep captions short enough to render
  /// nicely in a single-line overlay.
  static const int maxLength = 30;

  @override
  State<AppNotePill> createState() => _AppNotePillState();
}

class _AppNotePillState extends State<AppNotePill> {
  late final TextEditingController _ctrl;
  double _fontSize = 14;

  TextStyle _textStyle(double fontSize) => TextStyle(
        color: AppColors.bw100,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        fontFamily: 'Nunito',
      );

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.text);
    _ctrl.addListener(() {
      widget.onChanged?.call(_ctrl.text);
      // Re-measure so the pill grows / shrinks as the user types.
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(AppNotePill old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text && _ctrl.text != widget.text) {
      _ctrl.text = widget.text;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Measure the visual width of [text] at the current font.
  double _measureText(String text) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: _textStyle(_fontSize)),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width;
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    _fontSize = AppProportions.pillFontSize(screenW);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppProportions.pillPaddingH,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0x66394041),
        borderRadius: BorderRadius.circular(30),
      ),
      child: widget.readOnly ? _buildReadOnly() : _buildTextField(screenW),
    );
  }

  Widget _buildReadOnly() {
    // 30-char cap on input means the readOnly pill never needs marquee or
    // wrap — a single line with ellipsis is enough as a safety net.
    return Text(
      widget.text,
      style: _textStyle(_fontSize),
      maxLines: 1,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTextField(double screenW) {
    // Hug width: measure the typed text, clamp to [min, max] so the pill is
    // always tappable when empty and never spills past the photo frame.
    final text = _ctrl.text;
    final measured = _measureText(text.isEmpty ? 'A' : text);
    final minW = _fontSize; // ~1 character of space when empty
    final maxW =
        screenW - AppProportions.pillPaddingH * 2 - 24; // 24 = safety margin
    final width = measured.clamp(minW, maxW);

    return SizedBox(
      width: width,
      child: TextField(
        controller: _ctrl,
        style: _textStyle(_fontSize),
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: '',
          contentPadding: EdgeInsets.zero,
        ),
        maxLength: AppNotePill.maxLength,
        buildCounter: (
          _, {
          required currentLength,
          required isFocused,
          maxLength,
        }) =>
            null,
      ),
    );
  }
}
