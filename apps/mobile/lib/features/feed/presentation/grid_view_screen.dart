import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_proportions.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/features/feed/application/feed_filter_controller.dart';
import 'package:meep/features/feed/data/post.dart';
import 'package:meep/features/feed/presentation/feed_filter_dropdown.dart';
import 'package:meep/features/feed/presentation/grid_photo_tile.dart';
import 'package:meep/features/space/application/space_controller.dart';

/// Grid view 3-cột tất cả ảnh đã post của filter hiện tại. Mở từ nút
/// grid trên Taskbar feed (HomeScreen embedded). Filter (Mọi người / Bạn /
/// friend / Space) sync với HomeScreen qua `feedFilterControllerProvider`.
class GridViewScreen extends ConsumerWidget {
  const GridViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(feedFilterControllerProvider);
    final FeedFilter mode;
    if (selection.spaceId != null) {
      mode = FeedFilter.space;
    } else if (selection.authorUid != null) {
      mode = FeedFilter.person;
    } else {
      mode = FeedFilter.all;
    }

    // [DEBUG/Space Feed] Log mỗi lần Grid rebuild để đối chiếu với Home.
    debugPrint(
      '[Space Feed] GridViewScreen build — mode=$mode, '
      'authorUid=${selection.authorUid}, spaceId=${selection.spaceId}',
    );

    final feedAsync = ref.watch(
      feedControllerProvider(
        filter: mode,
        filterUid: selection.authorUid,
        filterSpaceId: selection.spaceId,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.bw900,
      body: SafeArea(
        child: Column(
          children: [
            const _GridTopBar(),
            Expanded(
              child: feedAsync.when(
                loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.turquoise500),
                ),
                error: (e, st) {
                  // [DEBUG/Space Feed] Grid render error — log để biết
                  // user thấy "Không tải được ảnh" do nguyên nhân nào.
                  debugPrint(
                    '[Space Feed] GridViewScreen render ERROR — '
                    'mode=$mode, spaceId=${selection.spaceId}, error=$e',
                  );
                  debugPrint('[Space Feed] Stacktrace UI Grid: $st');
                  return const Center(
                    child: Text(
                      'Không tải được ảnh',
                      style: TextStyle(color: AppColors.bw500),
                    ),
                  );
                },
                data: (state) {
                  debugPrint(
                    '[Space Feed] GridViewScreen render DATA — '
                    'mode=$mode, posts=${state.posts.length}',
                  );
                  return state.posts.isEmpty
                      ? const Center(
                          child: Text(
                            'Chưa có ảnh',
                            style: TextStyle(color: AppColors.bw500),
                          ),
                        )
                      : _Grid(posts: state.posts);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.posts});

  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    return GridView.builder(
      padding: EdgeInsets.all(AppProportions.gridHPadding(screenW)),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppProportions.gridColumns,
        crossAxisSpacing: AppProportions.gridGap,
        mainAxisSpacing: AppProportions.gridGap,
      ),
      itemCount: posts.length,
      itemBuilder: (_, i) => GridPhotoTile(
        post: posts[i],
        onTap: () => _openDetail(context, i),
      ),
    );
  }

  // Push sang PhotoDetailScreen full-screen (shared widget). Route
  // `/grid/photo/:postId` wire borderColor từ Space + onShareTap mở
  // ShareModal — xem `_GridPhotoDetailRoute` trong app_router.dart.
  void _openDetail(BuildContext context, int index) {
    final post = posts[index];
    context.push(
      '/grid/photo/${post.postId}',
      extra: <String, Object>{
        'posts': posts,
        'index': index,
      },
    );
  }
}

/// Topbar: back ← | "[label] ▾" pill | spacer phải (40px cho symmetric).
/// Tap pill mở `FeedFilterDropdown` — selection sync qua provider, Home
/// và Grid cùng nhìn thấy state mới khi quay lại.
class _GridTopBar extends ConsumerWidget {
  const _GridTopBar();

  Future<void> _openFilterDropdown(
    BuildContext context,
    WidgetRef ref,
    String currentUid,
    String selectedLabel,
  ) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Đóng bộ lọc',
      barrierColor: const Color(0x73000000),
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (_, __, ___) => FeedFilterDropdown(
        currentUid: currentUid,
        selectedLabel: selectedLabel,
        onFilterSelected: (authorUid, label) {
          final notifier = ref.read(feedFilterControllerProvider.notifier);
          if (authorUid == null) {
            notifier.selectAll();
          } else {
            notifier.selectAuthor(authorUid, label);
          }
        },
        onSpaceFilterSelected: (space) {
          ref.read(feedFilterControllerProvider.notifier).selectSpace(space);
          ref.read(currentSpaceProvider.notifier).select(space);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(currentUidProvider).valueOrNull;
    final label = ref.watch(
      feedFilterControllerProvider.select((s) => s.label),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Quay lại',
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.arrow_back, color: AppColors.bw100),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: currentUid == null
                ? null
                : () => _openFilterDropdown(context, ref, currentUid, label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bw700.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style:
                        AppTextStyles.mdBold.copyWith(color: AppColors.bw100),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.bw200,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Symmetric spacer — same width as back icon (24) + room for tap area.
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}
