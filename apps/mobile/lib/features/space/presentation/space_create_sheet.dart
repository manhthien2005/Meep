import 'package:flutter/material.dart';
import 'package:meep/features/space/presentation/widgets/friend_select_step.dart';
import 'package:meep/features/space/presentation/widgets/icon_builder_step.dart';
import 'package:meep/features/space/presentation/widgets/space_config_step.dart';
import 'package:meep/shared/widgets/app_bottom_sheet.dart';

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
    // TODO(SP/T3.5): wire SpaceController.createSpace()
    Navigator.of(context).pop();
  }
}
