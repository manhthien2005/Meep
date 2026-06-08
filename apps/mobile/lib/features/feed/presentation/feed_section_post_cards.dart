part of 'feed_section.dart';

class FriendPostCard extends StatelessWidget {
  const FriendPostCard({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return PostCard(
      post: post,
      onLongPress: () => _showShareModal(context, post, isAuthor: false),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PostHeaderRow(
            post: post,
            isOwn: false,
            onAvatarTap: () => context.push('/friend-profile/${post.authorId}'),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: FriendMessageBar(
              postId: post.postId,
              authorId: post.authorId,
              spaceId: post.spaceIds.isEmpty ? null : post.spaceIds.first,
            ),
          ),
        ],
      ),
    );
  }
}

class OwnPostCard extends StatelessWidget {
  const OwnPostCard({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return PostCard(
      post: post,
      onLongPress: () => _showShareModal(context, post, isAuthor: true),
      footer: OwnPostFooter(post: post),
    );
  }
}

/// Author label + activity pill shown under the photo on own posts.
/// Extracted so [OwnPostPage] can position it at the bottom of the screen
/// (separately from the photo).
class OwnPostFooter extends StatelessWidget {
  const OwnPostFooter({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PostHeaderRow(post: post, isOwn: true),
        const SizedBox(height: 12),
        ActivityPill(postId: post.postId),
      ],
    );
  }
}

/// Own post variant for the home PageView: photo near the top, footer
/// (label + activity pill) pinned near the taskbar at ~4% screen height.
/// Used instead of [OwnPostCard] when the post fills a full screen page.
class OwnPostPage extends ConsumerWidget {
  const OwnPostPage({super.key, required this.post});

  final Post post;

  /// Spacing from the bottom of the screen (above the taskbar). Tuned by
  /// product preference; pill should sit just above the nav bar.
  static const double _bottomGapRatio = 0.04;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenH = MediaQuery.sizeOf(context).height;
    final borderColor = _postBorderColor(ref, post);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),
        PostCard(
          post: post,
          borderColor: borderColor,
          onLongPress: () => _showShareModal(context, post, isAuthor: true),
        ),
        const SizedBox(height: 8),
        PostHeaderRow(post: post, isOwn: true),
        const Spacer(),
        ActivityPill(postId: post.postId),
        SizedBox(height: screenH * _bottomGapRatio),
      ],
    );
  }
}

/// Friend post variant for the home PageView. Mirrors [OwnPostPage] so both
/// post types share the same vertical rhythm and horizontal gutters: photo
/// on top, header + message bar pinned at ~4% above the taskbar.
class FriendPostPage extends ConsumerWidget {
  const FriendPostPage({super.key, required this.post});

  final Post post;

  static const double _bottomGapRatio = 0.04;
  static const double _gutter = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenH = MediaQuery.sizeOf(context).height;
    final borderColor = _postBorderColor(ref, post);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),
        PostCard(
          post: post,
          borderColor: borderColor,
          onLongPress: () => _showShareModal(context, post, isAuthor: false),
        ),
        const SizedBox(height: 8),
        PostHeaderRow(
          post: post,
          isOwn: false,
          onAvatarTap: () => context.push('/friend-profile/${post.authorId}'),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _gutter),
          child: FriendMessageBar(
            postId: post.postId,
            authorId: post.authorId,
            spaceId: post.spaceIds.isEmpty ? null : post.spaceIds.first,
          ),
        ),
        SizedBox(height: screenH * _bottomGapRatio),
      ],
    );
  }
}

void _showShareModal(
  BuildContext context,
  Post post, {
  required bool isAuthor,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => ShareModal(post: post, isAuthor: isAuthor),
  );
}

/// Derive border color cho PostCard từ Space đầu tiên trong post.spaceIds.
/// Trả null khi post không thuộc Space nào hoặc Space chưa load. Pick first
/// (post có thể gửi multi-Space nhưng visual hint dùng 1 màu).
Color? _postBorderColor(WidgetRef ref, Post post) {
  if (post.spaceIds.isEmpty) return null;
  final space = ref.watch(spaceByIdProvider(post.spaceIds.first)).valueOrNull;
  if (space == null) return null;
  return hexToColor(space.colorHex);
}
