import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/profile/presentation/widgets/photo_grid.dart';
import 'package:meep/features/profile/presentation/widgets/profile_tab_bar.dart';

// ─── MOCK DATA — xoá khi wire ProfileController ──────────────────────────────
const _kUsername = 'janakimmm';
const _kBio = 'nhìn cái choá zì ???';
const _kPostCount = 9;
const _kFriendCount = 15;
const _kSpaceCount = 2;
final _kMockPhotos = List.generate(
  9,
  (i) => 'https://picsum.photos/seed/meep_mock_$i/400',
);

// ─── Missing design tokens — ping leader để add vào core/theme/ ───────────
// #0D0804 → profileBackground  (bw900=#050F10 là gần nhất)
// #363636 → actionButtonFill
// #DDDDDD → actionButtonText
// #D9D9D9 → avatarRingIdle
// AppTextStyles.lgSemiBold  — 20px w600 h:28/20  (username)
// AppTextStyles.baseSemiBold — 18px w600 h:24/18 (stats number)
const _cBg = Color(0xFF0D0804);
const _cButtonFill = Color(0xFF363636);
const _cButtonText = Color(0xFFDDDDDD);
const _cAvatarRing = Color(0xFFD9D9D9);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.uid});

  final String uid;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cBg,
      body: SafeArea(
        child: Column(
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
                      const _ProfileAvatar(username: _kUsername),
                      const SizedBox(width: 25),
                      _StatsRow(
                        postCount: _kPostCount,
                        friendCount: _kFriendCount,
                        spaceCount: _kSpaceCount,
                        onFriendTap: () {
                          // TODO(T3): open FriendSheet
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    _kUsername,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.w600, // TODO: AppTextStyles.lgSemiBold
                      height: 28 / 20,
                      color: AppColors.bw100,
                    ),
                  ),
                  if (_kBio.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      _kBio,
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
                          onTap: () {
                            // TODO(T3): context.push('/profile/edit')
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ProfileActionButton(
                          label: 'Chia sẻ trang cá nhân',
                          onTap: () {
                            // TODO(T6): show ShareProfileSheet
                          },
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
            Expanded(
              child: _activeTab == 0
                  ? PhotoGrid(
                      photos: _kMockPhotos,
                      onTap: (index) {
                        // TODO(T4): context.push('/profile/photo/${index}')
                      },
                    )
                  : const _DiaryTabContent(),
            ),
          ],
        ),
      ),
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
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(color: _cAvatarRing, width: 2), // TODO: AppColors.avatarRingIdle
        ),
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? Image.network(avatarUrl!, fit: BoxFit.cover)
            : Container(
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
    required this.onFriendTap,
  });

  final int postCount;
  final int friendCount;
  final int spaceCount;
  final VoidCallback onFriendTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatItem(count: postCount, label: 'Khoảnh khắc'),
        const SizedBox(width: 30),
        GestureDetector(
          onTap: onFriendTap,
          child: _StatItem(count: friendCount, label: 'Bạn bè'),
        ),
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
            fontWeight: FontWeight.w600, // TODO: AppTextStyles.baseSemiBold
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

// ─── Diary tab ───────────────────────────────────────────────────────────────

class _DiaryTabContent extends StatelessWidget {
  const _DiaryTabContent();

  @override
  Widget build(BuildContext context) {
    // TODO(T8): connect DiaryRepository.getPublicEntries(uid) → DiaryMoodCard grid
    return const Center(
      child: Text(
        'Chưa có nhật ký nào',
        style: TextStyle(color: AppColors.bw500),
      ),
    );
  }
}
