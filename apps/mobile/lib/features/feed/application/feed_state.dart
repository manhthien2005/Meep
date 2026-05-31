import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:meep/features/feed/data/post.dart';

part 'feed_state.freezed.dart';

@freezed
class FeedState with _$FeedState {
  const factory FeedState({
    @Default([]) List<Post> posts,
    @Default(false) bool isLoadingMore,
    @Default(false) bool hasMore,
    DocumentSnapshot? lastDoc,
  }) = _FeedState;
}
