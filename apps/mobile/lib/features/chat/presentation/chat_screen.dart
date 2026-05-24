import 'package:flutter/material.dart';

// TODO(C/T5/TBD): implement ChatScreen per Figma — 1-1 direct chat
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.shrink());
}
