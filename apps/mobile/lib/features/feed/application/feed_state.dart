import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:meep/shared/models/post.dart';

part 'feed_state.freezed.dart';

@freezed
class FeedState with _$FeedState {
  const factory FeedState({
    @Default([]) List<Post> posts,
    @Default(false) bool isLoadingMore,
    @Default(false) bool hasMore,

    /// Pagination cursor = postId của doc cuối trang trước (typed String thay
    /// vì Firestore DocumentSnapshot — không rò SDK type lên UI). Null = trang
    /// đầu. Repository tự resolve cursor → startAfter khi pagination wire.
    String? lastDocId,
  }) = _FeedState;
}
