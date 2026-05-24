import 'package:flutter/material.dart';

// TODO(SE/T9/TBD): implement LogoutConfirmDialog per Figma
class LogoutConfirmDialog extends StatelessWidget {
  const LogoutConfirmDialog({super.key});

  static Future<bool?> show(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (_) => const LogoutConfirmDialog(),
      );

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
