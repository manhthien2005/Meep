import 'package:flutter/material.dart';

// TODO(D/T11/TBD): implement DiscardChangesDialog per Figma
class DiscardChangesDialog extends StatelessWidget {
  const DiscardChangesDialog({super.key});

  static Future<bool?> show(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (_) => const DiscardChangesDialog(),
      );

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
