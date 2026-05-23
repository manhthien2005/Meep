import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/chat/application/chat_providers.dart';
import 'package:meep/features/feed/application/app_camera_controller.dart';
import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/features/feed/data/post.dart';
import 'package:meep/features/feed/presentation/camera_section.dart';
import 'package:meep/features/feed/presentation/feed_section.dart';
import 'package:meep/features/friend/application/friend_controller.dart';
import 'package:meep/features/friend/presentation/friend_sheet.dart';
import 'package:meep/features/space/presentation/space_context_bottom_sheet.dart';
import 'package:meep/shared/widgets/app_avatar.dart';
import 'package:meep/shared/widgets/app_taskbar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.spaceId});

  final String? spaceId;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController _pageController;

  /// Current vertical page: 0 = camera, >=1 = feed posts.
  /// Drives the topbar mode (friend count on camera, filter on feed).
  int _currentPage = 0;

  /// Selected feed filter on the home topbar.
  /// null = "Mọi người" (all friends' feed). Otherwise filter by this author
  /// uid: currentUid = "Bạn" (own posts), or a friend's uid.
  String? _selectedAuthorUid;
  String _selectedLabel = 'Mọi người';

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
    setState(() => _currentPage = index);
    final notifier = ref.read(appCameraControllerProvider.notifier);
    if (index == 0) {
      notifier.resumePreview();
    } else {
      notifier.stopPreview();
      ref
          .read(
            feedControllerProvider(
              filter: _filter,
              filterUid: _activeFilterUid,
              filterSpaceId: widget.spaceId,
            ).notifier,
          )
          .onItemVisible(index - 1);
    }
  }

  /// Feed filter derived from topbar selector + space context.
  /// Space context (Bước 2) takes precedence; otherwise the selector chooses
  /// between "Mọi người" (all) and a specific author (person).
  FeedFilter get _filter {
    if (widget.spaceId != null) return FeedFilter.space;
    return _selectedAuthorUid != null ? FeedFilter.person : FeedFilter.all;
  }

  /// Author uid passed to [FeedFilter.person]. Null in space/all modes.
  String? get _activeFilterUid =>
      widget.spaceId != null ? null : _selectedAuthorUid;

  void _onFilterSelected(String? authorUid, String label) {
    setState(() {
      _selectedAuthorUid = authorUid;
      _selectedLabel = label;
    });
    // Jump back to the camera page so the freshly filtered feed loads cleanly.
    _pageController.jumpToPage(0);
  }

  /// Taskbar tab → navigate. Home tab cuộn về trang camera (page 0) thay vì
  /// push route mới (đang ở /home rồi). Các tab khác đẩy sang route tương ứng.
  void _onTaskbarTab(TaskbarTab tab) {
    switch (tab) {
      case TaskbarTab.home:
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      case TaskbarTab.streak:
        context.go('/streak');
      case TaskbarTab.diary:
        context.go('/diary');
      case TaskbarTab.chat:
        context.go('/inbox');
      case TaskbarTab.profile:
        context.go('/profile', extra: ref.read(currentUidProvider).valueOrNull);
    }
  }

  // TODO(Feed/KhoaLND): wire luồng chia sẻ — nút phải embedded là nút share,
  // chưa chốt đích đến.
  void _onShareTap() {}

  /// Camera page (page 0) -> floating pill (hug-width, có active state).
  /// Feed (page >=1) -> embedded full-width với nút grid + share ngoài pill.
  Widget _buildTaskbar(int chatBadgeCount) {
    if (_currentPage >= 1) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).size.height * 0.04,
        ),
        child: AppTaskbar(
          variant: TaskbarVariant.embedded,
          activeTab: TaskbarTab.home,
          chatBadgeCount: chatBadgeCount,
          onTabSelected: _onTaskbarTab,
          onGridTap: () => context.go('/grid-view'),
          onUploadTap: _onShareTap,
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height * 0.045,
      ),
      child: Center(
        child: AppTaskbar(
          activeTab: TaskbarTab.home,
          chatBadgeCount: chatBadgeCount,
          onTabSelected: _onTaskbarTab,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(
      feedControllerProvider(
        filter: _filter,
        filterUid: _activeFilterUid,
        filterSpaceId: widget.spaceId,
      ),
    );

    final unreadCounts = ref.watch(unreadCountsProvider);
    final totalUnread =
        unreadCounts.values.fold<int>(0, (sum, val) => sum + val);

    return Scaffold(
      backgroundColor: AppColors.bw900,
      body: SafeArea(
        child: Column(
          children: [
            _HomeTopBar(
              isFeedMode: _currentPage >= 1,
              selectedLabel: _selectedLabel,
              onFilterSelected: _onFilterSelected,
            ),
            Expanded(
              child: feedAsync.when(
                loading: () => _buildPageView(null, isLoading: true),
                error: (_, __) => _buildPageView(null, isError: true),
                data: (state) => _buildPageView(state.posts),
              ),
            ),
            _buildTaskbar(totalUnread),
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

class _HomeTopBar extends ConsumerWidget {
  const _HomeTopBar({
    required this.isFeedMode,
    required this.selectedLabel,
    required this.onFilterSelected,
  });

  /// true = viewing feed → show "Mọi người ▾" filter dropdown.
  /// false = camera page → show "N bạn bè" pill that opens the FriendSheet.
  final bool isFeedMode;

  /// Label shown on the filter button ("Mọi người", "Bạn", or a friend name).
  final String selectedLabel;

  /// Called with (authorUid, label). authorUid null = "Mọi người".
  final void Function(String? authorUid, String label) onFilterSelected;

  void _openFriendSheet(BuildContext context) {
    // Modal sheet đồng bộ với các sheet khác (kéo xuống để đóng, tap barrier
    // để đóng). FriendSheet render AppBottomSheet bên trong.
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x73000000),
      builder: (_) => const FriendSheet(),
    );
  }

  Future<void> _openFilterDropdown(
    BuildContext context,
    String currentUid,
  ) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Đóng bộ lọc',
      barrierColor: const Color(0x73000000),
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (_, __, ___) => _FeedFilterDropdown(
        currentUid: currentUid,
        selectedLabel: selectedLabel,
        onFilterSelected: onFilterSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(currentUidProvider).valueOrNull;
    final avatarUrl =
        ref.watch(currentUserProfileProvider).valueOrNull?.avatarUrl;
    final friendCount = currentUid == null
        ? 0
        : ref.watch(friendControllerProvider(currentUid)).friends.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 40),
          const Spacer(),
          if (isFeedMode)
            _buildFilterButton(context, currentUid)
          else
            _buildFriendCountPill(context, friendCount),
          const Spacer(),
          GestureDetector(
            onTap: () => _openFriendSheet(context),
            child: AppAvatar(
              imageUrl: avatarUrl,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  /// Camera page: pill hiển thị số bạn bè thật.
  /// - Tap = mở FriendSheet (Figma).
  /// - Long-press = mở SpaceContextBottomSheet để đổi Camera context
  ///   (gửi cho All friends hay 1 Space cụ thể). Per Space spec T4.
  Widget _buildFriendCountPill(BuildContext context, int friendCount) {
    final label = friendCount == 0 ? 'Chưa có bạn bè' : '$friendCount bạn bè';
    return GestureDetector(
      onTap: () => _openFriendSheet(context),
      onLongPress: () => SpaceContextBottomSheet.show(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bw700.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/ic_user_round.svg',
              width: 18,
              height: 18,
              colorFilter: const ColorFilter.mode(
                AppColors.bw100,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.mdBold.copyWith(color: AppColors.bw100),
            ),
          ],
        ),
      ),
    );
  }

  /// Feed page: "Mọi người ▾" mở dropdown lọc theo người đăng.
  Widget _buildFilterButton(BuildContext context, String? currentUid) {
    return GestureDetector(
      onTap: currentUid == null
          ? null
          : () => _openFilterDropdown(context, currentUid),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bw700.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedLabel,
              style: AppTextStyles.mdBold.copyWith(color: AppColors.bw100),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.bw200,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// Feed filter dropdown — "Mọi người" / "Bạn" / per-friend.
/// Mirrors Figma "ListFriend" (269:1667): rounded card, dark rows with dividers.
/// TODO(Friend/KhoaLND): thêm danh sách Space khi watchSpaceFeed sẵn sàng (Bước 2).
class _FeedFilterDropdown extends ConsumerWidget {
  const _FeedFilterDropdown({
    required this.currentUid,
    required this.selectedLabel,
    required this.onFilterSelected,
  });

  final String currentUid;
  final String selectedLabel;
  final void Function(String? authorUid, String label) onFilterSelected;

  void _select(BuildContext context, String? authorUid, String label) {
    Navigator.of(context).pop();
    onFilterSelected(authorUid, label);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendControllerProvider(currentUid)).friends;
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 265,
            decoration: BoxDecoration(
              color: AppColors.bw600,
              borderRadius: BorderRadius.circular(25),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FilterRow(
                  label: 'Mọi người',
                  leading: _iconCircle('assets/icons/ic_users_round.svg'),
                  onTap: () => _select(context, null, 'Mọi người'),
                ),
                _FilterRow(
                  label: 'Bạn',
                  leading: AppAvatar(
                    imageUrl: profile?.avatarUrl,
                    size: 25,
                    fallbackText: (profile?.displayName.isNotEmpty ?? false)
                        ? profile!.displayName[0].toUpperCase()
                        : null,
                  ),
                  onTap: () => _select(context, currentUid, 'Bạn'),
                ),
                ...friends.map(
                  (friend) => _FilterRow(
                    label: friend.displayName,
                    leading: AppAvatar(
                      imageUrl: friend.avatarUrl,
                      size: 25,
                      fallbackText: friend.displayName.isNotEmpty
                          ? friend.displayName[0].toUpperCase()
                          : null,
                    ),
                    onTap: () => _select(
                      context,
                      friend.uid,
                      friend.displayName,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconCircle(String iconPath) {
    return Container(
      width: 25,
      height: 25,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bw600,
      ),
      padding: const EdgeInsets.all(6),
      child: SvgPicture.asset(
        iconPath,
        colorFilter: const ColorFilter.mode(AppColors.bw100, BlendMode.srcIn),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.label,
    required this.leading,
    required this.onTap,
  });

  final String label;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.bw700,
          border: Border(
            bottom: BorderSide(color: AppColors.bw800),
          ),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.mdBold.copyWith(color: AppColors.bw100),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.bw500,
              size: 20,
            ),
          ],
        ),
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
