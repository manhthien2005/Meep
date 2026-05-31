import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/profile/presentation/widgets/diary_tab_content.dart';
import 'package:meep/features/profile/presentation/widgets/photo_grid.dart';
import 'package:meep/shared/widgets/app_taskbar.dart';
import 'package:meep/shared/widgets/share_profile_sheet.dart';

// ─── MOCK DATA — xoá khi wire ProfileController ──────────────────────────────
const _kFriendUsername = 'bk';
const _kFriendBio = '🍚 👚 🌾 💵\n💙 Mê xe độ 💙\nĐối sao đáp vậy 👍';
const _kFriendPostCount = 6;
const _kFriendFriendCount = 15;
const _kFriendSpaceCount = 4;

final _kFriendPhotos = List.generate(
  _kFriendPostCount,
  (i) => 'https://picsum.photos/seed/friend_mock_$i/400',
);

const _cBg = Color(0xFF050F10);
const _cButtonFill = Color(0xFF363636);
const _cButtonText = Color(0xFFDDDDDD);
const _cAvatarRing = Color(0xFFD9D9D9);
const _cInactiveIcon = Color(0xFF949494);

class FriendProfileScreen extends StatefulWidget {
  const FriendProfileScreen({super.key, required this.uid});

  final String uid;

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
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
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _FriendAvatar(username: _kFriendUsername),
                          SizedBox(width: 25),
                          _StatsRow(
                            postCount: _kFriendPostCount,
                            friendCount: _kFriendFriendCount,
                            spaceCount: _kFriendSpaceCount,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        _kFriendUsername,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 28 / 20,
                          color: AppColors.bw100,
                        ),
                      ),
                      if (_kFriendBio.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          _kFriendBio,
                          style: AppTextStyles.smRegular.copyWith(
                            color: AppColors.bw100,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _FriendActionButton(
                              label: 'Nhắn tin',
                              onTap: () {
                                // TODO(T3/HanDHG): navigate to chat
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FriendActionButton(
                              label: 'Chia sẻ trang cá nhân',
                              onTap: () => ShareProfileSheet.show(
                                context,
                                uid: widget.uid,
                                username: _kFriendUsername,
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
                  activeTab: _activeTab,
                  onTabChanged: (t) => setState(() => _activeTab = t),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _activeTab == 0
                      ? PhotoGrid(
                          photos: _kFriendPhotos,
                          onTap: (index) => context.push(
                            '/profile/photo/friend-$index',
                            extra: <String, dynamic>{
                              'index': index,
                              'photos': _kFriendPhotos,
                            },
                          ),
                        )
                      : const DiaryTabContent(itemCount: 4),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppTaskbar(
                  activeTab: TaskbarTab.profile,
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
                        context.go('/profile', extra: widget.uid);
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

// ─── Avatar ──────────────────────────────────────────────────────────────────

class _FriendAvatar extends StatelessWidget {
  const _FriendAvatar({required this.username});

  final String username;

  String get _initials {
    final parts = username.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return username.isNotEmpty ? username[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
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
        child: Container(
          color: AppColors.bw700,
          alignment: Alignment.center,
          child: Text(
            _initials,
            style: AppTextStyles.lgBold.copyWith(color: AppColors.bw100),
          ),
        ),
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
  });

  final int postCount;
  final int friendCount;
  final int spaceCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatItem(count: postCount, label: 'Khoảnh khắc'),
        const SizedBox(width: 30),
        _StatItem(count: friendCount, label: 'Bạn bè'),
        const SizedBox(width: 30),
        _StatItem(count: spaceCount, label: 'Space'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 24 / 18,
            color: AppColors.bw100,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: AppTextStyles.smMedium.copyWith(color: AppColors.bw100),
          textAlign: TextAlign.center,
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
