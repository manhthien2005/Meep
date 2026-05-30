import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/core/utils/pair_id.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/friend/application/friend_state.dart';
import 'package:meep/features/friend/data/friend_repository.dart';
import 'package:meep/features/friend/data/friend_request.dart';
import 'package:meep/features/friend/data/friend_request_repository.dart';

part 'friend_controller.g.dart';

@Riverpod(keepAlive: true)
FriendRepository friendRepository(Ref ref) => throw UnimplementedError(
      'friendRepositoryProvider must be overridden — '
      'wire FirebaseFriendRepository in main.dart (TODO: F/T1/ThienPDM)',
    );

@Riverpod(keepAlive: true)
FriendRequestRepository friendRequestRepository(Ref ref) =>
    throw UnimplementedError(
      'friendRequestRepositoryProvider must be overridden — '
      'wire FirebaseFriendRequestRepository in main.dart (TODO: F/T1/ThienPDM)',
    );

@riverpod
class FriendController extends _$FriendController {
  Timer? _searchDebounce;
  StreamSubscription<List<UserProfile>>? _friendsSub;
  StreamSubscription<List<FriendRequest>>? _requestsSub;

  @override
  FriendState build(String uid) {
    ref.onDispose(() {
      _searchDebounce?.cancel();
      _friendsSub?.cancel();
      _requestsSub?.cancel();
    });

    // Watch friends stream
    _friendsSub = ref.read(friendRepositoryProvider).watchFriends(uid).listen(
      (friends) {
        state = state.copyWith(friends: friends);
      },
      onError: (Object error) {
        state = state.copyWith(
          errorMessage: 'Không thể tải danh sách bạn bè: $error',
        );
      },
    );

    // Watch pending requests stream
    _requestsSub = ref
        .read(friendRequestRepositoryProvider)
        .watchPendingRequests(uid)
        .listen(
      (requests) {
        state = state.copyWith(pendingRequests: requests);
      },
      onError: (Object error) {
        state = state.copyWith(
          errorMessage: 'Không thể tải yêu cầu kết bạn: $error',
        );
      },
    );

    return const FriendState();
  }

  Future<void> searchUser(String query) async {
    final trimmed = query.trim();

    // Update search query immediately
    state = state.copyWith(searchQuery: trimmed, errorMessage: null);

    // Clear result if query is empty
    if (trimmed.isEmpty) {
      state = state.copyWith(searchResult: null);
      _searchDebounce?.cancel();
      return;
    }

    // Debounce 500ms
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      state = state.copyWith(isLoading: true);

      try {
        final result =
            await ref.read(friendRepositoryProvider).searchUser(trimmed);
        state = state.copyWith(
          searchResult: result,
          isLoading: false,
          errorMessage: null,
        );
      } catch (error) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Không thể tìm kiếm: $error',
        );
      }
    });
  }

  Future<void> sendFriendRequest(String receiverUid) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final currentUid = ref.read(currentUidProvider).requireValue!;
      await ref.read(friendRequestRepositoryProvider).sendFriendRequest(
            senderUid: currentUid,
            receiverUid: receiverUid,
          );

      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể gửi lời mời: $error',
      );
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await ref
          .read(friendRequestRepositoryProvider)
          .acceptFriendRequest(requestId);

      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
      );
    } catch (error) {
      // Check for "max 20 friends" error
      final errorMsg = error.toString();
      if (errorMsg.contains('20') || errorMsg.contains('FAILED_PRECONDITION')) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Bạn đã có 20 bạn bè, không thể chấp nhận thêm',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Không thể chấp nhận lời mời: $error',
        );
      }
    }
  }

  Future<void> cancelFriendRequest(String requestId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await ref
          .read(friendRequestRepositoryProvider)
          .cancelFriendRequest(requestId);

      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể hủy lời mời: $error',
      );
    }
  }

  Future<void> declineFriendRequest(String requestId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await ref
          .read(friendRequestRepositoryProvider)
          .declineFriendRequest(requestId);

      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể từ chối lời mời: $error',
      );
    }
  }

  Future<void> unfriend(String friendUid) async {
    final currentUid = ref.read(currentUidProvider).requireValue!;
    final pairId = pairIdOf(currentUid, friendUid);

    // Optimistic update: remove friend immediately
    final originalFriends = state.friends;
    state = state.copyWith(
      friends: originalFriends.where((f) => f.uid != friendUid).toList(),
      errorMessage: null,
    );

    try {
      await ref.read(friendRepositoryProvider).unfriend(pairId);
    } catch (error) {
      // Revert on error
      state = state.copyWith(
        friends: originalFriends,
        errorMessage: 'Không thể xóa bạn: $error',
      );
    }
  }
}
