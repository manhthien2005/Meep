import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/hex_color.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/chat/application/chat_controller.dart';
import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/shared/models/post.dart';
import 'package:meep/features/reaction/application/reaction_controller.dart';
import 'package:meep/features/reaction/data/reaction.dart';
import 'package:meep/features/reaction/presentation/emoji_picker_sheet.dart';
import 'package:meep/features/reaction/presentation/reaction_list_sheet.dart';
import 'package:meep/features/feed/presentation/widgets/feed_error_view.dart';
import 'package:meep/features/space/application/space_controller.dart';
import 'package:meep/shared/widgets/app_avatar.dart';
import 'package:meep/shared/widgets/post_card.dart';
import 'package:meep/shared/widgets/share_modal.dart';

part 'feed_section_header_widgets.dart';
part 'feed_section_message_bar.dart';
part 'feed_section_post_cards.dart';
part 'feed_section_states.dart';

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
      error: (_, __) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FeedErrorView(
            onRetry: () => ref.invalidate(
              feedControllerProvider(filter: filter, filterUid: filterUid),
            ),
          ),
        ),
      ),
      data: (state) {
        if (state.posts.isEmpty) {
          return const SliverToBoxAdapter(child: _EmptyState());
        }

        // uid resolve một lần qua auth abstraction (currentUidProvider) thay vì
        // Firebase Auth singleton trong itemBuilder — giữ layering + tránh
        // re-read mỗi tile.
        final currentUid = ref.watch(currentUidProvider).valueOrNull;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= state.posts.length) return const _FeedFooter();

              final post = state.posts[index];
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
