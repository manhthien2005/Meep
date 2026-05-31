import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/profile/presentation/widgets/share_photo_sheet.dart';

// ─── MOCK DATA — xoá khi wire PostRepository ─────────────────────────────────
final _kMockPhotos = List.generate(
  9,
  (i) => 'https://picsum.photos/seed/meep_detail_$i/700',
);
const _kMockNotes = [
  'Feeling toasty!',
  '',
  'Chill day',
  '',
  'Miss you',
  '',
  '',
  'Lunch!',
  '',
];
const _kMockTimes = [
  '17:03',
  '09:12',
  '14:55',
  '20:01',
  '08:30',
  '16:44',
  '11:22',
  '19:07',
  '07:48',
];
const _kMockDates = [
  'Ngày 1 tháng 5',
  'Ngày 3 tháng 5',
  'Ngày 5 tháng 5',
  'Ngày 7 tháng 5',
  'Ngày 9 tháng 5',
  'Ngày 11 tháng 5',
  'Ngày 13 tháng 5',
  'Ngày 15 tháng 5',
  'Ngày 17 tháng 5',
];

class PhotoDetailScreen extends StatefulWidget {
  const PhotoDetailScreen({
    super.key,
    required this.postId,
    this.initialIndex = 0,
    this.photos,
  });

  final String postId;
  final int initialIndex;

  /// Override danh sách ảnh. Null = dùng mock mặc định (_kMockPhotos).
  final List<String>? photos;

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
    // Scroll thumbnail strip to center active thumb after first frame
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
    // Accumulate left edge positions: listPadding + (i × (thumbSize + thumbGap))
    // then add half active thumb to get center point
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

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos ?? _kMockPhotos;
    return Scaffold(
      backgroundColor: AppColors.bw900,
      body: SafeArea(
        child: Column(
          children: [
            _Topbar(
              year: '2026',
              date: _kMockDates[_currentIndex % _kMockDates.length],
              onClose: () => Navigator.of(context).pop(),
              onShare: () => SharePhotoSheet.show(context),
            ),
            const Spacer(),
            // Ảnh chính + peek + Note overlay - căn giữa màn hình
            Stack(
              children: [
                _PhotoCarousel(
                  photos: photos,
                  controller: _pageController,
                  currentIndex: _currentIndex,
                  onPageChanged: _onPageChanged,
                ),
                if (_kMockNotes[_currentIndex % _kMockNotes.length].isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _NotePill(
                        text:
                            _kMockNotes[_currentIndex % _kMockNotes.length],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Time tag — bên dưới ảnh, không có nền
            _TimeTag(time: _kMockTimes[_currentIndex % _kMockTimes.length]),
            const Spacer(),
            // Thumbnail strip — ở dưới cùng màn hình
            _ThumbnailStrip(
              photos: photos,
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
    required this.photos,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  final List<String> photos;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    // Figma 660:1940: main photo 350×350, peek nhẹ (small + faded)
    return SizedBox(
      height: 350,
      child: PageView.builder(
        controller: controller,
        itemCount: photos.length,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          final isActive = index == currentIndex;
          final size = isActive ? 350.0 : 260.0;
          final opacity = isActive ? 1.0 : 0.15;
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.network(
                  photos[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColors.bw700),
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(color: AppColors.bw800),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Note pill ────────────────────────────────────────────────────────────────

class _NotePill extends StatelessWidget {
  const _NotePill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x80000000),
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
  const _TimeTag({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    return Text(
      time,
      style: AppTextStyles.lgBold.copyWith(color: AppColors.bw100),
    );
  }
}

// ─── Thumbnail strip ──────────────────────────────────────────────────────────

class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({
    required this.photos,
    required this.activeIndex,
    required this.scrollController,
    required this.onTap,
  });

  final List<String> photos;
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
    // Luôn hiển thị 5 slots: active ở giữa + 2 bên mỗi bên 2 slots
    // Nếu không có ảnh thì dùng invisible spacer
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

    // Luôn tạo 5 slots để giữ active thumb ở giữa
    for (int offset = -2; offset <= 2; offset++) {
      final index = activeIndex + offset;
      final distance = offset.abs();

      if (index >= 0 && index < photos.length) {
        // Có ảnh: render thumbnail
        final isActive = offset == 0;
        final size = _getThumbSizeByDistance(distance);

        slots.add(
          Padding(
            padding: EdgeInsets.only(
              right: offset < 2 ? _thumbGap : 0,
            ),
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
                      child: _thumbImage(photos[index]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        // Không có ảnh: invisible spacer
        final size = _getThumbSizeByDistance(distance);
        slots.add(
          Padding(
            padding: EdgeInsets.only(
              right: offset < 2 ? _thumbGap : 0,
            ),
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
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: AppColors.bw700),
    );
  }
}
