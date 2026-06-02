import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meep/core/theme/app_colors.dart';

/// Align toolbar — thay thế Content toolbar khi tap icon align trong Canvas.
///
/// 4 lựa chọn (giống Word): trái / giữa / phải / căn đều. Selected highlight
/// nền Info/200 + border Info/500 (match `_FormatToggle` của TextStylePicker).
///
/// Widget thuần presentation: state (current align) do Canvas giữ, picker chỉ
/// render + phát callback.
class AlignPicker extends StatelessWidget {
  const AlignPicker({
    super.key,
    required this.current,
    required this.onSelected,
    required this.onClose,
  });

  final TextAlign current;
  final ValueChanged<TextAlign> onSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.turquoise200, // #F4FEFF
        border: Border(
          top: BorderSide(color: AppColors.turquoise500), // #00DEEE
        ),
      ),
      padding: const EdgeInsets.only(left: 18, right: 12),
      child: Row(
        children: [
          _IconTap(
            semanticLabel: 'Đóng căn lề',
            onTap: onClose,
            child: SvgPicture.asset(
              'assets/icons/ic_diary_close.svg',
              width: 18,
              height: 18,
            ),
          ),
          const SizedBox(width: 14),
          _AlignToggle(
            asset: 'assets/icons/ic_diary_align_left.svg',
            semanticLabel: 'Căn trái',
            active: current == TextAlign.left,
            onTap: () => onSelected(TextAlign.left),
          ),
          const SizedBox(width: 20),
          _AlignToggle(
            // Icon "center" có sẵn — reuse từ toolbar gốc.
            asset: 'assets/icons/ic_diary_align.svg',
            semanticLabel: 'Căn giữa',
            active: current == TextAlign.center,
            onTap: () => onSelected(TextAlign.center),
          ),
          const SizedBox(width: 20),
          _AlignToggle(
            asset: 'assets/icons/ic_diary_align_right.svg',
            semanticLabel: 'Căn phải',
            active: current == TextAlign.right,
            onTap: () => onSelected(TextAlign.right),
          ),
          const SizedBox(width: 20),
          _AlignToggle(
            asset: 'assets/icons/ic_diary_align_justify.svg',
            semanticLabel: 'Căn đều',
            active: current == TextAlign.justify,
            onTap: () => onSelected(TextAlign.justify),
          ),
        ],
      ),
    );
  }
}

/// Align toggle — selected: nền Info/200 + border Info/500 (match `_FormatToggle`).
class _AlignToggle extends StatelessWidget {
  const _AlignToggle({
    required this.asset,
    required this.semanticLabel,
    required this.active,
    required this.onTap,
  });

  final String asset;
  final String semanticLabel;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      toggled: active,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: active ? AppColors.info200 : Colors.transparent, // #E6EEFF
            borderRadius: BorderRadius.circular(5),
            border: active
                ? Border.all(color: AppColors.info500) // #4081FF
                : null,
          ),
          child: Center(
            child: SvgPicture.asset(asset, width: 18, height: 18),
          ),
        ),
      ),
    );
  }
}

/// Tap target tối thiểu 44×44 bọc 1 icon (close button).
class _IconTap extends StatelessWidget {
  const _IconTap({
    required this.child,
    required this.semanticLabel,
    required this.onTap,
  });

  final Widget child;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(width: 44, height: 44, child: Center(child: child)),
      ),
    );
  }
}
