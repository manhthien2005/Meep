import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/core/theme/hex_color.dart';
import 'package:meep/shared/widgets/app_primary_button.dart';

/// Preset icon = (emoji, background color) paired — Figma 269:1257 source of truth.
class SpacePreset {
  const SpacePreset(this.emoji, this.colorHex);
  final String emoji;
  final String colorHex;
}

const kSpacePresets = <SpacePreset>[
  SpacePreset('👨‍👩‍👧‍👦', '#BFD5FF'),
  SpacePreset('❤️', '#FFCFBF'),
  SpacePreset('🎃', '#FEEBCA'),
  SpacePreset('🐸', '#C4F3D9'),
  SpacePreset('🌼', '#F9FFC4'),
  SpacePreset('🐻‍❄️', '#EEF2F3'),
  SpacePreset('🥰', '#FFF7EA'),
  SpacePreset('🫃', '#BFD5FF'),
];

class SpaceConfigStep extends StatelessWidget {
  const SpaceConfigStep({
    super.key,
    required this.spaceName,
    required this.iconEmoji,
    required this.colorHex,
    required this.onNameChanged,
    required this.onPresetSelected,
    required this.onCustomIconTap,
    required this.onComplete,
    this.customPresets = const [],
    this.isLoading = false,
  });

  final String spaceName;
  final String iconEmoji;
  final String colorHex;
  final ValueChanged<String> onNameChanged;
  final void Function(String emoji, String color) onPresetSelected;
  final VoidCallback onCustomIconTap;
  final VoidCallback onComplete;

  /// Preset tuỳ chỉnh user tạo ở Step 3 — hiện sau 8 preset gốc, trước ô "+".
  final List<SpacePreset> customPresets;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'Cấu hình Space',
            style: AppTextStyles.xlBold.copyWith(color: AppColors.bw100),
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
          // Section: Đặt tên cho Space
          const _SectionHeader(
            icon: Icons.text_fields,
            label: 'Đặt tên cho Space',
          ),
          const SizedBox(height: 12),
          _NameField(value: spaceName, onChanged: onNameChanged),
          const SizedBox(height: 24),
          // Section: Space theme
          const _SectionHeader(
            icon: Icons.palette_outlined,
            label: 'Space theme',
          ),
          const SizedBox(height: 16),
          // Preset grid 3 cột (8 preset gốc + N custom + ô "+")
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 20,
              crossAxisSpacing: 25,
              children: [
                for (final preset in [...kSpacePresets, ...customPresets])
                  _PresetCircle(
                    preset: preset,
                    isSelected: iconEmoji == preset.emoji &&
                        colorHex.toUpperCase() == preset.colorHex.toUpperCase(),
                    onTap: () =>
                        onPresetSelected(preset.emoji, preset.colorHex),
                  ),
                _CustomIconCircle(onTap: onCustomIconTap),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppPrimaryButton(
            label: 'Hoàn tất',
            showTrailingIcon: false,
            isLoading: isLoading,
            onPressed: spaceName.trim().isEmpty ? null : onComplete,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFD5D5D5)),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.baseBold.copyWith(
            color: const Color(0xFFDDDDDD),
          ),
        ),
      ],
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF363636),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 13),
      child: TextField(
        maxLength: 30,
        onChanged: onChanged,
        style: AppTextStyles.mdSemiBold.copyWith(color: AppColors.bw100),
        decoration: InputDecoration(
          hintText: 'Meepsie',
          hintStyle: AppTextStyles.mdSemiBold.copyWith(
            color: const Color(0x80FFFFFF),
          ),
          border: InputBorder.none,
          isDense: true,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _PresetCircle extends StatelessWidget {
  const _PresetCircle({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  final SpacePreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: hexToColor(preset.colorHex),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              preset.emoji,
              style: const TextStyle(fontSize: 36),
            ),
          ),
          if (isSelected)
            const Positioned(
              top: 4,
              right: 4,
              child: _SelectedBadge(),
            ),
        ],
      ),
    );
  }
}

class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: AppColors.bw800,
        shape: BoxShape.circle,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.turquoise500,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 12, color: AppColors.bw900),
      ),
    );
  }
}

class _CustomIconCircle extends StatelessWidget {
  const _CustomIconCircle({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bw600,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.add, size: 40, color: Color(0xFFD5D5D5)),
      ),
    );
  }
}
