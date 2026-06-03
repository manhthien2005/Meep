import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/features/chat/application/chat_controller.dart';
import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/features/feed/data/post.dart';
import 'package:meep/shared/widgets/app_avatar.dart';
import 'package:meep/shared/widgets/post_card.dart';
import 'package:meep/shared/widgets/share_modal.dart';

class FeedSection extends ConsumerWidget {
  const FeedSection({super.key, this.filterUid});

  final String? filterUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = filterUid != null ? FeedFilter.person : FeedFilter.all;
    final feedAsync = ref.watch(
      feedControllerProvider(filter: filter, filterUid: filterUid),
    );

    return feedAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.turquoise500),
          ),
        ),
      ),
      error: (_, __) => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Không tải được feed. Kiểm tra kết nối.',
              style: TextStyle(color: AppColors.bw500),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (state) {
        if (state.posts.isEmpty) {
          return const SliverToBoxAdapter(child: _EmptyState());
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= state.posts.length) return const _FeedFooter();

              final post = state.posts[index];

              // Trigger prefetch after frame — never call state mutation during build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref
                    .read(
                      feedControllerProvider(
                        filter: filter,
                        filterUid: filterUid,
                      ).notifier,
                    )
                    .onItemVisible(index);
              });

              final currentUid = FirebaseAuth.instance.currentUser?.uid;
              final isOwn = post.authorId == currentUid;

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: isOwn
                    ? OwnPostCard(post: post)
                    : FriendPostCard(post: post),
              );
            },
            childCount: state.posts.length + 1,
          ),
        );
      },
    );
  }
}

/// Shared header row used by both own and friend posts. Friend variant shows
/// the avatar + `<name> d thg M`; own variant shows just `Bạn d thg M` (no
/// avatar — the user already sees themselves on every screen, so it would
/// just be visual noise).
class PostHeaderRow extends StatelessWidget {
  const PostHeaderRow({super.key, required this.post, required this.isOwn});

  final Post post;
  final bool isOwn;

  static String _formatDate(DateTime dt) => '${dt.day} thg ${dt.month}';

  @override
  Widget build(BuildContext context) {
    final nameText = isOwn ? 'Bạn' : post.authorName;
    final dateText = ' ${_formatDate(post.createdAt)}';
    final label = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: nameText,
            style: const TextStyle(color: AppColors.bw100),
          ),
          TextSpan(
            text: dateText,
            style: const TextStyle(color: AppColors.bw500),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        fontFamily: 'Nunito',
      ),
    );

    if (isOwn) {
      return Center(child: label);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppAvatar(
          imageUrl: post.authorAvatarUrl,
          size: 28,
          fallbackText: post.authorName.isNotEmpty
              ? post.authorName[0].toUpperCase()
              : null,
        ),
        const SizedBox(width: 8),
        Flexible(child: label),
      ],
    );
  }
}

/// Activity pill — own posts only ("Chưa có hoạt động nào!"). Hug content,
/// transparent rounded background. Centered in its parent.
class ActivityPill extends StatelessWidget {
  const ActivityPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x66252627),
        borderRadius: BorderRadius.circular(40),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            color: AppColors.bw400,
            size: 18,
          ),
          SizedBox(width: 10),
          Text(
            'Chưa có hoạt động nào!',
            style: TextStyle(
              color: AppColors.bw400,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }
}

/// Friend message bar — 2-state inline composer trên Feed:
/// - **Collapsed** (mặc định): text "Gửi tin nhắn..." + 3 emoji quick-react +
///   icon add-reaction. Tap vùng text trái → expand sang TextField.
/// - **Expanded:** TextField focused + send button. Tap-outside hoặc submit →
///   collapse. Submit gọi `ChatController.sendMessageFromFeed(postId, authorId)`
///   để tạo/lookup direct conversation rồi append message. KHÔNG navigate —
///   theo spec, user vẫn ở Feed sau khi gửi (input chỉ collapse).
///
/// Emoji quick-react ở collapsed state hiện chưa wire (chờ T5 reactions —
/// `tasks/todo-chat.md`). Trong PR này chỉ wire text → send flow.
class FriendMessageBar extends ConsumerStatefulWidget {
  const FriendMessageBar({
    super.key,
    required this.postId,
    required this.authorId,
    this.spaceId,
  });

  /// postId — context cho `sendMessageFromFeed` (lưu quotedPostId tương lai).
  final String postId;

  /// authorId — peer uid để `getOrCreateConversation` tính pairId.
  /// Khi [spaceId] != null, authorId chỉ dùng tham chiếu — message forward
  /// sang space chat thay vì 1-1.
  final String authorId;

  /// spaceId — nếu post được share trong Space, reply forward sang group
  /// conversation của Space (`conversationId == spaceId`). Null = post
  /// all-friends → forward 1-1 với author.
  final String? spaceId;

  @override
  ConsumerState<FriendMessageBar> createState() => _FriendMessageBarState();
}

class _FriendMessageBarState extends ConsumerState<FriendMessageBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _expanded = false;
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _expand() {
    setState(() => _expanded = true);
    // Defer requestFocus để widget render TextField xong trước.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  void _collapse() {
    _focusNode.unfocus();
    _controller.clear();
    setState(() => _expanded = false);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    final conversationId =
        await ref.read(chatControllerProvider.notifier).sendMessageFromFeed(
              postId: widget.postId,
              authorId: widget.authorId,
              text: text,
              spaceId: widget.spaceId,
            );
    if (!mounted) return;
    setState(() => _isSending = false);
    if (conversationId != null) {
      _collapse();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi tin nhắn'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Controller đã set errorMessage trong state — read để show.
      final err = ref.read(chatControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Không gửi được tin nhắn'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final screenH = MediaQuery.sizeOf(context).height;
    return Container(
      height: screenH * 0.07,
      width: screenW * 0.8,
      decoration: BoxDecoration(
        color: AppColors.bw800,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _expanded ? _buildExpanded(screenW) : _buildCollapsed(screenW),
    );
  }

  Widget _buildCollapsed(double screenW) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _expand,
            child: Text(
              'Gửi tin nhắn...',
              style: TextStyle(
                color: AppColors.bw100,
                fontSize: screenW * 0.042,
                fontWeight: FontWeight.w800,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ),
        const Text('💙', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        const Text('😂', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        const Text('🥰', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        const Icon(
          Icons.add_reaction_outlined,
          color: AppColors.bw500,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildExpanded(double screenW) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: !_isSending,
            maxLength: 500,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            onTapOutside: (_) {
              if (_controller.text.trim().isEmpty) _collapse();
            },
            decoration: InputDecoration(
              hintText: 'Gửi tin nhắn...',
              hintStyle: TextStyle(
                color: AppColors.bw500,
                fontSize: screenW * 0.042,
                fontWeight: FontWeight.w800,
                fontFamily: 'Nunito',
              ),
              border: InputBorder.none,
              isCollapsed: true,
              counterText: '',
            ),
            style: TextStyle(
              color: AppColors.bw100,
              fontSize: screenW * 0.042,
              fontWeight: FontWeight.w800,
              fontFamily: 'Nunito',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (_controller.text.trim().isNotEmpty)
          GestureDetector(
            onTap: _send,
            child: Icon(
              Icons.send_rounded,
              color: _isSending ? AppColors.bw500 : AppColors.turquoise500,
              size: 22,
            ),
          )
        else
          GestureDetector(
            onTap: _collapse,
            child: const Icon(
              Icons.close,
              color: AppColors.bw500,
              size: 20,
            ),
          ),
      ],
    );
  }
}

class FriendPostCard extends StatelessWidget {
  const FriendPostCard({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return PostCard(
      post: post,
      onLongPress: () => _showShareModal(context, post, isAuthor: false),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PostHeaderRow(post: post, isOwn: false),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: FriendMessageBar(
              postId: post.postId,
              authorId: post.authorId,
              spaceId: post.spaceId,
            ),
          ),
        ],
      ),
    );
  }
}

class OwnPostCard extends StatelessWidget {
  const OwnPostCard({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return PostCard(
      post: post,
      onLongPress: () => _showShareModal(context, post, isAuthor: true),
      footer: OwnPostFooter(post: post),
    );
  }
}

/// Author label + activity pill shown under the photo on own posts.
/// Extracted so [OwnPostPage] can position it at the bottom of the screen
/// (separately from the photo).
class OwnPostFooter extends StatelessWidget {
  const OwnPostFooter({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PostHeaderRow(post: post, isOwn: true),
        const SizedBox(height: 12),
        const ActivityPill(),
      ],
    );
  }
}

/// Own post variant for the home PageView: photo near the top, footer
/// (label + activity pill) pinned near the taskbar at ~4% screen height.
/// Used instead of [OwnPostCard] when the post fills a full screen page.
class OwnPostPage extends StatelessWidget {
  const OwnPostPage({super.key, required this.post});

  final Post post;

  /// Spacing from the bottom of the screen (above the taskbar). Tuned by
  /// product preference; pill should sit just above the nav bar.
  static const double _bottomGapRatio = 0.04;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PostCard(
          post: post,
          onLongPress: () => _showShareModal(context, post, isAuthor: true),
        ),
        // 1% of screen height — author pill sits just under the photo.
        // The PostCard's internal photo→footer gap only runs when a footer is
        // passed in; here we pass none (so the footer can be pinned near the
        // taskbar), so the gap is applied explicitly at this level instead.
        SizedBox(height: screenH * 0.01),
        PostHeaderRow(post: post, isOwn: true),
        const Spacer(),
        const ActivityPill(),
        SizedBox(height: screenH * _bottomGapRatio),
      ],
    );
  }
}

/// Friend post variant for the home PageView. Mirrors [OwnPostPage] so both
/// post types share the same vertical rhythm and horizontal gutters: photo
/// on top, header + message bar pinned at ~4% above the taskbar.
class FriendPostPage extends StatelessWidget {
  const FriendPostPage({super.key, required this.post});

  final Post post;

  static const double _bottomGapRatio = 0.04;
  static const double _gutter = 6;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PostCard(
          post: post,
          onLongPress: () => _showShareModal(context, post, isAuthor: false),
        ),
        // 1% screen-height gap — author pill sits just under the photo,
        // matching the OwnPostPage rhythm.
        SizedBox(height: screenH * 0.01),
        PostHeaderRow(post: post, isOwn: false),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _gutter),
          child: FriendMessageBar(
            postId: post.postId,
            authorId: post.authorId,
            spaceId: post.spaceId,
          ),
        ),
        SizedBox(height: screenH * _bottomGapRatio),
      ],
    );
  }
}

void _showShareModal(
  BuildContext context,
  Post post, {
  required bool isAuthor,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => ShareModal(post: post, isAuthor: isAuthor),
  );
}

class _FeedFooter extends StatelessWidget {
  const _FeedFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'Đã hiển thị tất cả',
          style: TextStyle(
            color: AppColors.bw500,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Column(
        children: [
          Icon(Icons.photo_camera_outlined, color: AppColors.bw600, size: 48),
          SizedBox(height: 16),
          Text(
            'Chưa có ảnh nào',
            style: TextStyle(
              color: AppColors.bw400,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'Nunito',
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Chụp ảnh đầu tiên và gửi cho bạn bè!',
            style: TextStyle(
              color: AppColors.bw600,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
