import 'package:flutter/material.dart';

// TODO(P/T7/HanDHG): implement FriendProfileScreen per Figma — friend's profile view
// Shows: avatar + stats (postCount + friendCount only; spaceCount hidden) + bio + photo grid
// Photo grid: only posts shared with the current viewer (audienceType == 'all' OR
//   audienceType == 'select' && audienceUids.contains(currentUid))
// No Edit / Share buttons — read-only. "Xoá bạn" navigates to FriendSheet.
class FriendProfileScreen extends StatelessWidget {
  const FriendProfileScreen({super.key, required this.uid});

  /// UID of the friend whose profile is being viewed.
  final String uid;

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.shrink());
}
