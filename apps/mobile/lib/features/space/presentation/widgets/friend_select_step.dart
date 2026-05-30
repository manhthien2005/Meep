import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/friend/application/friend_controller.dart';

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
    // TODO(SP/T3.2): get current user uid from auth
    final repo = ref.watch(friendRepositoryProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            'Thêm Space mới',
            style: AppTextStyles.xlBold.copyWith(color: AppColors.bw100),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tạo một không gian kết nối với bạn bè',
            style: AppTextStyles.mdBold.copyWith(color: AppColors.bw500),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm bạn bè',
              hintStyle: AppTextStyles.mdRegular.copyWith(
                color: AppColors.bw500,
              ),
              filled: true,
              fillColor: AppColors.bw700,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: AppTextStyles.mdRegular.copyWith(color: AppColors.bw100),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          // Friend list
          Expanded(
            child: StreamBuilder<List<UserProfile>>(
              stream: repo.watchFriends('current-uid-mock'),
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
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final friend = filtered[index];
                    final isSelected =
                        widget.selectedFriendUids.contains(friend.uid);
                    final canSelect =
                        isSelected || widget.selectedFriendUids.length < 9;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: friend.avatarUrl != null
                            ? NetworkImage(friend.avatarUrl!)
                            : null,
                        child: friend.avatarUrl == null
                            ? Text(
                                friend.displayName[0].toUpperCase(),
                                style: AppTextStyles.mdBold,
                              )
                            : null,
                      ),
                      title: Text(
                        friend.displayName,
                        style: AppTextStyles.mdSemiBold.copyWith(
                          color: AppColors.bw100,
                        ),
                      ),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: canSelect
                            ? (value) {
                                setState(() {
                                  if (value == true) {
                                    widget.selectedFriendUids.add(friend.uid);
                                  } else {
                                    widget.selectedFriendUids
                                        .remove(friend.uid);
                                  }
                                });
                              }
                            : null,
                        activeColor: AppColors.turquoise500,
                        checkColor: Colors.white,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Continue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  widget.selectedFriendUids.isEmpty ? null : widget.onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0x66394041),
                disabledBackgroundColor: const Color(0x66394041),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Tiếp tục →',
                style: AppTextStyles.mdBold.copyWith(
                  color: widget.selectedFriendUids.isEmpty
                      ? AppColors.bw600
                      : AppColors.bw100,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
