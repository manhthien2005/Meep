import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/core/theme/hex_color.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/chat/application/chat_providers.dart';
import 'package:meep/features/feed/application/app_camera_controller.dart';
import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/features/feed/application/feed_filter_controller.dart';
import 'package:meep/features/feed/data/post.dart';
import 'package:meep/features/feed/presentation/camera_section.dart';
import 'package:meep/features/feed/presentation/feed_filter_dropdown.dart';
import 'package:meep/features/feed/presentation/feed_section.dart';
import 'package:meep/features/friend/application/friend_controller.dart';
import 'package:meep/features/friend/presentation/friend_sheet.dart';
import 'package:meep/features/settings/presentation/settings_sheet.dart';
import 'package:meep/features/space/application/space_controller.dart';
import 'package:meep/features/space/data/space.dart';
import 'package:meep/features/space/presentation/space_management_sheet.dart';
import 'package:meep/shared/widgets/app_avatar.dart';
import 'package:meep/shared/widgets/app_taskbar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    this.spaceId,
    this.highlightPostId,
    this.openFriendSheet = false,
  });

  final String? spaceId;
  final String? highlightPostId;

  /// Set true when navigated from a friend_request / friend_accepted push
  /// (T4 deep link). HomeScreen auto-opens the FriendSheet once after
  /// mount, then clears the pending flag.
  final bool openFriendSheet;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController _pageController;

  /// Current vertical page: 0 = camera, >=1 = feed posts.
  /// Drives the topbar mode (friend count on camera, filter on feed).
  int _currentPage = 0;

  /// Cache posts list để derive ringColor + bg space cho taskbar.
  List<Post> _posts = [];

  /// Widget-tap deeplink target — postId cần scroll tới khi feed có data.
  /// Set từ `widget.highlightPostId` ở initState/didUpdateWidget, clear ngay
  /// sau khi handle xong (animate hoặc fallback toast) để không re-fire khi
  /// rebuild vì lý do khác.
  String? _pendingHighlightPostId;

  /// Notification deep link target — set khi route mở với
  /// `?openFriendSheet=1` (friend_request / friend_accepted push). Cleared
  /// ngay sau khi showModalBottomSheet để rebuild kế tiếp không mở thêm
  /// sheet thứ hai.
  bool _pendingOpenFriendSheet = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pendingHighlightPostId = widget.highlightPostId;
    _pendingOpenFriendSheet = widget.openFriendSheet;

    // Deeplink `/space/:spaceId` → seed provider sau frame đầu (provider
    // chưa thể mutate inside initState — ref.read OK nhưng convention
    // post-frame). Deeplink luôn thắng provider state cũ. Label dùng
    // placeholder "Space" — sẽ được sync về tên thật khi spaceById emit.
    final routeSpaceId = widget.spaceId;
    if (routeSpaceId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(feedFilterControllerProvider.notifier).seedFromRoute(
              spaceId: routeSpaceId,
              label: 'Space',
            );
      });
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Warm start: cùng HomeScreen instance, GoRouter chỉ update query param
    // → re-arm pending khi postId thay đổi (kể cả từ non-null sang null
    // mình bỏ qua).
    if (widget.highlightPostId != null &&
        widget.highlightPostId != oldWidget.highlightPostId) {
      _pendingHighlightPostId = widget.highlightPostId;
    }
    if (widget.openFriendSheet && !oldWidget.openFriendSheet) {
      _pendingOpenFriendSheet = true;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Scroll PageView tới page chứa [postId] (page 0 = camera, page i+1 =
  /// posts[i]). Nếu không tìm thấy → snackbar fallback "Khoảnh khắc này
  /// không còn tồn tại".
  void _handleHighlight(String postId, List<Post> posts) {
    if (!mounted) return;
    final index = posts.indexWhere((p) => p.postId == postId);
    if (index < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Khoảnh khắc này không còn tồn tại')),
      );
      return;
    }
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index + 1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
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
    final filterSelection = ref.read(feedFilterControllerProvider);
    final filterMode = _filterModeFor(filterSelection);
    if (index == 0) {
      notifier.resumePreview();
    } else {
      notifier.stopPreview();
      ref
          .read(
            feedControllerProvider(
              filter: filterMode,
              filterUid: filterSelection.authorUid,
              filterSpaceId: filterSelection.spaceId,
            ).notifier,
          )
          .onItemVisible(index - 1);
    }
  }

  /// Derive FeedFilter mode từ selection state. spaceId thắng authorUid
  /// (mutually exclusive trong selection, đề phòng future state changes).
  FeedFilter _filterModeFor(FeedFilterSelection selection) {
    if (selection.spaceId != null) return FeedFilter.space;
    if (selection.authorUid != null) return FeedFilter.person;
    return FeedFilter.all;
  }

  void _onFilterSelected(String? authorUid, String label) {
    final notifier = ref.read(feedFilterControllerProvider.notifier);
    if (authorUid == null) {
      notifier.selectAll();
    } else {
      notifier.selectAuthor(authorUid, label);
    }
    // Jump back to the camera page so the freshly filtered feed loads cleanly.
    _pageController.jumpToPage(0);
  }

  /// Khi user chọn 1 Space từ dropdown — set filter provider + sync
  /// `currentSpaceProvider` để Camera page biết context Space (badge
  /// "Đang gửi: [name]" + viền camera theo colorHex).
  void _onSpaceFilterSelected(Space space) {
    ref.read(feedFilterControllerProvider.notifier).selectSpace(space);
    ref.read(currentSpaceProvider.notifier).select(space);
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

  // TODO(Feed/KhoaLND): wire luồng chia sẻ — nút phải embedded là nút share,
  // chưa chốt đích đến.
  void _onShareTap() {}

  /// Camera page (page 0) -> floating pill (hug-width, có active state).
  /// Feed (page >=1) -> embedded full-width với nút grid + share ngoài pill.
  Widget _buildTaskbar(int chatBadgeCount, Color? ringColor) {
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
          ringColor: ringColor,
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
    final filterSelection = ref.watch(feedFilterControllerProvider);
    final filterMode = _filterModeFor(filterSelection);

    // [DEBUG/Space Feed] Log mỗi lần HomeScreen rebuild với filter mới.
    // Anh đối chiếu thứ tự: FilterController log → HomeScreen log → FeedController log → Repo log.
    debugPrint(
      '[Space Feed] HomeScreen build — mode=$filterMode, '
      'authorUid=${filterSelection.authorUid}, '
      'spaceId=${filterSelection.spaceId}, label="${filterSelection.label}"',
    );

    final feedAsync = ref.watch(
      feedControllerProvider(
        filter: filterMode,
        filterUid: filterSelection.authorUid,
        filterSpaceId: filterSelection.spaceId,
      ),
    );

    // Widget deeplink → scroll tới post khi feed có data. Defer 1 frame để
    // PageController kịp attach vào PageView.builder bên dưới. whenData chạy
    // sync nếu feed đã cache; nếu chưa, rebuild kế tiếp (khi stream emit)
    // sẽ hit lại nhánh này.
    if (_pendingHighlightPostId != null) {
      feedAsync.whenData((feedState) {
        final pendingId = _pendingHighlightPostId!;
        _pendingHighlightPostId = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleHighlight(pendingId, feedState.posts);
        });
      });
    }

    // Notification deep link (friend_request / friend_accepted) → auto-open
    // FriendSheet. Independent of feed loading state — clear pending
    // synchronously so this branch only fires once per arrival.
    if (_pendingOpenFriendSheet) {
      _pendingOpenFriendSheet = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: const Color(0x73000000),
          builder: (_) => const FriendSheet(),
        );
      });
    }

    final unreadCounts = ref.watch(unreadCountsProvider);
    final totalUnread =
        unreadCounts.values.fold<int>(0, (sum, val) => sum + val);

    return Scaffold(
      backgroundColor: AppColors.bw900,
      // Khi mở composer sheet để reply post, keyboard appear → nếu Scaffold
      // tự resize, PageView shrunk làm FriendPostPage Column tràn (overflow
      // 314px) và embedded taskbar bị đẩy lên trên keyboard che modal sheet
      // TextField. Sheet đã tự lift bằng MediaQuery.viewInsets — Scaffold
      // không cần can thiệp.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            _HomeTopBar(
              isFeedMode: _currentPage >= 1,
              selectedLabel: filterSelection.label,
              onFilterSelected: _onFilterSelected,
              onSpaceFilterSelected: _onSpaceFilterSelected,
              spaceId: widget.spaceId,
            ),
            Expanded(
              child: feedAsync.when(
                loading: () => _buildPageView(null, isLoading: true),
                error: (e, st) {
                  // [DEBUG/Space Feed] Đây là chỗ UI hiển thị "Không tải
                  // được feed". Log error cuối cùng + stacktrace để anh
                  // thấy rõ trong terminal.
                  debugPrint(
                    '[Space Feed] HomeScreen render ERROR state — '
                    'mode=$filterMode, spaceId=${filterSelection.spaceId}, error=$e',
                  );
                  debugPrint('[Space Feed] Stacktrace UI: $st');
                  return _buildPageView(null, isError: true);
                },
                data: (state) {
                  debugPrint(
                    '[Space Feed] HomeScreen render DATA state — '
                    'mode=$filterMode, posts=${state.posts.length}',
                  );
                  _posts = state.posts;
                  return _buildPageView(state.posts);
                },
              ),
            ),
            _buildTaskbar(totalUnread, _ringColor),
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
            Semantics(
              button: true,
              label: 'Cài đặt',
              child: GestureDetector(
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const SettingsSheet(),
                ),
                child: AppAvatar(
                  imageUrl: avatarUrl,
                  size: 40,
                ),
              ),
            ),
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
          color: AppColors.bw700.withValues(alpha: 0.08),
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
          color: AppColors.bw700.withValues(alpha: 0.08),
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
class _PostPage extends StatelessWidget {
  const _PostPage({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return post.authorId == currentUid
        ? OwnPostPage(post: post)
        : FriendPostPage(post: post);
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
