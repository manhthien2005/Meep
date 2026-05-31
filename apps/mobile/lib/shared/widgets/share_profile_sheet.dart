import 'package:flutter/material.dart';

/// Shared widget — used by both Settings and Profile modules.
// TODO(SE/T12/TBD): implement ShareProfileSheet per Figma — 573:3648
class ShareProfileSheet extends StatelessWidget {
  const ShareProfileSheet({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
