import 'package:flutter/material.dart';

// TODO(P/T8/TBD): implement PhotoDetailScreen per Figma — full-screen own photo
class PhotoDetailScreen extends StatelessWidget {
  const PhotoDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.shrink());
}
