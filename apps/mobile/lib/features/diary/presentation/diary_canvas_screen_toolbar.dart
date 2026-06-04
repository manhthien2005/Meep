part of 'diary_canvas_screen.dart';

/// Content toolbar — 4 SVG icons: image, type, align, smile.
/// Figma `658:6070` (Frame 1570, Turquoise/200 bg + Turquoise/500 border).
class _ContentToolbar extends StatelessWidget {
  const _ContentToolbar({
    required this.onType,
    required this.onAlign,
    required this.onImage,
  });

  final VoidCallback onType;
  final VoidCallback onAlign;
  final VoidCallback onImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.turquoise200,
        border: Border(top: BorderSide(color: AppColors.turquoise500)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          _SvgIconBtn(
            asset: 'assets/icons/ic_diary_image.svg',
            semanticLabel: 'Chọn ảnh bìa',
            onTap: onImage,
          ),
          const SizedBox(width: 22),
          _SvgIconBtn(
            asset: 'assets/icons/ic_diary_type.svg',
            semanticLabel: 'Kiểu chữ',
            onTap: onType,
          ),
          const SizedBox(width: 22),
          _SvgIconBtn(
            asset: 'assets/icons/ic_diary_align.svg',
            semanticLabel: 'Căn lề',
            onTap: onAlign,
          ),
          const SizedBox(width: 22),
          _SvgIconBtn(
            asset: 'assets/icons/ic_diary_smile.svg',
            semanticLabel: 'Chèn emoji',
            onTap: () {
              // TODO(D/T9/HanDHG): chèn emoji inline
            },
          ),
        ],
      ),
    );
  }
}

/// SVG icon button — 20×20 icon, 44×44 tap target.
class _SvgIconBtn extends StatelessWidget {
  const _SvgIconBtn({
    required this.asset,
    required this.semanticLabel,
    required this.onTap,
  });

  final String asset;
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
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: SvgPicture.asset(asset, width: 20, height: 20),
          ),
        ),
      ),
    );
  }
}
