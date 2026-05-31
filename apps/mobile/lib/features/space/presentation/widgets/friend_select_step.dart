import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/friend/application/friend_controller.dart';
import 'package:meep/shared/widgets/app_avatar.dart';
import 'package:meep/shared/widgets/app_primary_button.dart';

class FriendSelectStep extends ConsumerStatefulWidget {
  const FriendSelectStep({
    super.key,
    required this.selectedFriendUids,
    required this.onContinue,
    required this.onClose,
  });

  final Set<String> selectedFriendUids;
  final VoidCallback onContinue;
  final VoidCallback onClose;

  @override
  ConsumerState<FriendSelectStep> createState() => _FriendSelectStepState();
}

class _FriendSelectStepState extends ConsumerState<FriendSelectStep> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Cache stream 1 lần để setState (tap chọn friend) không re-subscribe
  // → không reload toàn bộ list.
  late final Stream<List<UserProfile>> _friendsStream;

  @override
  void initState() {
    super.initState();
    // TODO(SP/T3.2): get current user uid from auth
    _friendsStream =
        ref.read(friendRepositoryProvider).watchFriends('current-uid-mock');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserProfile> _filterFriends(List<UserProfile> friends) {
    if (_searchQuery.isEmpty) return friends;
    final query = _searchQuery.toLowerCase();
    return friends
        .where(
          (f) =>
              f.displayName.toLowerCase().contains(query) ||
              f.username.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Title
          Text(
            'Thêm Space mới',
            style: AppTextStyles.xlBold.copyWith(color: AppColors.bw100),
          ),
          const SizedBox(height: 8),
          // Subtitle
          Text(
            'Tạo một không gian kết nối với bạn bè',
            style: AppTextStyles.baseBold.copyWith(color: AppColors.bw500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF363636),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Input thật — text căn giữa
                TextField(
                  controller: _searchController,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: AppTextStyles.baseBold.copyWith(
                    color: AppColors.bw100,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                // Placeholder (icon + text) căn giữa, ẩn khi gõ
                if (_searchQuery.isEmpty)
                  IgnorePointer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search,
                          size: 20,
                          color: Color(0xFFD5D5D5),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Tìm kiếm bạn bè',
                          style: AppTextStyles.baseBold.copyWith(
                            color: const Color(0xFFDDDDDD),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Section header
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                size: 20,
                color: Color(0xFFD5D5D5),
              ),
              const SizedBox(width: 8),
              Text(
                'Chọn bạn bè để thêm vào Space',
                style: AppTextStyles.baseBold.copyWith(
                  color: const Color(0xFFDDDDDD),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Friend list
          Expanded(
            child: StreamBuilder<List<UserProfile>>(
              stream: _friendsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Lỗi tải danh sách bạn bè',
                      style: AppTextStyles.mdRegular.copyWith(
                        color: AppColors.error500,
                      ),
                    ),
                  );
                }
                final friends = snapshot.data ?? [];
                final filtered = _filterFriends(friends);
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'Không tìm thấy bạn bè',
                      style: AppTextStyles.mdRegular.copyWith(
                        color: AppColors.bw500,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final friend = filtered[index];
                    final isSelected =
                        widget.selectedFriendUids.contains(friend.uid);
                    final canSelect =
                        isSelected || widget.selectedFriendUids.length < 9;

                    return _FriendListItem(
                      friend: friend,
                      isSelected: isSelected,
                      canSelect: canSelect,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            widget.selectedFriendUids.remove(friend.uid);
                          } else if (canSelect) {
                            widget.selectedFriendUids.add(friend.uid);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // Continue button
          AppPrimaryButton(
            label: 'Tiếp tục',
            onPressed:
                widget.selectedFriendUids.isNotEmpty ? widget.onContinue : null,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FriendListItem extends StatelessWidget {
  const _FriendListItem({
    required this.friend,
    required this.isSelected,
    required this.canSelect,
    required this.onTap,
  });

  final UserProfile friend;
  final bool isSelected;
  final bool canSelect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canSelect || isSelected ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            // Avatar with ring
            AppAvatar(
              imageUrl: friend.avatarUrl,
              size: 50,
              ringColor: AppColors.bw600,
              fallbackText: friend.displayName.isEmpty
                  ? '?'
                  : friend.displayName[0].toUpperCase(),
            ),
            const SizedBox(width: 16),
            // Name
            Expanded(
              child: Text(
                friend.displayName,
                style: AppTextStyles.mdBold.copyWith(color: AppColors.bw100),
              ),
            ),
            // Checkbox
            _CustomCheckbox(
              isChecked: isSelected,
              enabled: canSelect || isSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomCheckbox extends StatelessWidget {
  const _CustomCheckbox({
    required this.isChecked,
    required this.enabled,
  });

  final bool isChecked;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: isChecked ? AppColors.turquoise500 : AppColors.bw400,
        shape: BoxShape.circle,
        border: Border.all(
          color: isChecked ? AppColors.turquoise500 : AppColors.bw600,
          width: 2,
        ),
      ),
      child: isChecked
          ? const Icon(
              Icons.check,
              size: 12,
              color: AppColors.bw900,
            )
          : null,
    );
  }
}
