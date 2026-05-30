import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/space/presentation/widgets/space_color_overlay.dart';
import 'package:meep/shared/widgets/app_primary_button.dart';

/// 9 màu nền gợi ý cho icon — Figma 269:1334 source of truth.
const kIconBgSuggestions = <String>[
  '#FEEBCA',
  '#FFCFBF',
  '#C4F3D9',
  '#BFD5FF',
  '#CED9DA',
  '#FFDEFC',
  '#CDCAFE',
  '#FECACF',
  '#CAF2FE',
];

class IconBuilderStep extends StatefulWidget {
  const IconBuilderStep({
    super.key,
    required this.initialEmoji,
    required this.initialColor,
    required this.onDone,
  });

  final String initialEmoji;
  final String initialColor;
  final void Function(String emoji, String color) onDone;

  @override
  State<IconBuilderStep> createState() => _IconBuilderStepState();
}

class _IconBuilderStepState extends State<IconBuilderStep> {
  late String _emoji = widget.initialEmoji;
  late String _color = widget.initialColor;

  void _openEmojiPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bw800,
      builder: (_) => SizedBox(
        height: 300,
        child: EmojiPicker(
          onEmojiSelected: (category, emoji) {
            setState(() => _emoji = emoji.emoji);
            Navigator.of(context).pop();
          },
          config: const Config(
            emojiViewConfig: EmojiViewConfig(
              backgroundColor: AppColors.bw800,
              columns: 7,
              emojiSizeMax: 28,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openColorOverlay() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SpaceColorOverlay(initialColor: _color),
    );
    if (picked != null) {
      setState(() => _color = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'Tạo theme cho Space',
            style: AppTextStyles.xlBold.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Cá nhân hóa Space cho riêng bạn',
            style: AppTextStyles.baseBold.copyWith(
              color: const Color(0xFFBABABA),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Preview circle
          _PreviewCircle(emoji: _emoji, colorHex: _color),
          const SizedBox(height: 16),
          // 2 tab buttons: emoji / color
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TabButton(
                icon: Icons.emoji_emotions_outlined,
                onTap: _openEmojiPicker,
              ),
              const SizedBox(width: 13),
              _TabButton(
                icon: Icons.palette_outlined,
                onTap: _openColorOverlay,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Section "Gợi ý"
          Row(
            children: [
              const Icon(
                Icons.brush_outlined,
                size: 20,
                color: Color(0xFFD5D5D5),
              ),
              const SizedBox(width: 8),
              Text(
                'Gợi ý',
                style: AppTextStyles.baseBold.copyWith(
                  color: const Color(0xFFDDDDDD),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 9 suggestion circles
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 20,
              crossAxisSpacing: 25,
              children: [
                for (final bg in kIconBgSuggestions)
                  _SuggestionCircle(
                    emoji: _emoji,
                    colorHex: bg,
                    isSelected: _color.toUpperCase() == bg,
                    onTap: () => setState(() => _color = bg),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppPrimaryButton(
            label: 'Xong',
            showTrailingIcon: false,
            onPressed: () => widget.onDone(_emoji, _color),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PreviewCircle extends StatelessWidget {
  const _PreviewCircle({required this.emoji, required this.colorHex});

  final String emoji;
  final String colorHex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: hexToColor(colorHex),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 36)),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x66394041),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Icon(icon, size: 24, color: AppColors.bw100),
      ),
    );
  }
}

class _SuggestionCircle extends StatelessWidget {
  const _SuggestionCircle({
    required this.emoji,
    required this.colorHex,
    required this.isSelected,
    required this.onTap,
  });

  final String emoji;
  final String colorHex;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: hexToColor(colorHex),
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: AppColors.turquoise500, width: 3)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 36)),
      ),
    );
  }
}

Color hexToColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
