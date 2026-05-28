import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/feed/data/post.dart';
import 'package:meep/features/feed/data/post_repository.dart';
import 'package:meep/features/feed/data/storage_repository.dart';

part 'feed_controller.g.dart';

/// Feed filter mode.
enum FeedFilter {
  all,

  /// Filter by a specific friend's uid.
  person,

  /// Reserved — Space feed (Space module implements).
  space,
}

// ignore: avoid_classes_with_only_static_members
class FeedState {
  const FeedState._();
}

@Riverpod(keepAlive: true)
PostRepository postRepository(PostRepositoryRef ref) =>
    throw UnimplementedError(
      'postRepositoryProvider must be overridden — '
      'wire FirestorePostRepository in main.dart (TODO: FE/T1/KhoaLND)',
    );

@Riverpod(keepAlive: true)
StorageRepository storageRepository(StorageRepositoryRef ref) =>
    throw UnimplementedError(
      'storageRepositoryProvider must be overridden — '
      'wire FirebaseStorageRepository in main.dart (TODO: FE/T2/KhoaLND)',
    );

@riverpod
class FeedController extends _$FeedController {
  @override
  Future<List<Post>> build({
    FeedFilter filter = FeedFilter.all,
    // filterUid: used with FeedFilter.person — filter by friend's uid
    String? filterUid,
    // filterSpaceId: used with FeedFilter.space — query feed WHERE spaceId == filterSpaceId
    String? filterSpaceId,
  }) async {
    // TODO(FE/T3/KhoaLND): implement watchFeed stream
    throw UnimplementedError('FeedController.build — TODO: FE/T3/KhoaLND');
  }

  Future<void> loadMore() async {
    // TODO(FE/T4/KhoaLND): implement pagination
    throw UnimplementedError('loadMore — TODO: FE/T4/KhoaLND');
  }
}
