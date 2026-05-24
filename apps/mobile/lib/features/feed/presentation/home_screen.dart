import 'package:flutter/material.dart';

// TODO(FE/T13/KhoaLND): implement HomeScreen per Figma — camera + feed CustomScrollView
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.spaceId});

  /// When set: show Space feed (FeedFilter.space). Null = All-friends feed.
  final String? spaceId;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: CustomScrollView(slivers: []),
    );
  }
}
