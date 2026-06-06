import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/feed/application/feed_state.dart';
import 'package:meep/features/feed/data/firebase_post_repository.dart';
import 'package:meep/features/feed/data/firebase_storage_repository.dart';
import 'package:meep/features/feed/data/post.dart';
import 'package:meep/features/feed/data/post_repository.dart';
import 'package:meep/features/feed/data/storage_repository.dart';
import 'package:meep/features/widget/application/widget_data_service.dart';

part 'feed_controller.g.dart';

/// Feed filter mode.
enum FeedFilter {
  all,

  /// Filter by a specific friend's uid.
  person,

  /// Reserved — Space feed (Space module implements).
  space,
}

@Riverpod(keepAlive: true)
PostRepository postRepository(Ref ref) =>
    FirebasePostRepository(FirebaseFirestore.instance);

@Riverpod(keepAlive: true)
StorageRepository storageRepository(Ref ref) =>
    FirebaseStorageRepository(FirebaseStorage.instance);

/// Async notifier — build() returns `Future<FeedState>` so `AsyncValue.when()` works in UI.
///
/// M2: uses watchFeed stream (first 10 posts, no cursor pagination).
/// TODO(FE/T6/KhoaLND): full cursor pagination needs PostRepository.getPage() —
///   requires leader to add method to interface first.
@riverpod
class FeedController extends _$FeedController {
  static const int _prefetchAt = 4;

  @override
  Future<FeedState> build({
    FeedFilter filter = FeedFilter.all,
    // filterUid: used with FeedFilter.person — filter by friend's uid
    String? filterUid,
    // filterSpaceId: used with FeedFilter.space — query feed WHERE spaceId == filterSpaceId
    String? filterSpaceId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final repo = ref.read(postRepositoryProvider);

    // [DEBUG/Space Feed] Log lúc build provider — anh đối chiếu với
    // log từ UI để xác nhận FilterDropdown đã dispatch đúng mode.
    debugPrint(
      '[Space Feed] FeedController.build — filter=$filter, '
      'filterUid=$filterUid, filterSpaceId=$filterSpaceId, currentUid=$uid',
    );

    // Pass spaceId xuống repo khi filter là Space — repo branch sang
    // _watchSpaceFeed query thẳng /posts where spaceId == X. Khi filter
    // là all/person, spaceId truyền null → repo trả feed chung (đã loại
    // Space posts).
    final repoSpaceId = filter == FeedFilter.space ? filterSpaceId : null;

    if (filter == FeedFilter.space && filterSpaceId == null) {
      debugPrint(
        '[Space Feed] CẢNH BÁO: filter=space nhưng filterSpaceId=null. '
        'Sẽ rơi vào nhánh feed chung thay vì Space feed → bug ở provider/UI.',
      );
    }

    // Live stream so posts appear once the CF fan-out writes the feed doc —
    // no manual refresh needed. A single subscription drives both the initial
    // future (first emission) and subsequent state updates.
    final completer = Completer<FeedState>();
    final sub = repo.watchFeed(uid, spaceId: repoSpaceId).listen(
      (posts) {
        // FeedFilter.space: repo đã filter sẵn theo spaceId → posts pass through.
        // FeedFilter.person: client-side filter theo authorId.
        // FeedFilter.all: posts từ feed chung (đã loại Space posts ở repo).
        final filtered = switch (filter) {
          FeedFilter.person when filterUid != null =>
            posts.where((p) => p.authorId == filterUid).toList(),
          _ => posts,
        };
        debugPrint(
          '[Space Feed] FeedController emit — filter=$filter, '
          'posts từ repo=${posts.length}, sau client filter=${filtered.length}',
        );
        final feedState = FeedState(posts: filtered, hasMore: false);
        if (completer.isCompleted) {
          state = AsyncData(feedState);
        } else {
          completer.complete(feedState);
        }

        // Update home-screen widget with latest all-friends post.
        // Best-effort — widget failures must not crash the feed.
        if (filter == FeedFilter.all && filtered.isNotEmpty) {
          _updateWidget(ref, filtered.first);
        }
      },
      onError: (Object e, StackTrace st) {
        // [DEBUG/Space Feed] Đây là điểm cuối cùng error đi qua trước khi
        // UI hiện "Không tải được feed". Nếu anh thấy "Không tải được feed"
        // mà KHÔNG có log nào trước log này → error chưa được catch ở repo.
        debugPrint(
          '[Space Feed] FeedController nhận error từ repo — '
          'filter=$filter, filterSpaceId=$filterSpaceId, error=$e',
        );
        if (!completer.isCompleted) {
          completer.completeError(e, st);
        } else {
          state = AsyncError(e, st);
        }
      },
    );
    ref.onDispose(sub.cancel);

    return completer.future;
  }

  // TODO(FE/T6/KhoaLND): loadMore requires PostRepository.getPage() interface method.
  // Blocked until leader adds paginated query to PostRepository contract.
  Future<void> loadMore() async {}

  void onItemVisible(int index) {
    final posts = state.valueOrNull?.posts ?? [];
    if (index >= posts.length - _prefetchAt) loadMore();
  }

  void _updateWidget(Ref ref, Post post) {
    // Fire-and-forget. Sync `try` ngoài chỉ catch lỗi đồng bộ của
    // `ref.read` (vd provider scope sai) — async error trong Future của
    // `updateWidgetData` cần `.catchError`, nếu không sẽ trở thành
    // unhandled async exception. `_safePoke` bên trong đã nuốt
    // PlatformException/MissingPluginException, nên `.catchError` chỉ là
    // safety net cho future-proof.
    try {
      unawaited(
        ref
            .read(widgetDataServiceProvider)
            .updateWidgetData(
              postId: post.postId,
              imageUrl: post.coverImageUrl,
              authorAvatarUrl: post.authorAvatarUrl,
              caption: post.caption,
              captionType: post.captionType?.name,
            )
            .catchError((Object e, StackTrace st) {
          debugPrint('[FeedController] widget update failed: $e\n$st');
        }),
      );
    } catch (e, st) {
      // Best-effort — widget update must not crash the feed stream.
      debugPrint('[FeedController] widget update sync error: $e\n$st');
    }
  }
}
