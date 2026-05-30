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
  String _iconEmoji = '👥';
  String _colorHex = '#bfd5ff';
  bool _isCreating = false;

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
            onDone: (emoji, color) {
              setState(() {
                _iconEmoji = emoji;
                _colorHex = color;
              });
              _goToStep(1);
            },
          ),
        ],
      ),
    );
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
