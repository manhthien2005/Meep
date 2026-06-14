import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/chat/application/chat_providers.dart';
import 'package:meep/features/profile/application/friend_posts_provider.dart';
import 'package:meep/features/profile/application/profile_controller.dart';
import 'package:meep/features/profile/presentation/widgets/diary_tab_content.dart';
import 'package:meep/features/profile/presentation/widgets/photo_grid.dart';
import 'package:meep/shared/widgets/app_taskbar.dart';
import 'package:meep/shared/widgets/share_profile_sheet.dart';

// ─── Missing design tokens — ping leader để add vào core/theme/ ──────────────
const _cBg = Color(0xFF050F10);
const _cButtonFill = Color(0xFF363636);
const _cButtonText = Color(0xFFDDDDDD);
const _cAvatarRing = Color(0xFFD9D9D9);
const _cInactiveIcon = Color(0xFF949494);

class FriendProfileScreen extends ConsumerStatefulWidget {
  const FriendProfileScreen({super.key, required this.uid});

  final String uid;

  @override
  ConsumerState<FriendProfileScreen> createState() =>
      _FriendProfileScreenState();
}

class _FriendProfileScreenState extends ConsumerState<FriendProfileScreen> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    final isFriendAsync = ref.watch(isFriendOfCurrentProvider(widget.uid));
    final unreadCounts = ref.watch(unreadCountsProvider);
    final totalUnread =
        unreadCounts.values.fold<int>(0, (sum, val) => sum + val);

    return Scaffold(
      backgroundColor: _cBg,
      body: SafeArea(
        child: isFriendAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.bw100),
          ),
          error: (e, _) => _GateMessage(
            message: 'Không tải được hồ sơ bạn bè.',
            onBack: () => context.pop(),
          ),
          data: (isFriend) {
            if (!isFriend) {
              return _GateMessage(
                message: 'Bạn cần kết bạn để xem trang cá nhân này.',
                onBack: () => context.pop(),
              );
            }
            return _FriendProfileBody(
              friendUid: widget.uid,
              activeTab: _activeTab,
              onTabChanged: (t) => setState(() => _activeTab = t),
              totalUnread: totalUnread,
            );
          },
        ),
      ),
    );
  }
}

// ─── Gate fallback — non-friend / error / unauth ─────────────────────────────

class _GateMessage extends StatelessWidget {
  const _GateMessage({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: AppTextStyles.mdRegular.copyWith(color: AppColors.bw100),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _FriendActionButton(
              label: 'Quay lại',
              onTap: onBack,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Body — load profile + posts cho friend ─────────────────────────────────

class _FriendProfileBody extends ConsumerWidget {
  const _FriendProfileBody({
    required this.friendUid,
    required this.activeTab,
    required this.onTabChanged,
    required this.totalUnread,
  });

  final String friendUid;
  final int activeTab;
  final ValueChanged<int> onTabChanged;
  final int totalUnread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider(friendUid));

    if (state.isLoading && state.profile == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.bw100),
      );
    }

    final profile = state.profile;
    if (profile == null) {
      return _GateMessage(
        message: state.errorMessage ?? 'Không tải được hồ sơ',
        onBack: () => context.pop(),
      );
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Semantics(
                button: true,
                label: 'Quay lại',
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.bw100,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _FriendAvatar(
                        username: profile.username,
                        avatarUrl: profile.avatarUrl,
                      ),
                      const SizedBox(width: 25),
                      // Friend profile chỉ hiện Khoảnh khắc + Bạn bè per spec —
                      // Space ẩn (không gọi từ profile.spaceCount).
                      Expanded(
                        child: _StatsRow(
                          postCount: profile.postCount,
                          friendCount: profile.friendCount,
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
                      style: AppTextStyles.smRegular
                          .copyWith(color: AppColors.bw100),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _FriendActionButton(
                          label: 'Nhắn tin',
                          onTap: () {
                            // TODO(P/T7/HanDHG): navigate to chat conversation
                            // qua pairId — đợi Chat module BE
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FriendActionButton(
                          label: 'Chia sẻ trang cá nhân',
                          onTap: () => ShareProfileSheet.show(
                            context,
                            uid: friendUid,
                            username: profile.username,
                            title: 'Chia sẻ liên kết của bạn bè',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            _FriendTabBar(
              activeTab: activeTab,
              onTabChanged: onTabChanged,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: activeTab == 0
                  ? _FriendPhotosTab(friendUid: friendUid)
                  : DiaryTabContent(
                      uid: friendUid,
                      ownerActionsEnabled: false,
                    ),
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
                    context.go('/profile', extra: friendUid);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Photos tab — audience filtered ──────────────────────────────────────────

class _FriendPhotosTab extends ConsumerWidget {
  const _FriendPhotosTab({required this.friendUid});

  final String friendUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(friendPostsProvider(friendUid)).when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.bw100),
          ),
          error: (e, _) => Center(
            child: Text(
              'Không tải được ảnh.',
              style: AppTextStyles.smRegular.copyWith(color: AppColors.bw500),
            ),
          ),
          data: (posts) {
            if (posts == null || posts.isEmpty) {
              return Center(
                child: Text(
                  'Chưa có ảnh nào',
                  style:
                      AppTextStyles.smRegular.copyWith(color: AppColors.bw500),
                ),
              );
            }
            final urls = posts.map((p) => p.coverImageUrl).toList();
            return PhotoGrid(
              photos: urls,
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

class _FriendAvatar extends StatelessWidget {
  const _FriendAvatar({required this.username, this.avatarUrl});

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

// ─── Stats — chỉ 2 cột (Khoảnh khắc + Bạn bè), KHÔNG hiện Space ──────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.postCount, required this.friendCount});

  final int postCount;
  final int friendCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Flexible(child: _StatItem(count: postCount, label: 'Khoảnh khắc')),
        Flexible(child: _StatItem(count: friendCount, label: 'Bạn bè')),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.count, required this.label});

  final int count;
  final String label;

  // Counter trên Firestore có thể drift âm — xem note tại
  // profile_screen.dart `_StatItem._safeCount`.
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

class _FriendActionButton extends StatelessWidget {
  const _FriendActionButton({required this.label, required this.onTap});

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
            color: _cButtonFill,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.smSemiBold.copyWith(color: _cButtonText),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

// ─── Tab bar — grid-3x3 + book-heart, có thể toggle ─────────────────────────

class _FriendTabBar extends StatelessWidget {
  const _FriendTabBar({required this.activeTab, required this.onTabChanged});

  final int activeTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                selected: activeTab == 0,
                label: 'Tab ảnh',
                child: GestureDetector(
                  onTap: () => onTabChanged(0),
                  child: SizedBox(
                    height: 33,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/ic_grid_3x3.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          activeTab == 0 ? AppColors.bw100 : _cInactiveIcon,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                button: true,
                selected: activeTab == 1,
                label: 'Tab nhật ký',
                child: GestureDetector(
                  onTap: () => onTabChanged(1),
                  child: SizedBox(
                    height: 33,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/ic_book_heart.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          activeTab == 1 ? AppColors.bw100 : _cInactiveIcon,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Stack(
          children: [
            Container(
              height: 1,
              color: AppColors.bw300.withValues(alpha: 0.5),
            ),
            AnimatedAlign(
              alignment:
                  activeTab == 0 ? Alignment.centerLeft : Alignment.centerRight,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(height: 1, color: AppColors.bw100),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
