import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_proportions.dart';

/// Editable caption overlay pill. cornerRadius 30, semi-transparent bg.
/// Fixed-width text area: marquee ping-pong when readOnly + text overflows.
/// Width and font size are computed internally from MediaQuery.
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

  @override
  State<AppNotePill> createState() => _AppNotePillState();
}

class _AppNotePillState extends State<AppNotePill>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _ctrl;
  AnimationController? _marqueeCtrl;
  Animation<double>? _marqueeAnim;

  double _textAreaWidth = 0;
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
    _ctrl.addListener(() => widget.onChanged?.call(_ctrl.text));

    if (widget.readOnly) {
      _marqueeCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2500),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _setupMarquee());
    }
  }

  void _setupMarquee() {
    final tp = TextPainter(
      text: TextSpan(text: widget.text, style: _textStyle(_fontSize)),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    final overflow = tp.width - _textAreaWidth;
    if (overflow > 0 && _marqueeCtrl != null) {
      _marqueeAnim = Tween<double>(begin: 0, end: -(overflow + 8)).animate(
        CurvedAnimation(parent: _marqueeCtrl!, curve: Curves.easeInOut),
      );
      _marqueeCtrl!.repeat(reverse: true);
      if (mounted) setState(() {});
    }
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
    _marqueeCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final pillW = AppProportions.pillWidth(screenW);
    _fontSize = AppProportions.pillFontSize(screenW);
    final iconSize = _fontSize + 2;
    // Fixed-width pill: text area = pill width minus padding, icon, and gap.
    _textAreaWidth = pillW -
        AppProportions.pillPaddingH * 2 -
        iconSize -
        AppProportions.pillIconGap;

    return Container(
      width: pillW,
      padding: const EdgeInsets.symmetric(
        horizontal: AppProportions.pillPaddingH,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0x66394041),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.text_fields, color: AppColors.bw300, size: iconSize),
          const SizedBox(width: AppProportions.pillIconGap),
          SizedBox(
            width: _textAreaWidth,
            child: widget.readOnly ? _buildMarquee() : _buildTextField(),
          ),
        ],
      ),
    );
  }

  Widget _buildMarquee() {
    if (_marqueeAnim == null) {
      return Text(
        widget.text,
        style: _textStyle(_fontSize),
        maxLines: 1,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      );
    }
    return ClipRect(
      child: AnimatedBuilder(
        animation: _marqueeAnim!,
        builder: (_, child) => Transform.translate(
          offset: Offset(_marqueeAnim!.value, 0),
          child: child,
        ),
        child: Text(
          widget.text,
          style: _textStyle(_fontSize),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _ctrl,
      style: _textStyle(_fontSize),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        hintText: 'Nhập chú thích...',
        hintStyle: TextStyle(color: AppColors.bw500, fontSize: _fontSize),
        contentPadding: EdgeInsets.zero,
      ),
      maxLength: 200,
      buildCounter:
          (_, {required currentLength, required isFocused, maxLength}) => null,
    );
  }
}
