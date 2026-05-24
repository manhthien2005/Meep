import 'package:flutter/material.dart';

// TODO(R/T3/TBD): implement EmojiPickerSheet per Figma
class EmojiPickerSheet extends StatelessWidget {
  const EmojiPickerSheet({super.key, required this.onEmojiSelected});

  final ValueChanged<String> onEmojiSelected;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
