import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_proportions.dart';

/// Editable caption overlay pill. cornerRadius 30, semi-transparent bg.
///
/// Editable mode width is fixed at [editableWidthRatio] of the screen (40%)
/// so the pill anchors at a predictable size as the user swipes between
/// caption presets. Long text scrolls horizontally inside the TextField.
/// Read-only mode still hugs content with a soft ellipsis safety net.
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

  /// Editable pill width as a ratio of screen width. Fixed (not hug-content)
  /// so swiping between caption presets doesn't make the pill jump around.
  static const double editableWidthRatio = 0.40;

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
    // Fixed 40%-of-screen width. The TextField stays single-line and scrolls
    // horizontally inside itself when the typed text exceeds the visible area.
    final width = screenW * AppNotePill.editableWidthRatio;

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
