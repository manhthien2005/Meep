import 'package:flutter/material.dart';

// TODO(SE/T11/TBD): implement DeleteAccountDialog per Figma
class DeleteAccountDialog extends StatelessWidget {
  const DeleteAccountDialog({super.key});

  static Future<bool?> show(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (_) => const DeleteAccountDialog(),
      );

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
