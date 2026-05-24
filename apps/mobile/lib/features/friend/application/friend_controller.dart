import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/friend/data/friend_repository.dart';
import 'package:meep/features/friend/data/friend_request.dart';
import 'package:meep/features/friend/data/friend_request_repository.dart';

part 'friend_controller.g.dart';

@Riverpod(keepAlive: true)
FriendRepository friendRepository(Ref ref) => throw UnimplementedError(
      'friendRepositoryProvider must be overridden — '
      'wire FirestoreFriendRepository in main.dart (TODO: F/T1/KhoaLND)',
    );

@Riverpod(keepAlive: true)
FriendRequestRepository friendRequestRepository(Ref ref) =>
    throw UnimplementedError(
      'friendRequestRepositoryProvider must be overridden — '
      'wire FirestoreFriendRequestRepository in main.dart (TODO: F/T1/KhoaLND)',
    );

@riverpod
class FriendController extends _$FriendController {
  @override
  Future<List<UserProfile>> build(String uid) async {
    // TODO(F/T2/KhoaLND): implement watchFriends stream
    throw UnimplementedError('FriendController.build — TODO: F/T2/KhoaLND');
  }

  Future<void> searchUsers(String query) async {
    // TODO(F/T3/KhoaLND): implement user search
    throw UnimplementedError('searchUsers — TODO: F/T3/KhoaLND');
  }

  Future<void> sendRequest(String receiverUid) async {
    // TODO(F/T4/KhoaLND): implement sendFriendRequest
    throw UnimplementedError('sendRequest — TODO: F/T4/KhoaLND');
  }

  Future<void> cancelRequest(String requestId) async {
    // TODO(F/T5/KhoaLND): implement cancelFriendRequest
    throw UnimplementedError('cancelRequest — TODO: F/T5/KhoaLND');
  }

  Future<void> declineRequest(String requestId) async {
    // TODO(F/T6/KhoaLND): implement declineFriendRequest
    throw UnimplementedError('declineRequest — TODO: F/T6/KhoaLND');
  }

  Future<void> unfriend(String friendUid) async {
    // TODO(F/T7/KhoaLND): implement unfriend
    throw UnimplementedError('unfriend — TODO: F/T7/KhoaLND');
  }

  Future<List<FriendRequest>> watchPendingRequests() async {
    // TODO(F/T8/KhoaLND): implement watchPendingRequests
    throw UnimplementedError('watchPendingRequests — TODO: F/T8/KhoaLND');
  }
}
