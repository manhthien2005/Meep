import 'package:flutter/material.dart';

// TODO(SE/T8/TBD): implement BlockConfirmDialog per Figma — 605:1991
class BlockConfirmDialog extends StatelessWidget {
  const BlockConfirmDialog({super.key, required this.targetName});

  final String targetName;

  static Future<bool?> show(BuildContext context, String targetName) =>
      showDialog<bool>(
        context: context,
        builder: (_) => BlockConfirmDialog(targetName: targetName),
      );

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
