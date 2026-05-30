import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/space/presentation/widgets/friend_select_step.dart';

class SpaceCreateSheet extends StatefulWidget {
  const SpaceCreateSheet({super.key});

  @override
  State<SpaceCreateSheet> createState() => _SpaceCreateSheetState();
}

class _SpaceCreateSheetState extends State<SpaceCreateSheet> {
  final _pageController = PageController();

  // State shared across steps
  final Set<String> _selectedFriendUids = {};
  String _spaceName = '';
  String _iconEmoji = '👥';
  String _colorHex = '#bfd5ff';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bw800,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 55,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.bw700,
                borderRadius: BorderRadius.circular(6.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // PageView
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                FriendSelectStep(
                  selectedFriendUids: _selectedFriendUids,
                  onContinue: () => _goToStep(1),
                  onClose: () => Navigator.of(context).pop(),
                ),
                _SpaceConfigStep(
                  spaceName: _spaceName,
                  iconEmoji: _iconEmoji,
                  colorHex: _colorHex,
                  onNameChanged: (name) => setState(() => _spaceName = name),
                  onPresetSelected: (emoji, color) {
                    setState(() {
                      _iconEmoji = emoji;
                      _colorHex = color;
                    });
                  },
                  onCustomIconTap: () => _goToStep(2),
                  onBack: () => _goToStep(0),
                  onComplete: _createSpace,
                ),
                _IconBuilderStep(
                  initialEmoji: _iconEmoji,
                  initialColor: _colorHex,
                  onDone: (emoji, color) {
                    setState(() {
                      _iconEmoji = emoji;
                      _colorHex = color;
                    });
                    _goToStep(1);
                  },
                  onBack: () => _goToStep(1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createSpace() async {
    // TODO(SP/T3.5): wire SpaceController.createSpace()
    Navigator.of(context).pop();
  }
}

// Step 2 stub
class _SpaceConfigStep extends StatelessWidget {
  const _SpaceConfigStep({
    required this.spaceName,
    required this.iconEmoji,
    required this.colorHex,
    required this.onNameChanged,
    required this.onPresetSelected,
    required this.onCustomIconTap,
    required this.onBack,
    required this.onComplete,
  });

  final String spaceName;
  final String iconEmoji;
  final String colorHex;
  final ValueChanged<String> onNameChanged;
  final void Function(String emoji, String color) onPresetSelected;
  final VoidCallback onCustomIconTap;
  final VoidCallback onBack;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            'Cấu hình Space',
            style: AppTextStyles.xlBold.copyWith(color: AppColors.bw100),
          ),
          const Spacer(),
          // TODO(SP/T3.3): TextField + preset list
          ElevatedButton(
            onPressed: spaceName.isEmpty ? null : onComplete,
            child: const Text('Hoàn tất'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// Step 3 stub
class _IconBuilderStep extends StatelessWidget {
  const _IconBuilderStep({
    required this.initialEmoji,
    required this.initialColor,
    required this.onDone,
    required this.onBack,
  });

  final String initialEmoji;
  final String initialColor;
  final void Function(String emoji, String color) onDone;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            'Tạo theme cho Space',
            style: AppTextStyles.xlBold.copyWith(color: AppColors.bw100),
          ),
          const Spacer(),
          // TODO(SP/T3.4): preview + emoji picker + color overlay
          ElevatedButton(
            onPressed: () => onDone(initialEmoji, initialColor),
            child: const Text('Xong'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
