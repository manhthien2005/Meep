import 'package:flutter/material.dart';

import 'package:meep/features/reaction/application/reaction_controller.dart';

/// M2: controller null → no-op stub.
/// M3: inject ReactionController to enable emoji reactions.
// TODO(R/T5/TBD): implement AppActTextBar per Figma — M3 reaction bar
class AppActTextBar extends StatelessWidget {
  const AppActTextBar({super.key, this.controller});

  /// When null (M2), all interactions are disabled.
  final ReactionController? controller;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
