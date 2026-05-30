import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/features/feed/application/app_camera_controller.dart';
import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/features/feed/data/post.dart';
import 'package:meep/features/feed/presentation/camera_section.dart';
import 'package:meep/features/feed/presentation/feed_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.spaceId});

  final String? spaceId;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToFeed() {
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _onPageChanged(int index) {
    final notifier = ref.read(appCameraControllerProvider.notifier);
    if (index == 0) {
      notifier.resumePreview();
    } else {
      notifier.stopPreview();
      ref
          .read(
            feedControllerProvider(
              filter: _filter,
              filterUid: widget.spaceId,
            ).notifier,
          )
          .onItemVisible(index - 1);
    }
  }

  FeedFilter get _filter =>
      widget.spaceId != null ? FeedFilter.person : FeedFilter.all;

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(
      feedControllerProvider(filter: _filter, filterUid: widget.spaceId),
    );

    return Scaffold(
      backgroundColor: AppColors.bw900,
      body: SafeArea(
        child: Column(
          children: [
            const _HomeTopBar(),
            Expanded(
              child: feedAsync.when(
                loading: () => _buildPageView(null, isLoading: true),
                error: (_, __) => _buildPageView(null, isError: true),
                data: (state) => _buildPageView(state.posts),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageView(
    List<Post>? posts, {
    bool isLoading = false,
    bool isError = false,
  }) {
    final postCount = (isLoading || isError || posts == null || posts.isEmpty)
        ? 1
        : posts.length;

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      onPageChanged: _onPageChanged,
      itemCount: 1 + postCount,
      itemBuilder: (context, index) {
        if (index == 0) return CameraSection(onGoToFeed: _goToFeed);
        if (isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.turquoise500),
          );
        }
        if (isError) {
          return const Center(
            child: Text(
              'Không tải được feed. Kiểm tra kết nối.',
              style: TextStyle(color: AppColors.bw500),
              textAlign: TextAlign.center,
            ),
          );
        }
        if (posts == null || posts.isEmpty) return const _EmptyFeedPage();
        return _PostPage(post: posts[index - 1]);
      },
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 36),
          const Spacer(),
          // TODO(Friend/KhoaLND): replace with real friend count from FriendRepository
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.bw800,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '15 người bạn',
                style: TextStyle(
                  color: AppColors.bw100,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const Spacer(),
          // TODO(Settings/KhoaLND): navigate to settings route on tap
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bw700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostPage extends StatelessWidget {
  const _PostPage({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: post.authorId == currentUid
            ? OwnPostCard(post: post)
            : FriendPostCard(post: post),
      ),
    );
  }
}

class _EmptyFeedPage extends StatelessWidget {
  const _EmptyFeedPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
