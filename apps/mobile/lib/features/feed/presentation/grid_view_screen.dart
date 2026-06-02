import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_proportions.dart';
import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/features/feed/data/post.dart';
import 'package:meep/features/feed/presentation/feed_section.dart';
import 'package:meep/features/feed/presentation/grid_photo_tile.dart';
import 'package:meep/shared/widgets/share_modal.dart';

class GridViewScreen extends ConsumerWidget {
  const GridViewScreen({super.key, this.filterUid});

  final String? filterUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = filterUid != null ? FeedFilter.person : FeedFilter.all;
    final feedAsync = ref.watch(
      feedControllerProvider(filter: filter, filterUid: filterUid),
    );

    return Scaffold(
      backgroundColor: AppColors.bw900,
      body: SafeArea(
        child: Column(
          children: [
            const _TopBar(),
            Expanded(
              child: feedAsync.when(
                loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.turquoise500),
                ),
                error: (_, __) => const Center(
                  child: Text(
                    'Không tải được ảnh',
                    style: TextStyle(color: AppColors.bw500),
                  ),
                ),
                data: (state) => state.posts.isEmpty
                    ? const Center(
                        child: Text(
                          'Chưa có ảnh',
                          style: TextStyle(color: AppColors.bw500),
                        ),
                      )
                    : _Grid(posts: state.posts),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.posts});

  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    return GridView.builder(
      padding: EdgeInsets.all(AppProportions.gridHPadding(screenW)),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppProportions.gridColumns,
        crossAxisSpacing: AppProportions.gridGap,
        mainAxisSpacing: AppProportions.gridGap,
      ),
      itemCount: posts.length,
      itemBuilder: (_, i) => GridPhotoTile(
        post: posts[i],
        onTap: () => _showDetail(context, posts[i]),
      ),
    );
  }

  void _showDetail(BuildContext context, Post post) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostDetailSheet(post: post),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back, color: AppColors.bw100),
          ),
          const Spacer(),
          // TODO(Friend/KhoaLND): FriendsButton filter dropdown
          const Text(
            'Mọi người ▾',
            style: TextStyle(
              color: AppColors.bw100,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFamily: 'Nunito',
            ),
          ),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bw700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostDetailSheet extends StatelessWidget {
  const _PostDetailSheet({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bw900,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: ctrl,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.bw600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              post.authorId == currentUid
                  ? OwnPostCard(post: post)
                  : FriendPostCard(post: post),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ShareModal(
                        post: post,
                        isAuthor: post.authorId == currentUid,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bw800,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.ios_share, color: AppColors.bw100, size: 18),
                      SizedBox(width: 8),
                      Text('Chia sẻ', style: TextStyle(color: AppColors.bw100)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
