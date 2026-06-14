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
import 'package:meep/features/feed/presentation/camera_section.dart';
import 'package:meep/features/feed/presentation/feed_filter_dropdown.dart';
import 'package:meep/features/feed/presentation/feed_section.dart';
import 'package:meep/features/feed/presentation/widgets/feed_error_view.dart';
import 'package:meep/features/friend/application/friend_controller.dart';
import 'package:meep/features/friend/presentation/friend_sheet.dart';
import 'package:meep/features/space/application/space_controller.dart';
import 'package:meep/features/space/data/space.dart';
import 'package:meep/features/space/presentation/space_management_sheet.dart';
import 'package:meep/shared/models/post.dart';
import 'package:meep/shared/widgets/app_avatar.dart';
import 'package:meep/shared/widgets/app_taskbar.dart';

part 'home_screen_widgets.dart';

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

  // TODO(Feed/KhoaLND): wire luồng chia sẻ — nút phải embedded là nút share,
  // chưa chốt đích đến.
  void _onShareTap() {}

  @override
  Widget build(BuildContext context) {
    final filterSelection = ref.watch(feedFilterControllerProvider);
    final filterMode = _filterModeFor(filterSelection);

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
      body: Stack(
        children: [
          Positioned.fill(
            child: feedAsync.when(
              loading: () => _buildPageView(null, isLoading: true),
              error: (e, st) => _buildPageView(null, isError: true),
              data: (state) {
                _posts = state.posts;
                return _buildPageView(state.posts);
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: _HomeTopBar(
                isFeedMode: _currentPage >= 1,
                selectedLabel: filterSelection.label,
                onFilterSelected: _onFilterSelected,
                onSpaceFilterSelected: _onSpaceFilterSelected,
                spaceId: widget.spaceId,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: _buildTaskbar(totalUnread, _ringColor),
            ),
          ),
        ],
      ),
    );
  }
}
