part of 'feed_section.dart';

/// Shared header row used by both own and friend posts. Friend variant shows
/// the avatar + `<name> d thg M`; own variant shows just `Bạn d thg M` (no
/// avatar — the user already sees themselves on every screen, so it would
/// just be visual noise).
class PostHeaderRow extends StatelessWidget {
  const PostHeaderRow({
    super.key,
    required this.post,
    required this.isOwn,
    this.onAvatarTap,
  });

  final Post post;
  final bool isOwn;
  final VoidCallback? onAvatarTap;

  static String _formatDate(DateTime dt) => '${dt.day} thg ${dt.month}';

  @override
  Widget build(BuildContext context) {
    final nameText = isOwn ? 'Bạn' : post.authorName;
    final dateText = ' ${_formatDate(post.createdAt)}';
    final label = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: nameText,
            style: const TextStyle(color: AppColors.bw100),
          ),
          TextSpan(
            text: dateText,
            style: const TextStyle(color: AppColors.bw500),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        fontFamily: 'Nunito',
      ),
    );

    if (isOwn) {
      return Center(child: label);
    }
    final avatar = _AuthorAvatar(
      post: post,
      onTap: onAvatarTap,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        avatar,
        const SizedBox(width: 8),
        Flexible(child: label),
      ],
    );
  }
}

/// Resolves the author's avatar: uses [Post.authorAvatarUrl] when available,
/// otherwise falls back to the author's current Firestore profile avatar.
class _AuthorAvatar extends ConsumerWidget {
  const _AuthorAvatar({required this.post, this.onTap});

  final Post post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ưu tiên authorAvatarUrl từ post (đã có sẵn từ lúc tạo post).
    // Nếu null (post cũ, email signup), lookup từ profile author hiện tại.
    String? avatarUrl = post.authorAvatarUrl;
    if (avatarUrl == null || avatarUrl.isEmpty) {
      avatarUrl =
          ref.watch(_authorAvatarUrlProvider(post.authorId)).valueOrNull;
    }

    final child = AppAvatar(
      imageUrl: avatarUrl,
      size: 28,
      fallbackText:
          post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : null,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: child);
    }
    return child;
  }
}

/// Fetches a user's current avatar URL from their public Firestore profile.
final _authorAvatarUrlProvider =
    FutureProvider.family<String?, String>((ref, uid) async {
  final profile = await ref.read(userRepositoryProvider).getPublicProfile(uid);
  return profile?.avatarUrl;
});

/// Activity pill — own posts only. Two states:
/// - Empty: "Chưa có hoạt động nào!" (M2 fallback khi chưa có react)
/// - Has reactions: "Hoạt động" + stacked avatars + ReactionListSheet on tap
class ActivityPill extends ConsumerWidget {
  const ActivityPill({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reactionControllerProvider(postId));
    final reactions = state.reactions;
    final isEmpty = reactions.isEmpty;

    return GestureDetector(
      onTap: isEmpty ? null : () => ReactionListSheet.show(context, postId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x66252627),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_outlined,
              color: AppColors.bw400,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              isEmpty ? 'Chưa có hoạt động nào!' : 'Hoạt động',
              style: TextStyle(
                color: isEmpty ? AppColors.bw400 : AppColors.bw100,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Nunito',
              ),
            ),
            if (!isEmpty) ...[
              const SizedBox(width: 10),
              _AvatarStack(reactions: reactions),
            ],
          ],
        ),
      ),
    );
  }
}

/// Stacked avatars — max 3 first + "+N" badge if count > 3.
/// Figma 472:2052 node 769:4494.
class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.reactions});

  final List<Reaction> reactions;

  @override
  Widget build(BuildContext context) {
    final top3 = reactions.length <= 3
        ? reactions
        : reactions.sublist(0, 3); // already sorted DESC from State
    final overflow = reactions.length - 3;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final r in top3)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: AppAvatar(
              imageUrl: r.reactorAvatarUrl,
              fallbackText: r.reactorName.isNotEmpty
                  ? r.reactorName[0].toUpperCase()
                  : '?',
              size: 32,
            ),
          ),
        if (overflow > 0)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.bw300,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.bw100, width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              '+$overflow',
              style: const TextStyle(
                color: AppColors.bw700,
                fontSize: 14,
                fontFamily: 'Roboto',
              ),
            ),
          ),
      ],
    );
  }
}
