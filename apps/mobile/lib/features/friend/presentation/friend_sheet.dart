import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:meep/core/config/app_config.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/public_profile.dart';
import 'package:meep/features/friend/application/friend_controller.dart';
import 'package:meep/features/friend/application/friend_state.dart';
import 'package:meep/features/friend/data/friend_request.dart';
import 'package:meep/shared/widgets/app_avatar.dart';
import 'package:meep/shared/widgets/app_bottom_sheet.dart';
import 'package:meep/shared/widgets/app_confirm_dialog.dart';

/// Fetches the sender's profile for a pending friend request row.
/// [FriendRequest] only carries [FriendRequest.senderId]; the UI needs the
/// display name + avatar, so we look up the public profile only.
final _senderProfileProvider =
    FutureProvider.family<PublicProfile?, String>((ref, senderId) {
  return ref.read(userRepositoryProvider).getPublicProfile(senderId);
});

/// Friend management bottom sheet.
/// Shows: friend count header, search bar, friend list, invite section.
class FriendSheet extends ConsumerStatefulWidget {
  const FriendSheet({super.key});

  @override
  ConsumerState<FriendSheet> createState() => _FriendSheetState();
}

class _FriendSheetState extends ConsumerState<FriendSheet> {
  bool _isSearchExpanded = false;
  bool _showAllFriends = false;
  bool _linkCopied = false;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _expandSearch() {
    setState(() => _isSearchExpanded = true);
    _searchFocus.requestFocus();
  }

  void _toggleShowAllFriends() {
    setState(() => _showAllFriends = !_showAllFriends);
  }

  void _collapseSearch(String currentUid) {
    setState(() => _isSearchExpanded = false);
    _searchController.clear();
    _searchFocus.unfocus();
    // Reset controller state để search mode mở lại không còn kết quả cũ.
    ref.read(friendControllerProvider(currentUid).notifier).clearSearch();
  }

  Future<void> _copyLink(String uid) async {
    final link = '${AppConfig.inviteBaseUrl}/$uid';
    await Clipboard.setData(ClipboardData(text: link));
    setState(() => _linkCopied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _linkCopied = false);
    }
  }

  /// Opens the system share sheet so the user can pick any installed app
  /// (Messenger, Instagram, SMS, ...). Platform deep-links per app are not
  /// reliable on Android, so all channels route through one share sheet.
  Future<void> _shareInviteLink(String uid) async {
    final link = '${AppConfig.inviteBaseUrl}/$uid';
    await Share.share(
      'Kết bạn với mình trên Meep nhé: $link',
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUidAsync = ref.watch(currentUidProvider);

    return currentUidAsync.when(
      data: (currentUid) {
        if (currentUid == null) {
          return const SizedBox.shrink();
        }

        final friendState = ref.watch(friendControllerProvider(currentUid));
        final displayedFriends = _showAllFriends
            ? friendState.friends
            : friendState.friends.take(3).toList();

        return AppBottomSheet(
          heightFactor: 0.95,
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Header: friend count
              Text(
                '${friendState.friends.length} / 20 người bạn',
                style: AppTextStyles.xlBold.copyWith(
                  color: AppColors.bw100,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                'Mời một người bạn để tiếp tục',
                style: AppTextStyles.baseBold.copyWith(
                  color: AppColors.bw500,
                ),
                textAlign: TextAlign.center,
              ),
              // Hiển thị lỗi stream (network, permission, rules) để
              // user biết dữ liệu có thể chưa đầy đủ. Tự ẩn khi
              // stream recover.
              if (friendState.errorMessage != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    friendState.errorMessage!,
                    style: AppTextStyles.smSemiBold.copyWith(
                      color: AppColors.error500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _buildSearchBar(currentUid),
              ),
              const SizedBox(height: 26),
              // Content sections
              if (!_isSearchExpanded)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pending requests section
                        if (friendState.pendingRequests.isNotEmpty) ...[
                          _buildSectionHeader(
                            iconPath: 'assets/icons/ic_users_round.svg',
                            title: 'Yêu cầu kết bạn',
                          ),
                          const SizedBox(height: 16),
                          ...friendState.pendingRequests.map(
                            (request) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildRequestItem(
                                request,
                                currentUid,
                              ),
                            ),
                          ),
                          const SizedBox(height: 46),
                        ],
                        // Sent requests section (outgoing, chưa accept)
                        // Lọc bỏ optimistic items (__optimistic_*) — chỉ hiển
                        // requests đã được Firestore xác nhận.
                        Builder(
                          builder: (context) {
                            final confirmed = friendState.sentRequests
                                .where(
                                  (r) => !r.requestId.startsWith(
                                    '__optimistic_',
                                  ),
                                )
                                .toList();
                            if (confirmed.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                  iconPath: 'assets/icons/ic_user_round.svg',
                                  title: 'Lời mời đã gửi',
                                ),
                                const SizedBox(height: 16),
                                ...confirmed.map(
                                  (request) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 12,
                                    ),
                                    child: _buildSentRequestItem(
                                      request,
                                      currentUid,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 46),
                              ],
                            );
                          },
                        ),
                        // Friend list section
                        if (friendState.friends.isNotEmpty) ...[
                          _buildSectionHeader(
                            iconPath: 'assets/icons/ic_users_round.svg',
                            title: 'Bạn bè của bạn',
                          ),
                          const SizedBox(height: 16),
                          ...displayedFriends.map(
                            (friend) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildFriendItem(friend, currentUid),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // "Xem thêm" button với dividers
                          if (friendState.friends.length > 3)
                            _buildViewMoreButton(),
                          const SizedBox(height: 46),
                        ],
                        // Invite section
                        ..._buildInviteSection(currentUid),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              if (_isSearchExpanded)
                Expanded(
                  child: _buildSearchResults(friendState, currentUid),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.turquoise500),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSearchBar(String currentUid) {
    if (_isSearchExpanded) {
      return Row(
        children: [
          Expanded(
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.bw700,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_search.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      AppColors.bw200,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      cursorColor: AppColors.turquoise500,
                      onChanged: (value) => ref
                          .read(friendControllerProvider(currentUid).notifier)
                          .searchUser(value),
                      style: AppTextStyles.baseBold.copyWith(
                        color: AppColors.bw200,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tìm hoặc thêm bạn bè',
                        hintStyle: AppTextStyles.baseBold.copyWith(
                          color: AppColors.bw500,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _collapseSearch(currentUid),
            child: Text(
              'Hủy',
              style: AppTextStyles.baseBold.copyWith(
                color: AppColors.bw200,
              ),
            ),
          ),
        ],
      );
    }

    // Collapsed search bar — horizontal padding nhỏ để Row center tự nhiên
    // chứa icon + text "Thêm một người bạn mới" (~210dp) không overflow trên
    // Android 360dp. MainAxisAlignment.center đã tự căn giữa.
    return GestureDetector(
      onTap: _expandSearch,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.bw700,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/ic_search.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                AppColors.bw200,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Thêm một người bạn mới',
                style: AppTextStyles.baseBold.copyWith(
                  color: AppColors.bw200,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(FriendState friendState, String currentUid) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            iconPath: 'assets/icons/ic_user_search.svg',
            title: 'Thêm theo tên người dùng',
          ),
          const SizedBox(height: 16),
          _buildSearchResultBody(friendState, currentUid),
          const SizedBox(height: 46),
          ..._buildInviteSection(currentUid),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSearchResultBody(FriendState friendState, String currentUid) {
    if (friendState.searchQuery.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Text(
          'Nhập tên người dùng để tìm kiếm',
          style: AppTextStyles.baseBold.copyWith(color: AppColors.bw500),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (friendState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 8, bottom: 8),
          child: CircularProgressIndicator(color: AppColors.turquoise500),
        ),
      );
    }

    final result = friendState.searchResult;
    if (result == null) {
      return SizedBox(
        width: double.infinity,
        child: Text(
          'Không tìm thấy người dùng @${friendState.searchQuery}',
          style: AppTextStyles.baseBold.copyWith(color: AppColors.bw500),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Chờ friends stream emit lần đầu trước khi quyết định isFriend.
    // Nếu chưa initialized mà search result đã về, hiện shimmer chờ
    // để tránh button "Thêm" nhấp nháy thành "Bạn bè" ngay sau đó.
    if (!friendState.friendsInitialized) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 8, bottom: 8),
          child: CircularProgressIndicator(color: AppColors.turquoise500),
        ),
      );
    }

    final isSelf = result.uid == currentUid;
    final isFriend = friendState.friends.any((f) => f.uid == result.uid);
    final sentRequest = friendState.sentRequests
        .where((r) => r.receiverId == result.uid)
        .firstOrNull;
    return _buildSearchResultItem(
      user: result,
      currentUid: currentUid,
      isSelf: isSelf,
      isFriend: isFriend,
      sentRequest: sentRequest,
    );
  }

  Widget _buildSearchResultItem({
    required PublicProfile user,
    required String currentUid,
    required bool isSelf,
    required bool isFriend,
    FriendRequest? sentRequest,
  }) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          AppAvatar(
            imageUrl: user.avatarUrl,
            size: 50,
            ringColor: AppColors.bw300,
            fallbackText: user.displayName.isNotEmpty
                ? user.displayName[0].toUpperCase()
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: AppTextStyles.mdBold.copyWith(color: AppColors.bw100),
                ),
                Text(
                  '@${user.username}',
                  style:
                      AppTextStyles.smSemiBold.copyWith(color: AppColors.bw500),
                ),
              ],
            ),
          ),
          _buildSearchActionButton(
            user: user,
            currentUid: currentUid,
            isSelf: isSelf,
            isFriend: isFriend,
            sentRequest: sentRequest,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchActionButton({
    required PublicProfile user,
    required String currentUid,
    required bool isSelf,
    required bool isFriend,
    FriendRequest? sentRequest,
  }) {
    if (isSelf) {
      return Text(
        'Đây là tôi',
        style: AppTextStyles.smSemiBold.copyWith(color: AppColors.bw500),
      );
    }
    if (isFriend) {
      return Text(
        'Bạn bè',
        style: AppTextStyles.smSemiBold.copyWith(color: AppColors.turquoise500),
      );
    }
    // Outgoing request đang chờ → "Đã gửi", bấm để hủy lời mời.
    if (sentRequest != null) {
      return GestureDetector(
        onTap: () => ref
            .read(friendControllerProvider(currentUid).notifier)
            .cancelSentRequestsTo(user.uid),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bw700,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Text(
            'Đã gửi',
            style: AppTextStyles.smSemiBold.copyWith(
              color: AppColors.bw200,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => ref
          .read(friendControllerProvider(currentUid).notifier)
          .sendFriendRequest(user.uid),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.turquoise500,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: AppColors.bw800, size: 18),
            const SizedBox(width: 4),
            Text(
              'Thêm',
              style: AppTextStyles.smSemiBold.copyWith(
                color: AppColors.bw800,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String iconPath,
    required String title,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: SvgPicture.asset(
            iconPath,
            width: 20,
            height: 20,
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(
              AppColors.bw200,
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.baseBold.copyWith(
            color: AppColors.bw200,
          ),
        ),
      ],
    );
  }

  Widget _buildFriendItem(PublicProfile friend, String currentUid) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              final router = GoRouter.of(context);
              Navigator.of(context).pop();
              router.push('/friend-profile/${friend.uid}');
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppAvatar(
                  imageUrl: friend.avatarUrl,
                  size: 50,
                  ringColor: AppColors.turquoise500,
                  fallbackText: friend.displayName.isNotEmpty
                      ? friend.displayName[0].toUpperCase()
                      : null,
                ),
                const SizedBox(width: 16),
                Text(
                  friend.displayName,
                  style: AppTextStyles.mdBold.copyWith(
                    color: AppColors.bw100,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Remove button (X icon)
          SizedBox(
            width: 20,
            height: 20,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 20,
              tooltip: 'Gỡ kết bạn',
              icon: const Icon(Icons.close, color: AppColors.bw100),
              onPressed: () => _confirmUnfriend(friend, currentUid),
            ),
          ),
        ],
      ),
    );
  }

  /// Confirm + remove an accepted friend. Shows the shared destructive dialog;
  /// the actual delete + friendCount/feed cleanup runs in the controller and
  /// the onFriendshipDeleted Cloud Function.
  Future<void> _confirmUnfriend(
    PublicProfile friend,
    String currentUid,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Xóa ${friend.displayName} khỏi Meep của bạn?',
      body: 'Các bạn sẽ không còn có thể gửi ảnh cho nhau trên Meep. '
          'Lịch sử của bạn sẽ có thể phục hồi nếu các bạn thêm lại nhau.',
      cancelLabel: 'Lưu',
      confirmLabel: 'Xoá',
    );
    if (!confirmed || !mounted) return;
    await ref
        .read(friendControllerProvider(currentUid).notifier)
        .unfriend(friend.uid);
  }

  Widget _buildRequestItem(FriendRequest request, String currentUid) {
    final senderAsync = ref.watch(_senderProfileProvider(request.senderId));
    final sender = senderAsync.valueOrNull;
    final displayName = sender?.displayName ?? '...';

    return SizedBox(
      height: 50,
      child: Row(
        children: [
          AppAvatar(
            imageUrl: sender?.avatarUrl,
            size: 50,
            ringColor: AppColors.turquoise500,
            fallbackText: displayName.isNotEmpty && displayName != '...'
                ? displayName[0].toUpperCase()
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              displayName,
              style: AppTextStyles.mdBold.copyWith(color: AppColors.bw100),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Accept button
          GestureDetector(
            onTap: () => ref
                .read(friendControllerProvider(currentUid).notifier)
                .acceptFriendRequest(request.requestId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.turquoise500,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(
                'Chấp nhận',
                style: AppTextStyles.mdBold.copyWith(color: AppColors.bw900),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Decline button (X icon)
          SizedBox(
            width: 20,
            height: 20,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 20,
              icon: const Icon(Icons.close, color: AppColors.bw100),
              onPressed: () => ref
                  .read(friendControllerProvider(currentUid).notifier)
                  .declineFriendRequest(request.requestId),
            ),
          ),
        ],
      ),
    );
  }

  /// Outgoing request row — receiver's profile + "Đã gửi" (bấm để hủy lời mời).
  Widget _buildSentRequestItem(FriendRequest request, String currentUid) {
    final receiverAsync = ref.watch(_senderProfileProvider(request.receiverId));
    final receiver = receiverAsync.valueOrNull;
    final displayName = receiver?.displayName ?? '...';

    return SizedBox(
      height: 50,
      child: Row(
        children: [
          AppAvatar(
            imageUrl: receiver?.avatarUrl,
            size: 50,
            ringColor: AppColors.bw300,
            fallbackText: displayName.isNotEmpty && displayName != '...'
                ? displayName[0].toUpperCase()
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              displayName,
              style: AppTextStyles.mdBold.copyWith(color: AppColors.bw100),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Cancel sent request button
          GestureDetector(
            onTap: () => ref
                .read(friendControllerProvider(currentUid).notifier)
                .cancelSentRequestsTo(request.receiverId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bw700,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(
                'Đã gửi',
                style: AppTextStyles.smSemiBold.copyWith(
                  color: AppColors.bw200,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewMoreButton() {
    return GestureDetector(
      onTap: _toggleShowAllFriends,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.bw700,
            ),
          ),
          const SizedBox(width: 19),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bw700,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Text(
              _showAllFriends ? 'Thu gọn' : 'Xem thêm',
              style: AppTextStyles.mdBold.copyWith(
                color: AppColors.bw400,
              ),
            ),
          ),
          const SizedBox(width: 19),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.bw700,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInviteSection(String uid) {
    return [
      _buildSectionHeader(
        iconPath: 'assets/icons/ic_share.svg',
        title: 'Chia sẻ liên kết Meep của bạn',
      ),
      const SizedBox(height: 16),
      _buildInviteItem(
        iconPath: 'assets/icons/ic_link.svg',
        label: 'Liên kết của bạn',
        hasArrow: false,
        showCheckmark: _linkCopied,
        onTap: () => _copyLink(uid),
      ),
      const SizedBox(height: 12),
      _buildInviteItem(
        iconPath: 'assets/icons/ic_logo_messenger.svg',
        label: 'Messenger',
        hasArrow: true,
        onTap: () => _shareInviteLink(uid),
      ),
      const SizedBox(height: 12),
      _buildInviteItem(
        iconPath: 'assets/icons/ic_logo_instagram.svg',
        label: 'Tin nhắn Instagram',
        hasArrow: true,
        onTap: () => _shareInviteLink(uid),
      ),
      const SizedBox(height: 12),
      _buildInviteItem(
        iconPath: 'assets/icons/ic_logo_instagram.svg',
        label: 'Tin Instagram',
        hasArrow: true,
        onTap: () => _shareInviteLink(uid),
      ),
      const SizedBox(height: 12),
      _buildInviteItem(
        iconPath: 'assets/icons/ic_logo_sms.svg',
        label: 'Tin nhắn',
        hasArrow: true,
        onTap: () => _shareInviteLink(uid),
      ),
    ];
  }

  Widget _buildInviteItem({
    String? iconPath,
    required String label,
    required bool hasArrow,
    bool showCheckmark = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            // Avatar với ring bw300
            if (showCheckmark)
              // Hiển thị checkmark thay vì icon
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: AppColors.bw300,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check,
                    color: AppColors.success500,
                    size: 24,
                  ),
                ),
              )
            else if (iconPath != null)
              // Logo nằm trọn trong vòng tròn 50px, chừa padding 2px cho border
              // và bọc ClipOval rõ ràng để logo không đè viền hoặc tràn ra ngoài.
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.bw300,
                    width: 2,
                  ),
                  color: AppColors.bw900,
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: iconPath.contains('ic_link')
                      ? Center(
                          child: SvgPicture.asset(
                            iconPath,
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Transform.scale(
                          scale:
                              1.25, // Phóng to logo SVG lên 25% để lấp đầy tràn viền, bo tròn đẹp
                          child: SvgPicture.asset(
                            iconPath,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                ),
              )
            else
              // Circle trống với ring (không có icon)
              const AppAvatar(
                size: 50,
                ringColor: AppColors.bw300,
                fallbackText: null,
              ),
            const SizedBox(width: 16),
            // Label
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.mdSemiBold.copyWith(
                  color: AppColors.bw100,
                ),
              ),
            ),
            // Arrow (không hiển thị checkmark ở đây nữa)
            if (hasArrow)
              const Icon(Icons.chevron_right, color: AppColors.bw100, size: 20),
          ],
        ),
      ),
    );
  }
}
