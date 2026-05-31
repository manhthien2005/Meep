import 'package:flutter/material.dart';

/// Shared widget — used by both Settings and Profile modules.
// TODO(SE/T12/TBD): implement ShareProfileSheet per Figma — 573:3648
class ShareProfileSheet extends StatelessWidget {
  const ShareProfileSheet({
    super.key,
    required this.uid,
    this.username,
    this.title,
  });

  final String uid;
  final String? username;
  final String? title;

  static Future<void> show(
    BuildContext context, {
    required String uid,
    String? username,
    String? title,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => ShareProfileSheet(
        uid: uid,
        username: username,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
