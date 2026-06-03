part of 'app_taskbar.dart';

// Primitive private dùng chung 2 variant. Tách khỏi app_taskbar.dart để giữ
// mỗi file ≤ 300 dòng (CLAUDE.md). Cùng library nên truy cập _Const, _TabSpec.

/// Layout responsive: chia [itemCount] slot đều theo width thực, đặt
/// [indicator] sau icon active (trượt mượt khi đổi tab). Bỏ toạ độ tuyệt đối.
class _IndicatorStack extends StatelessWidget {
  const _IndicatorStack({
    required this.itemCount,
    required this.activeIndex,
    required this.indicator,
    required this.indicatorWidth,
    required this.children,
  });

  final int itemCount;
  final int? activeIndex;
  final Widget indicator;
  final double indicatorWidth;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slotWidth = constraints.maxWidth / itemCount;
        final indicatorLeft = activeIndex == null
            ? 0.0
            : slotWidth * activeIndex! + (slotWidth - indicatorWidth) / 2;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (activeIndex != null)
              AnimatedPositioned(
                duration: _Const.animDuration,
                curve: _Const.animCurve,
                top: 0,
                bottom: 0,
                left: indicatorLeft,
                width: indicatorWidth,
                child: Center(child: indicator),
              ),
            Row(
              children: [
                for (final child in children) Expanded(child: child),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Một tab: icon SVG đơn + đổi màu theo state + tap target ≥ 48px + badge +
/// Semantics. Không có 2 phiên bản icon — chỉ recolor.
class _TaskbarIcon extends StatelessWidget {
  const _TaskbarIcon({
    required this.spec,
    required this.isActive,
    required this.onTap,
    this.activeColor = AppColors.bw100,
    this.badgeCount = 0,
    this.hideWhenHome = false,
  });

  final _TabSpec spec;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;
  final int badgeCount;

  /// Embedded: ẩn icon home để không đè lên ring + circle trắng.
  final bool hideWhenHome;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: spec.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: _Const.tapTarget,
          child: Center(
            child: hideWhenHome
                ? const SizedBox.shrink()
                : Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SvgPicture.asset(
                        spec.asset,
                        width: _Const.iconSize,
                        height: _Const.iconSize,
                        colorFilter: ColorFilter.mode(
                          isActive ? activeColor : AppColors.bw500,
                          BlendMode.srcIn,
                        ),
                      ),
                      if (badgeCount > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: _Badge(count: badgeCount),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Badge chat: vòng xanh turquoise với số (đúng Figma Active=Chat, Type=2).
class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('taskbarChatBadge'),
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: AppColors.turquoise500,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(
            color: AppColors.taskbarBadgeText,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Active indicator của float: pill xám bán trong suốt.
class _PillIndicator extends StatelessWidget {
  const _PillIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('taskbarPillIndicator'),
      width: _Const.pillWidth,
      height: _Const.pillHeight,
      decoration: BoxDecoration(
        color: AppColors.bw500.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(_Const.pillRadius),
      ),
    );
  }
}

/// Active indicator của embedded: đĩa trắng + vòng cyan (hoặc màu space).
class _RingIndicator extends StatelessWidget {
  const _RingIndicator({this.ringColor});

  /// Màu ring. null = turquoise600 mặc định. Feed truyền space.colorHex.
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final color = ringColor ?? AppColors.turquoise600;
    return SizedBox(
      key: const Key('taskbarRingIndicator'),
      width: _Const.ringSize,
      height: _Const.ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: _Const.ringSize,
            height: _Const.ringSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color,
                width: _Const.ringStroke,
              ),
            ),
          ),
          Container(
            width: _Const.ringInner,
            height: _Const.ringInner,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bw100,
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút phụ embedded (grid/upload) nằm ngoài pill.
class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.asset,
    required this.label,
    required this.onTap,
  });

  final String asset;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: _Const.tapTarget,
          height: _Const.tapTarget,
          child: Center(
            child: SvgPicture.asset(
              asset,
              width: _Const.sideIconSize,
              height: _Const.sideIconSize,
              colorFilter: const ColorFilter.mode(
                AppColors.taskbarSideButton,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
