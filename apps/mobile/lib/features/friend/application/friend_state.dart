import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/friend/data/friend_request.dart';

part 'friend_state.freezed.dart';

@freezed
class FriendState with _$FriendState {
  const factory FriendState({
    @Default([]) List<UserProfile> friends,
    @Default([]) List<FriendRequest> pendingRequests,
    @Default([]) List<FriendRequest> sentRequests,
    UserProfile? searchResult,
    @Default('') String searchQuery,
    @Default(false) bool isLoading,
    String? errorMessage,
    // true sau khi friends stream emit lần đầu — dùng để tránh race condition:
    // nếu search result về trước stream, không hiển thị nút "Thêm" vội
    // cho đến khi friendsInitialized = true.
    @Default(false) bool friendsInitialized,
  }) = _FriendState;
}
