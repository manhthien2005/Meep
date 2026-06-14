part of 'home_screen.dart';

const Key _homePageViewKey = ValueKey('homePageView');
const Key _homeTopBarKey = ValueKey('homeTopBar');
const Key _homeTaskbarKey = ValueKey('homeTaskbar');

const double _topbarPillAlpha = 0.4;

extension _HomeScreenStateWidgets on _HomeScreenState {
  /// Derive màu ring cho AppTaskbar từ Space đầu tiên trong post hiện tại.
  /// Multi-Space post pick first (visual hint dùng 1 màu).
  Color? get _ringColor {
    if (_currentPage < 1 || _currentPage - 1 >= _posts.length) return null;
    final post = _posts[_currentPage - 1];
    if (post.spaceIds.isEmpty) return null;
    final space = ref.read(spaceByIdProvider(post.spaceIds.first)).valueOrNull;
    if (space == null) return null;
    return hexToColor(space.colorHex);
  }

  /// Camera page (page 0) -> floating pill (hug-width, có active state).
  /// Feed (page >=1) -> embedded full-width với nút grid + share ngoài pill.
  Widget _buildTaskbar(int chatBadgeCount, Color? ringColor) {
    if (_currentPage >= 1) {
      return Padding(
        key: _homeTaskbarKey,
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
          onGridTap: () => context.push('/grid-view'),
          onUploadTap: _onShareTap,
          ringColor: ringColor,
        ),
      );
    }
    return Padding(
      key: _homeTaskbarKey,
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

  Widget _buildPageView(
    List<Post>? posts, {
    bool isLoading = false,
    bool isError = false,
  }) {
    final postCount = (isLoading || isError || posts == null || posts.isEmpty)
        ? 1
        : posts.length;
    final bottomChromePadding =
        AppTaskbar.height + MediaQuery.of(context).size.height * 0.045 + 8;

    return PageView.builder(
      key: _homePageViewKey,
      controller: _pageController,
      scrollDirection: Axis.vertical,
      onPageChanged: _onPageChanged,
      itemCount: 1 + postCount,
      itemBuilder: (context, index) {
        Widget page;
        if (index == 0) {
          page = CameraSection(onGoToFeed: _goToFeed);
        } else if (isLoading) {
          page = const Center(
            child: CircularProgressIndicator(color: AppColors.turquoise500),
          );
        } else if (isError) {
          page = FeedErrorView(
            onRetry: () {
              final sel = ref.read(feedFilterControllerProvider);
              ref.invalidate(
                feedControllerProvider(
                  filter: _filterModeFor(sel),
                  filterUid: sel.authorUid,
                  filterSpaceId: sel.spaceId,
                ),
              );
            },
          );
        } else if (posts == null || posts.isEmpty) {
          page = _EmptyFeedPage(
            onCapture: () => _pageController.jumpToPage(0),
          );
        } else {
          page = _PostPage(post: posts[index - 1]);
        }

        return Padding(
          padding: EdgeInsets.only(bottom: bottomChromePadding),
          child: page,
        );
      },
    );
  }
}

class _HomeTopBar extends ConsumerWidget {
  const _HomeTopBar({
    required this.isFeedMode,
    required this.selectedLabel,
    required this.onFilterSelected,
    required this.onSpaceFilterSelected,
    this.spaceId,
  });

  /// true = viewing feed → show "Mọi người ▾" filter dropdown.
  /// false = camera page → show "N bạn bè" pill that opens the FriendSheet.
  final bool isFeedMode;

  /// Label shown on the filter button ("Mọi người", "Bạn", or a friend name).
  final String selectedLabel;

  /// Called with (authorUid, label). authorUid null = "Mọi người".
  final void Function(String? authorUid, String label) onFilterSelected;

  /// Called khi user chọn Space từ dropdown — set local space filter +
  /// sync currentSpaceProvider cho Camera context.
  final void Function(Space space) onSpaceFilterSelected;

  /// Non-null khi HomeScreen mở qua deeplink `/space/:spaceId`. Topbar
  /// thay slot avatar bằng "..." icon mở [SpaceManagementSheet] (T10b).
  /// Trong Space view, Settings không access trực tiếp từ topbar — user
  /// vẫn vào được qua Profile tab.
  final String? spaceId;

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
      pageBuilder: (_, __, ___) => FeedFilterDropdown(
        currentUid: currentUid,
        selectedLabel: selectedLabel,
        onFilterSelected: onFilterSelected,
        onSpaceFilterSelected: onSpaceFilterSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(currentUidProvider).valueOrNull;
    final friendCount = currentUid == null
        ? 0
        : ref.watch(
            friendControllerProvider(currentUid)
                .select((s) => s.friends.length),
          );

    return Padding(
      key: _homeTopBarKey,
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
          if (spaceId != null)
            Semantics(
              button: true,
              label: 'Quản lý Space',
              child: GestureDetector(
                onTap: () => SpaceManagementSheet.show(context, spaceId!),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.bw700.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.more_horiz,
                    color: AppColors.bw100,
                    size: 22,
                  ),
                ),
              ),
            )
          else
            const AppTopAvatar(),
        ],
      ),
    );
  }

  /// Camera page: pill hiển thị số bạn bè thật.
  /// Tap = mở FriendSheet (Figma). Space context được pick từ AudienceRow ở
  /// CapturePreview thay vì long-press ở camera page.
  Widget _buildFriendCountPill(BuildContext context, int friendCount) {
    final label = friendCount == 0 ? 'Chưa có bạn bè' : '$friendCount bạn bè';
    return GestureDetector(
      onTap: () => _openFriendSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bw700.withValues(alpha: _topbarPillAlpha),
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
          color: AppColors.bw700.withValues(alpha: _topbarPillAlpha),
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

/// Full-screen page render từng post trong PageView. Background đổi theo
/// `post.spaceId.colorHex` — paint ở LEVEL Scaffold (_scaffoldBgColor) thay
/// vì ColoredBox riêng cho từng page, để header pill + footer taskbar
/// (transparent bg) phủ cùng màu space xuyên qua.
class _PostPage extends ConsumerWidget {
  const _PostPage({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(currentUidProvider).valueOrNull;
    return post.authorId == currentUid
        ? OwnPostPage(post: post)
        : FriendPostPage(post: post);
  }
}

class _EmptyFeedPage extends StatelessWidget {
  const _EmptyFeedPage({required this.onCapture});

  /// Đưa user về trang camera (page 0) để chụp ảnh đầu tiên.
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.photo_camera_outlined,
            color: AppColors.bw600,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có ảnh nào',
            style: TextStyle(
              color: AppColors.bw400,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chụp ảnh đầu tiên và gửi cho bạn bè!',
            style: TextStyle(
              color: AppColors.bw600,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: onCapture,
            icon: const Icon(Icons.photo_camera, size: 18),
            label: const Text('Chụp ảnh đầu tiên'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.turquoise500,
            ),
          ),
        ],
      ),
    );
  }
}
