import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meep/core/theme/app_colors.dart';

/// Text style toolbar — thay thế Content toolbar khi tap icon [type] (Tt).
///
/// Figma `724:2989` (Frame 1570). Gồm: [x] đóng + Size dropdown +
/// Bold/Italic/Underline/Strikethrough. Format đang bật → nền Info/200 +
/// border Info/500.
///
/// Widget thuần presentation: state (size, format flags) do Canvas giữ,
/// picker chỉ render + phát callback.
class TextStylePicker extends StatelessWidget {
  const TextStylePicker({
    super.key,
    required this.size,
    required this.bold,
    required this.italic,
    required this.underline,
    required this.strikethrough,
    required this.onSizeSelected,
    required this.onBold,
    required this.onItalic,
    required this.onUnderline,
    required this.onStrikethrough,
    required this.onClose,
  });

  /// Text size hiện tại (1=Large, 2=Big, 3=Medium, 4=Small).
  final int size;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;

  final ValueChanged<int> onSizeSelected;
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onUnderline;
  final VoidCallback onStrikethrough;
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
          // Close — về lại Content toolbar
          _IconTap(
            semanticLabel: 'Đóng kiểu chữ',
            onTap: onClose,
            child: SvgPicture.asset(
              'assets/icons/ic_diary_close.svg',
              width: 18,
              height: 18,
            ),
          ),
          const SizedBox(width: 14),

          // Size dropdown — "Size N" + chevron-down
          _SizeDropdown(size: size, onSelected: onSizeSelected),
          const SizedBox(width: 18),

          // Format toggles
          _FormatToggle(
            asset: 'assets/icons/ic_diary_bold.svg',
            semanticLabel: 'In đậm',
            active: bold,
            onTap: onBold,
          ),
          const SizedBox(width: 20),
          _FormatToggle(
            asset: 'assets/icons/ic_diary_italic.svg',
            semanticLabel: 'In nghiêng',
            active: italic,
            onTap: onItalic,
          ),
          const SizedBox(width: 20),
          _FormatToggle(
            asset: 'assets/icons/ic_diary_underline.svg',
            semanticLabel: 'Gạch chân',
            active: underline,
            onTap: onUnderline,
          ),
          const SizedBox(width: 20),
          _FormatToggle(
            asset: 'assets/icons/ic_diary_strikethrough.svg',
            semanticLabel: 'Gạch ngang',
            active: strikethrough,
            onTap: onStrikethrough,
          ),
        ],
      ),
    );
  }
}

/// Size dropdown chip — "Size N" + chevron-down. Tap → menu 4 size popup lên.
class _SizeDropdown extends StatelessWidget {
  const _SizeDropdown({required this.size, required this.onSelected});

  final int size;
  final ValueChanged<int> onSelected;

  /// 4 size theo spec: 1=Large, 2=Big, 3=Medium, 4=Small.
  static const _labels = {
    1: 'Size 1 (Large)',
    2: 'Size 2 (Big)',
    3: 'Size 3 (Medium)',
    4: 'Size 4 (Small)',
  };

  Future<void> _openMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    // Anchor menu ngay trên chip (đẩy lên vì toolbar ở đáy).
    final position = RelativeRect.fromLTRB(
      topLeft.dx,
      topLeft.dy - 200,
      overlay.size.width - topLeft.dx - box.size.width,
      overlay.size.height - topLeft.dy,
    );

    final picked = await showMenu<int>(
      context: context,
      position: position,
      color: AppColors.bw100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        for (final entry in _labels.entries)
          PopupMenuItem<int>(
            value: entry.key,
            height: 44,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight:
                          entry.key == size ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.bw900,
                    ),
                  ),
                ),
                if (entry.key == size)
                  const Icon(Icons.check, size: 18, color: AppColors.info500),
              ],
            ),
          ),
      ],
    );
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cỡ chữ',
      button: true,
      child: InkWell(
        onTap: () => _openMenu(context),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Size $size',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.bw900,
                  height: 22 / 16,
                ),
              ),
              const SizedBox(width: 2),
              SvgPicture.asset(
                'assets/icons/ic_diary_chevron_down.svg',
                width: 18,
                height: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Format toggle (bold/italic/...) — selected: nền Info/200 + border Info/500.
class _FormatToggle extends StatelessWidget {
  const _FormatToggle({
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

/// Tap target tối thiểu 44×44 bọc 1 icon.
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
