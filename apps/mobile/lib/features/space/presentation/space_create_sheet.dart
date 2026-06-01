import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meep/features/space/application/space_controller.dart';
import 'package:meep/features/space/presentation/widgets/friend_select_step.dart';
import 'package:meep/features/space/presentation/widgets/icon_builder_step.dart';
import 'package:meep/features/space/presentation/widgets/space_config_step.dart';
import 'package:meep/shared/widgets/app_bottom_sheet.dart';

class SpaceCreateSheet extends ConsumerStatefulWidget {
  const SpaceCreateSheet({super.key});

  @override
  ConsumerState<SpaceCreateSheet> createState() => _SpaceCreateSheetState();
}

class _SpaceCreateSheetState extends ConsumerState<SpaceCreateSheet> {
  final _pageController = PageController();

  // State shared across steps
  final Set<String> _selectedFriendUids = {};
  String _spaceName = '';
  // Default icon = mặt cười 😄 + nền warning300 (Figma Step 3 default).
  String _iconEmoji = '😄';
  String _colorHex = '#FEEBCA';
  bool _isCreating = false;

  // Preset tuỳ chỉnh user tạo ở Step 3 — lưu lại để chọn + đặt tên ở Step 2.
  final List<SpacePreset> _customPresets = [];

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
    return AppBottomSheet(
      // PageView cần bounded height — pin sheet ở 95% màn hình.
      heightFactor: 0.95,
      child: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          FriendSelectStep(
            selectedFriendUids: _selectedFriendUids,
            onContinue: () => _goToStep(1),
            onClose: () => Navigator.of(context).pop(),
          ),
          SpaceConfigStep(
            spaceName: _spaceName,
            iconEmoji: _iconEmoji,
            colorHex: _colorHex,
            isLoading: _isCreating,
            customPresets: _customPresets,
            onNameChanged: (name) => setState(() => _spaceName = name),
            onPresetSelected: (emoji, color) {
              setState(() {
                _iconEmoji = emoji;
                _colorHex = color;
              });
            },
            onCustomIconTap: () => _goToStep(2),
            onComplete: _createSpace,
          ),
          IconBuilderStep(
            initialEmoji: _iconEmoji,
            initialColor: _colorHex,
            onDone: _onCustomIconDone,
          ),
        ],
      ),
    );
  }

  /// Step 3 "Xong": lưu custom preset vào grid (nếu chưa có) + auto-select +
  /// về Step 2. Dedup theo (emoji, colorHex) — không thêm trùng.
  void _onCustomIconDone(String emoji, String color) {
    setState(() {
      _iconEmoji = emoji;
      _colorHex = color;
      final exists = _customPresets.any(
            (p) =>
                p.emoji == emoji &&
                p.colorHex.toUpperCase() == color.toUpperCase(),
          ) ||
          kSpacePresets.any(
            (p) =>
                p.emoji == emoji &&
                p.colorHex.toUpperCase() == color.toUpperCase(),
          );
      if (!exists) {
        _customPresets.add(SpacePreset(emoji, color));
      }
    });
    _goToStep(1);
  }

  Future<void> _createSpace() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);
    try {
      await ref.read(spaceControllerProvider.notifier).createSpace(
            name: _spaceName.trim(),
            iconEmoji: _iconEmoji,
            colorHex: _colorHex,
            friendUids: _selectedFriendUids.toList(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tạo được Space: $e')),
      );
    }
  }
}
