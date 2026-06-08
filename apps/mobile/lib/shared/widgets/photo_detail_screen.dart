import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/shared/models/post.dart';
import 'package:meep/shared/widgets/share_photo_sheet.dart';

/// Full-screen photo viewer with PageView swipe + thumbnail strip.
///
/// Shared widget — reused bởi:
/// - Profile module: docs/specs/2026-05-22-profile.md §Photo detail
/// - Streak module: docs/specs/2026-05-22-streak.md §Streak_2
///
/// Behavior:
/// - Swipe trái = ảnh cũ hơn (createdAt nhỏ hơn); swipe phải = ảnh mới hơn
/// - Caption: pill OVERLAY trên ảnh (chỉ khi non-null), bg [captionPillColor]
/// - Time: hiển thị riêng dưới ảnh ("17:03"), color [timeColor]
/// - Date format Vietnamese ("Ngày 1 tháng 5")
class PhotoDetailScreen extends StatefulWidget {
  const PhotoDetailScreen({
    super.key,
    required this.postId,
    this.initialIndex = 0,
    this.posts,
    this.captionPillColor = const Color(0x80000000),
    this.timeColor = AppColors.bw100,
    this.onShareTap,
    this.borderColorFor,
  });

  final String postId;
  final int initialIndex;

  /// Posts list (already sorted createdAt DESC). Null = empty list → navigate
  /// back immediately. Caller phải pass danh sách thật.
  final List<Post>? posts;

  /// Caption pill background color.
  /// Default: black 50% (Profile spec). Streak override: `Color(0x66394041)`.
  final Color captionPillColor;

  /// Time tag text color.
  /// Default: BW100 (Profile spec). Streak override: `AppColors.bw600`.
  final Color timeColor;

  /// Share button tap handler. Default: open [SharePhotoSheet] với
  /// `isAuthor: true`. Pass override để customize behavior per caller.
  final ValueChanged<Post>? onShareTap;

  /// Per-post border color resolver. Gọi với post hiện tại + ref để caller
  /// có thể watch provider (vd `spaceByIdProvider` cho Space post). Return
  /// `null` = no border cho post đó. `null` callback = no border bao giờ.
  /// Pattern match [AppPhotoFrame] cho consistency với feed home.
  final Color? Function(Post post, WidgetRef ref)? borderColorFor;

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  late final PageController _pageController;
  late final ScrollController _thumbnailController;
  late int _currentIndex;

  static const double _thumbSize = 40.0;
  static const double _thumbActiveSize = 52.0;
  static const double _thumbGap = 8.0;
  static const double _listPadding = 16.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 0.92,
    );
    _thumbnailController = ScrollController();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollThumbToCenter(_currentIndex));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _scrollThumbToCenter(index);
  }

  // Scroll thumbnail strip so active thumb is centered in viewport
  void _scrollThumbToCenter(int index) {
    if (!_thumbnailController.hasClients) return;
    final viewportWidth = _thumbnailController.position.viewportDimension;
    final centerOfThumb =
        _listPadding + index * (_thumbSize + _thumbGap) + _thumbActiveSize / 2;
    final targetOffset = centerOfThumb - viewportWidth / 2;
    final maxOffset = _thumbnailController.position.maxScrollExtent;
    _thumbnailController.animateTo(
      targetOffset.clamp(0.0, maxOffset),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _handleShare(Post post) {
    final handler = widget.onShareTap;
    if (handler != null) {
      handler(post);
      return;
    }
    // Default: open SharePhotoSheet với isAuthor=true (Profile behavior:
    // chỉ user xem ảnh của mình mới mở Photo detail).
    SharePhotoSheet.show(context, post: post, isAuthor: true);
  }

  @override
  Widget build(BuildContext context) {
    final posts = widget.posts ?? const <Post>[];
    if (posts.isEmpty) {
      // Defensive: route param missing → graceful back navigation.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      });
      return const Scaffold(
        backgroundColor: AppColors.bw900,
        body: SizedBox.shrink(),
      );
    }

    final currentPost = posts[_currentIndex.clamp(0, posts.length - 1)];
    return Scaffold(
      backgroundColor: AppColors.bw900,
      body: SafeArea(
        child: Column(
          children: [
            _Topbar(
              year: currentPost.createdAt.year.toString(),
              date: _formatDateVi(currentPost.createdAt),
              onClose: () => Navigator.of(context).pop(),
              onShare: () => _handleShare(currentPost),
            ),
            const Spacer(),
            Stack(
              children: [
                _PhotoCarousel(
                  posts: posts,
                  controller: _pageController,
                  currentIndex: _currentIndex,
                  onPageChanged: _onPageChanged,
                  borderColorFor: widget.borderColorFor,
                ),
                if ((currentPost.caption ?? '').isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _NotePill(
                        text: currentPost.caption!,
                        backgroundColor: widget.captionPillColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _TimeTag(
              time: _formatTime(currentPost.createdAt),
              color: widget.timeColor,
            ),
            const Spacer(),
            _ThumbnailStrip(
              posts: posts,
              activeIndex: _currentIndex,
              scrollController: _thumbnailController,
              onTap: (i) {
                _pageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// Vietnamese date format: "Ngày 1 tháng 5"
  String _formatDateVi(DateTime date) {
    return 'Ngày ${date.day} tháng ${date.month}';
  }

  /// 24-hour time format: "17:03"
  String _formatTime(DateTime date) {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

// ─── Topbar ───────────────────────────────────────────────────────────────────

class _Topbar extends StatelessWidget {
  const _Topbar({
    required this.year,
    required this.date,
    required this.onClose,
    required this.onShare,
  });

  final String year;
  final String date;
  final VoidCallback onClose;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(27, 9, 27, 9),
      child: Row(
        children: [
          _TopbarButton(
            iconAsset: 'assets/icons/ic_x.svg',
            iconColor: AppColors.bw500,
            semanticsLabel: 'Đóng',
            onTap: onClose,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  year,
                  style:
                      AppTextStyles.xsRegular.copyWith(color: AppColors.bw100),
                ),
                Text(
                  date,
                  style:
                      AppTextStyles.smSemiBold.copyWith(color: AppColors.bw100),
                ),
              ],
            ),
          ),
          _TopbarButton(
            iconAsset: 'assets/icons/ic_share.svg',
            iconColor: AppColors.bw100,
            semanticsLabel: 'Chia sẻ',
            onTap: onShare,
          ),
        ],
      ),
    );
  }
}

class _TopbarButton extends StatelessWidget {
  const _TopbarButton({
    required this.iconAsset,
    required this.iconColor,
    required this.semanticsLabel,
    required this.onTap,
  });

  final String iconAsset;
  final Color iconColor;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.bw800,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: SvgPicture.asset(
              iconAsset,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Photo carousel ───────────────────────────────────────────────────────────

class _PhotoCarousel extends StatelessWidget {
  const _PhotoCarousel({
    required this.posts,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
    this.borderColorFor,
  });

  final List<Post> posts;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final Color? Function(Post post, WidgetRef ref)? borderColorFor;

  // Match [AppPhotoFrame] feed pattern — 3px border quanh ảnh active.
  static const double _borderWidth = 3.0;
  static const double _cornerRadius = 50.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: PageView.builder(
        controller: controller,
        itemCount: posts.length,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          final isActive = index == currentIndex;
          final size = isActive ? 350.0 : 260.0;
          final opacity = isActive ? 1.0 : 0.15;
          final post = posts[index];
          final image = ClipRRect(
            borderRadius: BorderRadius.circular(_cornerRadius),
            child: CachedNetworkImage(
              imageUrl: post.coverImageUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: AppColors.bw700),
              placeholder: (_, __) => Container(color: AppColors.bw800),
            ),
          );
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.symmetric(
              horizontal: 6,
              vertical: isActive ? 0 : 45,
            ),
            width: size,
            height: size,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: opacity,
              // Border chỉ render cho ảnh active — ảnh inactive opacity 0.15
              // + size 260, thêm border sẽ noise. Match feed pattern. Mỗi
              // item wrap Consumer riêng để callback ref.watch reactive theo
              // post (vd swipe sang Space khác → border đổi màu).
              child: (isActive && borderColorFor != null)
                  ? Consumer(
                      builder: (_, ref, __) {
                        final color = borderColorFor!(post, ref);
                        if (color == null) return image;
                        return Container(
                          decoration: BoxDecoration(
                            // Outer radius = inner + borderWidth để bo trùng
                            // (match [AppPhotoFrame]).
                            borderRadius: BorderRadius.circular(
                              _cornerRadius + _borderWidth,
                            ),
                            border: Border.all(
                              color: color,
                              width: _borderWidth,
                            ),
                          ),
                          child: image,
                        );
                      },
                    )
                  : image,
            ),
          );
        },
      ),
    );
  }
}

// ─── Note pill ────────────────────────────────────────────────────────────────

class _NotePill extends StatelessWidget {
  const _NotePill({
    required this.text,
    required this.backgroundColor,
  });

  final String text;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icons/ic_case_sensitive.svg',
            width: 20,
            height: 20,
            colorFilter:
                const ColorFilter.mode(AppColors.bw100, BlendMode.srcIn),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.smSemiBold.copyWith(color: AppColors.bw100),
          ),
        ],
      ),
    );
  }
}

// ─── Time tag ─────────────────────────────────────────────────────────────────

class _TimeTag extends StatelessWidget {
  const _TimeTag({required this.time, required this.color});

  final String time;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      time,
      style: AppTextStyles.lgBold.copyWith(color: color),
    );
  }
}

// ─── Thumbnail strip ──────────────────────────────────────────────────────────

class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({
    required this.posts,
    required this.activeIndex,
    required this.scrollController,
    required this.onTap,
  });

  final List<Post> posts;
  final int activeIndex;
  final ScrollController scrollController;
  final ValueChanged<int> onTap;

  static const double _thumbActiveSize = 60.0;
  static const double _thumbGap = 30.0;
  static const double _thumbRadius = 13.0;
  static const double _thumbActiveRadius = 17.0;
  static const double _ringWidth = 2.5;
  static const double _ringPadding = 3.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _thumbActiveSize,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildThumbnailSlots(),
        ),
      ),
    );
  }

  List<Widget> _buildThumbnailSlots() {
    final List<Widget> slots = [];
    for (int offset = -2; offset <= 2; offset++) {
      final index = activeIndex + offset;
      final distance = offset.abs();
      if (index >= 0 && index < posts.length) {
        final isActive = offset == 0;
        final size = _getThumbSizeByDistance(distance);
        slots.add(
          Padding(
            padding: EdgeInsets.only(right: offset < 2 ? _thumbGap : 0),
            child: Semantics(
              button: true,
              selected: isActive,
              label: 'Ảnh ${index + 1}',
              child: GestureDetector(
                onTap: () => onTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: size,
                  height: size,
                  decoration: isActive
                      ? BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(_thumbActiveRadius),
                          color: AppColors.turquoise500,
                        )
                      : null,
                  padding: isActive ? const EdgeInsets.all(_ringWidth) : null,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_thumbRadius),
                      color: AppColors.bw900,
                    ),
                    padding: const EdgeInsets.all(_ringPadding),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(_thumbRadius - _ringPadding),
                      child: _thumbImage(posts[index].coverImageUrl),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        final size = _getThumbSizeByDistance(distance);
        slots.add(
          Padding(
            padding: EdgeInsets.only(right: offset < 2 ? _thumbGap : 0),
            child: SizedBox(width: size, height: size),
          ),
        );
      }
    }
    return slots;
  }

  double _getThumbSizeByDistance(int distance) {
    switch (distance) {
      case 0:
        return _thumbActiveSize;
      case 1:
        return 44.0;
      case 2:
        return 36.0;
      default:
        return 32.0;
    }
  }

  Widget _thumbImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => Container(color: AppColors.bw700),
      placeholder: (_, __) => Container(color: AppColors.bw800),
    );
  }
}
