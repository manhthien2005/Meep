import 'package:flutter/material.dart';

// TODO(C/T6/TBD): implement GroupChatScreen per Figma — Space group chat
class GroupChatScreen extends StatelessWidget {
  const GroupChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.shrink());
}
