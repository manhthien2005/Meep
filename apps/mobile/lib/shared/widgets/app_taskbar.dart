import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/shared/widgets/app_glass_surface.dart';

part 'app_taskbar_widgets.dart';

/// Bottom navigation taskbar — 2 biến thể:
///
/// - [TaskbarVariant.floating]: pill nổi (hug content), active = pill xám trượt.
/// - [TaskbarVariant.embedded]: chìm full-width, có 2 nút phụ (grid/upload)
///   nằm ngoài pill. KHÔNG có active state — ring tĩnh giữa, icon home ẩn.
///
/// Widget thuần presentation: chỉ phát [onTabSelected]/[onGridTap]/[onUploadTap],
/// KHÔNG tự navigate. Mapping tab → route + ví dụ wire: xem
/// docs/architecture/taskbar-navigation.md.
///
/// Kiến trúc 3 lớp tách bạch: SVG chỉ là icon đơn (atomic, 20×20); khung kính,
/// indicator, layout và interaction đều dựng bằng Flutter — vì `flutter_svg`
/// không render `backdrop-filter`/`foreignObject`.
enum TaskbarTab { streak, diary, home, chat, profile }

enum TaskbarVariant { floating, embedded }

class AppTaskbar extends StatelessWidget {
  const AppTaskbar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    this.variant = TaskbarVariant.floating,
    this.chatBadgeCount = 0,
    this.onGridTap,
    this.onUploadTap,
  });

  /// Tab đang active. `null` = không tab nào active (ẩn indicator).
  final TaskbarTab? activeTab;
  final ValueChanged<TaskbarTab> onTabSelected;
  final TaskbarVariant variant;

  /// Số badge trên tab chat. `0` = không hiện badge.
  final int chatBadgeCount;

  /// Embedded only — nút grid (leading). No-op khi `null`.
  final VoidCallback? onGridTap;

  /// Embedded only — nút upload (trailing). No-op khi `null`.
  final VoidCallback? onUploadTap;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case TaskbarVariant.floating:
        return _FloatingTaskbar(
          activeTab: activeTab,
          onTabSelected: onTabSelected,
          chatBadgeCount: chatBadgeCount,
        );
      case TaskbarVariant.embedded:
        return _EmbeddedTaskbar(
          onTabSelected: onTabSelected,
          chatBadgeCount: chatBadgeCount,
          onGridTap: onGridTap,
          onUploadTap: onUploadTap,
        );
    }
  }
}

// ── Tab metadata ──────────────────────────────────────────────────────────────

class _TabSpec {
  const _TabSpec(this.asset, this.label);
  final String asset;
  final String label;
}

const Map<TaskbarTab, _TabSpec> _tabSpecs = {
  TaskbarTab.streak: _TabSpec('assets/icons/ic_tab_streak.svg', 'Kỷ niệm'),
  TaskbarTab.diary: _TabSpec('assets/icons/ic_tab_diary.svg', 'Nhật ký'),
  TaskbarTab.home: _TabSpec('assets/icons/ic_tab_home.svg', 'Trang chủ'),
  TaskbarTab.chat: _TabSpec('assets/icons/ic_tab_chat.svg', 'Tin nhắn'),
  TaskbarTab.profile: _TabSpec('assets/icons/ic_tab_profile.svg', 'Hồ sơ'),
};

// ── Constants (từ Figma) ────────────────────────────────────────────────────

class _Const {
  static const double height = 58;

  /// Float: bề rộng mỗi slot tab (hug content, không full-screen).
  static const double floatSlotWidth = 52;

  /// Float: padding nội bộ glass surface (tránh pill đè viền).
  static const double floatContentPadding = 14;

  static const double pillWidth = 54;
  static const double pillHeight = 46;
  static const double pillRadius = 23;

  static const double ringSize = 44;
  static const double ringInner = 32;
  static const double ringStroke = 2.7;

  /// Embedded: bán kính bo góc nền pill (= height / 2 - viền).
  static const double embeddedRadius = 28.5;

  static const double iconSize = 21;
  static const double sideIconSize = 24;
  static const double tapTarget = 48;

  static const Duration animDuration = Duration(milliseconds: 250);
  static const Curve animCurve = Curves.easeOutCubic;
}

// ── Floating variant ──────────────────────────────────────────────────────────

class _FloatingTaskbar extends StatelessWidget {
  const _FloatingTaskbar({
    required this.activeTab,
    required this.onTabSelected,
    required this.chatBadgeCount,
  });

  final TaskbarTab? activeTab;
  final ValueChanged<TaskbarTab> onTabSelected;
  final int chatBadgeCount;

  @override
  Widget build(BuildContext context) {
    const tabs = TaskbarTab.values;
    return SizedBox(
      width:
          _Const.floatSlotWidth * tabs.length + _Const.floatContentPadding * 2,
      height: _Const.height,
      child: AppGlassSurface(
        height: _Const.height,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _Const.floatContentPadding,
          ),
          child: _IndicatorStack(
            itemCount: tabs.length,
            activeIndex: activeTab == null ? null : tabs.indexOf(activeTab!),
            indicatorWidth: _Const.pillWidth,
            indicator: const _PillIndicator(),
            children: [
              for (final tab in tabs)
                _TaskbarIcon(
                  spec: _tabSpecs[tab]!,
                  isActive: tab == activeTab,
                  activeColor: AppColors.bw100,
                  badgeCount: tab == TaskbarTab.chat ? chatBadgeCount : 0,
                  onTap: () => onTabSelected(tab),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Embedded variant ────────────────────────────────────────────────────────

class _EmbeddedTaskbar extends StatelessWidget {
  const _EmbeddedTaskbar({
    required this.onTabSelected,
    required this.chatBadgeCount,
    required this.onGridTap,
    required this.onUploadTap,
  });

  final ValueChanged<TaskbarTab> onTabSelected;
  final int chatBadgeCount;
  final VoidCallback? onGridTap;
  final VoidCallback? onUploadTap;

  @override
  Widget build(BuildContext context) {
    const tabs = TaskbarTab.values;
    return SizedBox(
      height: _Const.height,
      child: Row(
        children: [
          _SideButton(
            asset: 'assets/icons/ic_tab_grid.svg',
            label: 'Lưới ảnh',
            onTap: onGridTap,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bw800.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(_Const.embeddedRadius),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ring + circle trắng cố định giữa
                  const _RingIndicator(),
                  // Icons
                  Row(
                    children: [
                      for (final tab in tabs)
                        Expanded(
                          child: _TaskbarIcon(
                            spec: _tabSpecs[tab]!,
                            isActive: false,
                            activeColor: AppColors.bw100,
                            hideWhenHome: tab == TaskbarTab.home,
                            badgeCount:
                                tab == TaskbarTab.chat ? chatBadgeCount : 0,
                            onTap: () => onTabSelected(tab),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _SideButton(
            asset: 'assets/icons/ic_tab_upload.svg',
            label: 'Tải ảnh lên',
            onTap: onUploadTap,
          ),
        ],
      ),
    );
  }
}
