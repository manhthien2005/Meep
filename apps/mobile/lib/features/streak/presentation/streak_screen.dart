import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/chat/application/chat_providers.dart';
import 'package:meep/features/streak/application/streak_controller.dart';
import 'package:meep/features/streak/presentation/widgets/empty_state_overlay.dart';
import 'package:meep/features/streak/presentation/widgets/streak_calendar.dart';
import 'package:meep/features/streak/presentation/widgets/streak_stats_pill.dart';
import 'package:meep/shared/widgets/app_avatar.dart';
import 'package:meep/shared/widgets/app_taskbar.dart';
import 'package:meep/shared/widgets/photo_detail_screen.dart';
import 'package:meep/shared/widgets/share_photo_sheet.dart';

/// Streak/Kỷ niệm — calendar view. Match Figma `269:1983`.
///
/// Layout:
/// - Topbar: "Kỷ niệm" Nunito Bold 18 white + avatar 40 góc phải
/// - Calendar grid (custom) → tap ngày có post → push PhotoDetailScreen
/// - Pill stats: `[N Khoảnh khắc | Xd chuỗi]` (toàn cục, không đổi khi swipe)
/// - Empty state: 2 arrow vector vẽ tay + subtitle CTA
class StreakScreen extends ConsumerStatefulWidget {
  const StreakScreen({super.key});

  @override
  ConsumerState<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends ConsumerState<StreakScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(streakControllerProvider.notifier).init(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(streakControllerProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final totalMoments =
        profileAsync.valueOrNull?.postCount ?? state.allPostDates.length;
    final unreadCounts = ref.watch(unreadCountsProvider);
    final totalUnread =
        unreadCounts.values.fold<int>(0, (sum, val) => sum + val);

    final hasNoPosts = state.allPostDates.isEmpty;
    final nowLocal = ref.watch(nowProvider)();
    final viewingMonth =
        state.viewingMonth ?? DateTime(nowLocal.year, nowLocal.month);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0804),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.vertical,
                ),
                child: Column(
                  children: [
                    const _Topbar(),
                    if (state.errorMessage != null)
                      _ErrorBanner(message: state.errorMessage!),
                    if (hasNoPosts) ...[
                      const SizedBox(height: 36),
                      const EmptyStateOverlay(),
                    ] else
                      const SizedBox(height: 90),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 41),
                      child: StreakCalendar(
                        viewingMonth: viewingMonth,
                        monthPosts: state.monthPosts,
                        today: nowLocal,
                        onTapDay: (index) => _openPhotoDetail(context, index),
                        onTapToday: () => context.go('/home'),
                        onSwipePrev: () => ref
                            .read(streakControllerProvider.notifier)
                            .swipePrev(),
                        onSwipeNext: () => ref
                            .read(streakControllerProvider.notifier)
                            .swipeNext(),
                      ),
                    ),
                    if (hasNoPosts) ...[
                      const SizedBox(height: 16),
                      const StreakArrowDown(),
                      const SizedBox(height: 16),
                    ] else
                      const SizedBox(height: 28),
                    StreakStatsPill(
                      totalMoments: totalMoments,
                      currentStreak: state.currentStreak,
                    ),
                    // Spacer cuối để Taskbar floating không đè lên pill
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height * 0.045,
                ),
                child: AppTaskbar(
                  activeTab: TaskbarTab.streak,
                  chatBadgeCount: totalUnread,
                  onTabSelected: _onTabSelected,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTabSelected(TaskbarTab tab) {
    switch (tab) {
      case TaskbarTab.streak:
        // Đã ở Streak → no-op
        break;
      case TaskbarTab.diary:
        context.go('/diary');
      case TaskbarTab.home:
        context.go('/home');
      case TaskbarTab.chat:
        context.go('/inbox');
      case TaskbarTab.profile:
        final uid = ref.read(currentUidProvider).valueOrNull;
        if (uid != null) {
          context.go('/profile', extra: uid);
        }
    }
  }

  void _openPhotoDetail(BuildContext context, int initialIndex) {
    final state = ref.read(streakControllerProvider);
    if (state.monthPosts.isEmpty) return;
    // Clamp index: monthPosts có thể đã thay đổi giữa lúc render cell và lúc
    // tap (stream emit lại, hoặc delete xảy ra song song). Tránh OOB crash.
    final safeIndex = initialIndex.clamp(0, state.monthPosts.length - 1);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PhotoDetailScreen(
          postId: state.monthPosts[safeIndex].postId,
          initialIndex: safeIndex,
          posts: state.monthPosts,
          captionPillColor: const Color(0x66394041),
          timeColor: AppColors.bw600,
          onShareTap: (p) => SharePhotoSheet.show(
            context,
            post: p,
            isAuthor: true,
          ),
        ),
      ),
    );
  }
}

// ─── Topbar ───────────────────────────────────────────────────────────────────

class _Topbar extends StatelessWidget {
  const _Topbar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(27, 9, 27, 9),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            const SizedBox(width: 40), // balance avatar
            Expanded(
              child: Text(
                'Kỷ niệm',
                textAlign: TextAlign.center,
                style: AppTextStyles.baseBold
                    .copyWith(color: const Color(0xFFFFFFFF)),
              ),
            ),
            const AppTopAvatar(),
          ],
        ),
      ),
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.error700.withValues(alpha: 0.9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.smSemiBold.copyWith(color: AppColors.bw100),
      ),
    );
  }
}
