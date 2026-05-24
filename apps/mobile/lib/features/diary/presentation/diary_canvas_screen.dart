import 'package:flutter/material.dart';

/// Mode of the diary canvas screen.
enum DiaryCanvasMode { create, read, edit }

// TODO(D/T7/TBD): implement DiaryCanvasScreen per Figma — canvas editor/viewer
class DiaryCanvasScreen extends StatelessWidget {
  const DiaryCanvasScreen({
    super.key,
    required this.mode,
    this.entryId,
  });

  final DiaryCanvasMode mode;
  final String? entryId;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}
