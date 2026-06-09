import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/chat/application/chat_providers.dart';
import 'package:meep/features/friend/application/friend_controller.dart';
import 'package:meep/features/friend/presentation/friend_sheet.dart';
import 'package:meep/features/profile/application/profile_controller.dart';
import 'package:meep/features/profile/application/profile_posts_provider.dart';
import 'package:meep/features/profile/presentation/widgets/diary_tab_content.dart';
import 'package:meep/features/profile/presentation/widgets/photo_grid.dart';
import 'package:meep/features/profile/presentation/widgets/profile_tab_bar.dart';
import 'package:meep/shared/widgets/app_taskbar.dart';
import 'package:meep/shared/widgets/share_profile_sheet.dart';

// ─── Missing design tokens — ping leader để add vào core/theme/ ───────────
// #0D0804 → profileBackground  (bw900=#050F10 là gần nhất)
// #363636 → actionButtonFill
// #DDDDDD → actionButtonText
// #D9D9D9 → avatarRingIdle
const _cBg = Color(0xFF050F10); // Black & White/900
const _cButtonFill = Color(0xFF363636);
const _cButtonText = Color(0xFFDDDDDD);
const _cAvatarRing = Color(0xFFD9D9D9);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, required this.uid});

  final String uid;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _activeTab = 0;

  void _openFriendSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x73000000),
      builder: (_) => const FriendSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = ref.watch(currentUidProvider).valueOrNull;
    final effectiveUid = widget.uid.isEmpty ? currentUid ?? '' : widget.uid;
    final state = ref.watch(profileControllerProvider(effectiveUid));
    final unreadCounts = ref.watch(unreadCountsProvider);
    final totalUnread =
        unreadCounts.values.fold<int>(0, (sum, val) => sum + val);

    if (state.isLoading && state.profile == null) {
      return const Scaffold(
        backgroundColor: _cBg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.bw100),
        ),
      );
    }

    final profile = state.profile;
    if (profile == null) {
      return Scaffold(
        backgroundColor: _cBg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.errorMessage ?? 'Không tải được hồ sơ',
                style: AppTextStyles.mdRegular.copyWith(color: AppColors.bw100),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    final friendCount = currentUid != null && effectiveUid == currentUid
        ? ref.watch(
            friendControllerProvider(currentUid).select(
              (s) => s.friends.length,
            ),
          )
        : profile.friendCount;

    return Scaffold(
      backgroundColor: _cBg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _ProfileAvatar(
                            username: profile.username,
                            avatarUrl: profile.avatarUrl,
                          ),
                          const SizedBox(width: 25),
                          Expanded(
                            child: _StatsRow(
                              postCount: profile.postCount,
                              friendCount: friendCount,
                              spaceCount: profile.spaceCount,
                              onFriendTap: () {
                                if (currentUid == null ||
                                    effectiveUid != currentUid) {
                                  return;
                                }
                                _openFriendSheet(context);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        profile.username,
                        style: AppTextStyles.lgSemiBold.copyWith(
                          color: AppColors.bw100,
                        ),
                      ),
                      if ((profile.bio ?? '').isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          profile.bio!,
                          style: AppTextStyles.smRegular.copyWith(
                            color: AppColors.bw100,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _ProfileActionButton(
                              label: 'Chỉnh sửa',
                              onTap: () => context.push('/profile/edit'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ProfileActionButton(
                              label: 'Chia sẻ trang cá nhân',
                              onTap: () => ShareProfileSheet.show(
                                context,
                                uid: effectiveUid,
                                username: profile.username,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                ProfileTabBar(
                  activeTab: _activeTab,
                  onTabChanged: (t) => setState(() => _activeTab = t),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _activeTab == 0
                      ? _PhotosTab(uid: effectiveUid)
                      : DiaryTabContent(uid: effectiveUid),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height * 0.045,
                ),
                child: AppTaskbar(
                  activeTab: TaskbarTab.profile,
                  chatBadgeCount: totalUnread,
                  onTabSelected: (tab) {
                    switch (tab) {
                      case TaskbarTab.streak:
                        context.go('/streak');
                      case TaskbarTab.diary:
                        context.go('/diary');
                      case TaskbarTab.home:
                        context.go('/home');
                      case TaskbarTab.chat:
                        context.go('/inbox');
                      case TaskbarTab.profile:
                        context.go('/profile', extra: effectiveUid);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Photos tab — load qua profilePostsProvider, render PhotoGrid ────────────

class _PhotosTab extends ConsumerWidget {
  const _PhotosTab({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(profilePostsProvider(uid)).when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.bw100),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Không tải được ảnh. Thử lại sau.',
                style: AppTextStyles.smRegular.copyWith(color: AppColors.bw500),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (posts) {
            if (posts.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Chưa có ảnh nào',
                    style: AppTextStyles.smRegular
                        .copyWith(color: AppColors.bw500),
                  ),
                ),
              );
            }
            final photos =
                posts.map((p) => p.coverImageUrl).toList(growable: false);
            return PhotoGrid(
              photos: photos,
              posts: posts,
              onTap: (index) {
                final post = posts[index];
                context.push(
                  '/profile/photo/${post.postId}',
                  extra: <String, Object>{
                    'posts': posts,
                    'index': index,
                  },
                );
              },
            );
          },
        );
  }
}

// ─── Avatar ──────────────────────────────────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.username, this.avatarUrl});

  final String username;
  final String? avatarUrl;

  String get _initials {
    final parts = username.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return username.isNotEmpty ? username[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(color: _cAvatarRing, width: 2),
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _initialsFallback(),
                placeholder: (_, __) => Container(color: AppColors.bw800),
              )
            : _initialsFallback(),
      ),
    );
  }

  Widget _initialsFallback() {
    return Container(
      color: AppColors.bw700,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: AppTextStyles.lgBold.copyWith(color: AppColors.bw100),
      ),
    );
  }
}

// ─── Stats ───────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.postCount,
    required this.friendCount,
    required this.spaceCount,
    required this.onFriendTap,
  });

  final int postCount;
  final int friendCount;
  final int spaceCount;
  final VoidCallback onFriendTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Flexible(child: _StatItem(count: postCount, label: 'Khoảnh khắc')),
        Flexible(
          child: GestureDetector(
            onTap: onFriendTap,
            child: _StatItem(count: friendCount, label: 'Bạn bè'),
          ),
        ),
        Flexible(child: _StatItem(count: spaceCount, label: 'Space')),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.count, required this.label});

  final int count;
  final String label;

  // Counter trên Firestore có thể drift âm do CF race / miss (Task 4 — Path C
  // fix root cause ở PR riêng). Clamp tại display layer để user không thấy
  // "-1 Khoảnh khắc". Khi BE fix xong + backfill, clamp này thành no-op.
  int get _safeCount => count < 0 ? 0 : count;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$_safeCount',
          style: AppTextStyles.baseSemiBold.copyWith(color: AppColors.bw100),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: AppTextStyles.smMedium.copyWith(color: AppColors.bw100),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─── Action button ───────────────────────────────────────────────────────────

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 30,
          decoration: BoxDecoration(
            color: _cButtonFill, // TODO: AppColors.actionButtonFill
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.smSemiBold.copyWith(
              color: _cButtonText, // TODO: AppColors.actionButtonText
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
