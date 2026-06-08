import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/shared/models/post.dart';

part 'profile_posts_provider.g.dart';

/// Posts của một user — load qua `PostRepository.getPostsByAuthor` (feed module),
/// sort `createdAt` DESC (mới → cũ) ngay tại boundary để UI consume nguyên list.
///
/// MVP scope: load tất cả posts (no cursor pagination). Spec T4 yêu cầu cursor
/// 9/batch — defer cho đến khi user > 100 posts trở thành issue thực.
/// Reuse cho ProfileScreen (own posts) + FriendProfileScreen (friend posts).
///
/// Note: provider không `keepAlive` → auto-dispose khi không widget watch
/// để tránh stale data sau khi user post mới. Caller có thể `ref.invalidate`
/// để force reload.
@riverpod
Future<List<Post>> profilePosts(Ref ref, String uid) async {
  final posts = await ref.read(postRepositoryProvider).getPostsByAuthor(uid);
  // PostRepository.getPostsByAuthor already orders by createdAt desc, but
  // re-sort defensively for any in-memory impl divergence.
  final sorted = [...posts]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return sorted;
}
