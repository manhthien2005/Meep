import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/friend/application/friend_state.dart';
import 'package:meep/features/friend/data/friend_repository.dart';
import 'package:meep/features/friend/data/friend_request_repository.dart';

part 'friend_controller.g.dart';

@Riverpod(keepAlive: true)
FriendRepository friendRepository(Ref ref) => throw UnimplementedError(
      'friendRepositoryProvider must be overridden — '
      'wire FirestoreFriendRepository in main.dart (TODO: F/T1/ThienPDM)',
    );

@Riverpod(keepAlive: true)
FriendRequestRepository friendRequestRepository(Ref ref) =>
    throw UnimplementedError(
      'friendRequestRepositoryProvider must be overridden — '
      'wire FirestoreFriendRequestRepository in main.dart (TODO: F/T1/ThienPDM)',
    );

@riverpod
class FriendController extends _$FriendController {
  @override
  FriendState build(String uid) {
    // TODO(F/T2/ThienPDM): implement watchFriends stream + watchPendingRequests
    // Listen to both streams and merge into FriendState
    return const FriendState();
  }

  Future<void> searchUser(String query) async {
    // TODO(F/T2/ThienPDM): implement user search with 500ms debounce
    // Call friendRepository.searchUser(query.toLowerCase())
    // Update state.searchResult + state.searchQuery
    throw UnimplementedError('searchUser — TODO: F/T2/ThienPDM');
  }

  Future<void> sendFriendRequest(String receiverUid) async {
    // TODO(F/T2/ThienPDM): implement sendFriendRequest
    // Call friendRequestRepository.sendFriendRequest
    throw UnimplementedError('sendFriendRequest — TODO: F/T2/ThienPDM');
  }

  Future<void> acceptFriendRequest(String requestId) async {
    // TODO(F/T2/ThienPDM): implement acceptFriendRequest
    // Call friendRequestRepository.acceptFriendRequest (calls CF)
    // Handle error "max 20 friends" → set state.errorMessage
    throw UnimplementedError('acceptFriendRequest — TODO: F/T2/ThienPDM');
  }

  Future<void> cancelFriendRequest(String requestId) async {
    // TODO(F/T2/ThienPDM): implement cancelFriendRequest
    throw UnimplementedError('cancelFriendRequest — TODO: F/T2/ThienPDM');
  }

  Future<void> declineFriendRequest(String requestId) async {
    // TODO(F/T2/ThienPDM): implement declineFriendRequest
    throw UnimplementedError('declineFriendRequest — TODO: F/T2/ThienPDM');
  }

  Future<void> unfriend(String pairId) async {
    // TODO(F/T2/ThienPDM): implement unfriend with optimistic update
    // Remove friend from state.friends immediately, then call repo
    throw UnimplementedError('unfriend — TODO: F/T2/ThienPDM');
  }
}
