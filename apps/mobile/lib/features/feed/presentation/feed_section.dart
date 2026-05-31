import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/features/feed/data/post.dart';
import 'package:meep/shared/widgets/post_card.dart';
import 'package:meep/shared/widgets/share_modal.dart';

class FeedSection extends ConsumerWidget {
  const FeedSection({super.key, this.filterUid});

  final String? filterUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = filterUid != null ? FeedFilter.person : FeedFilter.all;
    final feedAsync = ref.watch(
      feedControllerProvider(filter: filter, filterUid: filterUid),
    );

    return feedAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.turquoise500),
          ),
        ),
      ),
      error: (_, __) => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Không tải được feed. Kiểm tra kết nối.',
              style: TextStyle(color: AppColors.bw500),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (state) {
        if (state.posts.isEmpty) {
          return const SliverToBoxAdapter(child: _EmptyState());
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= state.posts.length) return const _FeedFooter();

              final post = state.posts[index];

              // Trigger prefetch after frame — never call state mutation during build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref
                    .read(
                      feedControllerProvider(
                        filter: filter,
                        filterUid: filterUid,
                      ).notifier,
                    )
                    .onItemVisible(index);
              });

              final currentUid = FirebaseAuth.instance.currentUser?.uid;
              final isOwn = post.authorId == currentUid;

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: isOwn
                    ? OwnPostCard(post: post)
                    : FriendPostCard(post: post),
              );
            },
            childCount: state.posts.length + 1,
          ),
        );
      },
    );
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return '${diff.inSeconds}s';
  if (diff.inMinutes < 60) return '${diff.inMinutes}p';
  if (diff.inHours < 24) return '${diff.inHours}h';
  return '${diff.inDays}n';
}

class FriendPostCard extends StatelessWidget {
  const FriendPostCard({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return PostCard(
      post: post,
      onLongPress: () => _showShareModal(context, post, isAuthor: false),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthorRow(post: post),
          const SizedBox(height: 8),
          const _ActTextBarStub(),
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
      footer: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn · ${_formatDate(post.createdAt)}',
              style: const TextStyle(
                color: AppColors.bw400,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.bw800,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '✨ Chưa có hoạt động nào!',
                style: TextStyle(
                  color: AppColors.bw300,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return 'hôm nay';
    }
    return '${dt.day}/${dt.month}';
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

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bw700,
              image: post.authorAvatarUrl != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(post.authorAvatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            post.authorName,
            style: const TextStyle(
              color: AppColors.bw100,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _timeAgo(post.createdAt),
            style: const TextStyle(
              color: AppColors.bw500,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActTextBarStub extends StatelessWidget {
  const _ActTextBarStub();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.bw800,
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Row(
          children: [
            Expanded(
              child: Text(
                'Gửi tin nhắn...',
                style: TextStyle(
                  color: AppColors.bw500,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text('💙', style: TextStyle(fontSize: 18)),
            SizedBox(width: 10),
            Text('😂', style: TextStyle(fontSize: 18)),
            SizedBox(width: 10),
            Text('🥰', style: TextStyle(fontSize: 18)),
            SizedBox(width: 10),
            Icon(Icons.add_reaction_outlined, color: AppColors.bw500, size: 20),
          ],
        ),
      ),
    );
  }
}

class _FeedFooter extends StatelessWidget {
  const _FeedFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'Đã hiển thị tất cả',
          style: TextStyle(
            color: AppColors.bw500,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Column(
        children: [
          Icon(Icons.photo_camera_outlined, color: AppColors.bw600, size: 48),
          SizedBox(height: 16),
          Text(
            'Chưa có ảnh nào',
            style: TextStyle(
              color: AppColors.bw400,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'Nunito',
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Chụp ảnh đầu tiên và gửi cho bạn bè!',
            style: TextStyle(
              color: AppColors.bw600,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
