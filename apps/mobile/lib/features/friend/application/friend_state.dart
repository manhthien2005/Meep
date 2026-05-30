import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/friend/data/friend_request.dart';

part 'friend_state.freezed.dart';

@freezed
class FriendState with _$FriendState {
  const factory FriendState({
    @Default([]) List<UserProfile> friends,
    @Default([]) List<FriendRequest> pendingRequests,
    UserProfile? searchResult,
    @Default('') String searchQuery,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _FriendState;
}
