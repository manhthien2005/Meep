import 'package:flutter/material.dart';

/// Bottom navigation taskbar — shared across Feed, Profile, Diary, Chat, Streak.
///
/// Owner: ThienPDM (leader-owned shared widget).
/// Figma: OQ8 — node ID TBD, pending designer confirmation.
///
/// Contract:
///   - [activeTab] — which tab is currently highlighted.
///   - [onTabSelected] — called when user taps a tab; caller handles navigation.
///   - Height: 64px logical pixels (48px touch target + 8px top/bottom padding).
///   - Background: Theme surface. No elevation shadow per Figma.
///
// TODO(OQ8/ThienPDM): confirm Figma node ID for AppTaskbar with HanDHG/NganTNK
// TODO(T3/TBD): implement AppTaskbar per Figma once node ID confirmed
enum TaskbarTab { feed, profile, diary, chat, streak }

class AppTaskbar extends StatelessWidget {
  const AppTaskbar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
  });

  final TaskbarTab activeTab;
  final ValueChanged<TaskbarTab> onTabSelected;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
