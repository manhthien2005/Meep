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
  StreamSubscription<List<FriendRequest>>? _sentSub;

  // Self-healing retry timers. Firestore snapshot streams terminate
  // permanently on error (e.g. permission-denied during a rules-deploy window).
  // Without re-subscribing, the list stays broken for the whole app session and
  // server-side fixes never surface until a full restart. These timers re-listen
  // after a short backoff so the UI recovers on its own.
  Timer? _friendsRetry;
  Timer? _requestsRetry;
  Timer? _sentRetry;
  bool _disposed = false;

  // Per-stream error flags. Only clear errorMessage on recovery (error→success),
  // never on a normal emission — otherwise a stream's first value would wipe an
  // error set by a mutation (acceptFriendRequest, etc.).
  bool _friendsHadError = false;
  bool _requestsHadError = false;
  bool _sentHadError = false;

  static const _retryDelay = Duration(seconds: 3);

  @override
  FriendState build(String uid) {
    ref.onDispose(() {
      _disposed = true;
      _searchDebounce?.cancel();
      _friendsSub?.cancel();
      _requestsSub?.cancel();
      _sentSub?.cancel();
      _friendsRetry?.cancel();
      _requestsRetry?.cancel();
      _sentRetry?.cancel();
    });

    _listenFriends(uid);
    _listenPending(uid);
    _listenSent(uid);

    return const FriendState();
  }

  /// Watch friends stream with self-healing re-subscribe on error.
  void _listenFriends(String uid) {
    if (_disposed) return;
    _friendsSub?.cancel();
    _friendsSub = ref.read(friendRepositoryProvider).watchFriends(uid).listen(
      (friends) {
        // Only clear error on recovery (error→success), never on a normal
        // emission — otherwise the first value would wipe a mutation error.
        final clearError = _friendsHadError;
        _friendsHadError = false;
        // Đặt friendsInitialized=true sau lần emit đầu tiên để UI biết
        // friends stream đã sẵn sàng — tránh race với search result.
        state = clearError
            ? state.copyWith(
                friends: friends,
                friendsInitialized: true,
                errorMessage: null,
              )
            : state.copyWith(friends: friends, friendsInitialized: true);
      },
      onError: (Object error) {
        _friendsHadError = true;
        // Vẫn đặt initialized để UI không chờ mãi khi lỗi
        state = state.copyWith(
          friendsInitialized: true,
          errorMessage: 'Không thể tải danh sách bạn bè. Thử lại sau.',
        );
        _friendsRetry?.cancel();
        _friendsRetry = Timer(_retryDelay, () => _listenFriends(uid));
      },
    );
  }

  /// Watch incoming pending requests with self-healing re-subscribe on error.
  void _listenPending(String uid) {
    if (_disposed) return;
    _requestsSub?.cancel();
    _requestsSub = ref
        .read(friendRequestRepositoryProvider)
        .watchPendingRequests(uid)
        .listen(
      (requests) {
        final clearError = _requestsHadError;
        _requestsHadError = false;
        state = clearError
            ? state.copyWith(pendingRequests: requests, errorMessage: null)
            : state.copyWith(pendingRequests: requests);
      },
      onError: (Object error) {
        _requestsHadError = true;
        state = state.copyWith(
          errorMessage: 'Không thể tải yêu cầu kết bạn. Thử lại sau.',
        );
        _requestsRetry?.cancel();
        _requestsRetry = Timer(_retryDelay, () => _listenPending(uid));
      },
    );
  }

  /// Watch outgoing (sent) pending requests — drives "Đã gửi" state so it
  /// survives re-search and sheet reopen. Self-healing re-subscribe on error.
  void _listenSent(String uid) {
    if (_disposed) return;
    _sentSub?.cancel();
    _sentSub =
        ref.read(friendRequestRepositoryProvider).watchSentRequests(uid).listen(
      (requests) {
        final clearError = _sentHadError;
        _sentHadError = false;
        state = clearError
            ? state.copyWith(sentRequests: requests, errorMessage: null)
            : state.copyWith(sentRequests: requests);
      },
      onError: (Object error) {
        _sentHadError = true;
        state = state.copyWith(
          errorMessage: 'Không thể tải lời mời đã gửi. Thử lại sau.',
        );
        _sentRetry?.cancel();
        _sentRetry = Timer(_retryDelay, () => _listenSent(uid));
      },
    );
  }

  /// Reset hoàn toàn search state — gọi khi user đóng search mode.
  /// Đảm bảo mở lại sheet không còn kết quả cũ.
  void clearSearch() {
    _searchDebounce?.cancel();
    state = state.copyWith(
      searchQuery: '',
      searchResult: null,
      isLoading: false,
      errorMessage: null,
    );
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
    final currentUid = ref.read(currentUidProvider).valueOrNull;
    if (currentUid == null) {
      state = state.copyWith(errorMessage: 'Chưa đăng nhập');
      return;
    }

    // Optimistic update: thêm ngay vào sentRequests để button đổi thành
    // "Đã gửi" tức thì, không cần đợi Firestore round-trip.
    final now = DateTime.now();
    final optimisticRequest = FriendRequest(
      requestId: '__optimistic_$receiverUid',
      senderId: currentUid,
      receiverId: receiverUid,
      status: FriendRequestStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    state = state.copyWith(
      sentRequests: [...state.sentRequests, optimisticRequest],
      errorMessage: null,
    );

    try {
      await ref.read(friendRequestRepositoryProvider).sendFriendRequest(
            senderUid: currentUid,
            receiverUid: receiverUid,
          );
      // Stream sẽ tự cập nhật sentRequests với doc thật từ Firestore
      // (bao gồm requestId thật thay cho '__optimistic_*').
    } catch (error) {
      // Rollback: xóa optimistic item
      state = state.copyWith(
        sentRequests: state.sentRequests
            .where((r) => r.requestId != '__optimistic_$receiverUid')
            .toList(),
        errorMessage: 'Không thể gửi lời mời: $error',
      );
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    // Optimistic update: xóa khỏi pendingRequests ngay để row biến mất
    // tức thì. Stream sẽ xác nhận khi CF acceptFriendRequest hoàn thành.
    final originalPending = state.pendingRequests;
    state = state.copyWith(
      pendingRequests:
          originalPending.where((r) => r.requestId != requestId).toList(),
      errorMessage: null,
    );

    try {
      await ref
          .read(friendRequestRepositoryProvider)
          .acceptFriendRequest(requestId);
    } catch (error) {
      final errorMsg = error.toString();
      final msg =
          (errorMsg.contains('20') || errorMsg.contains('FAILED_PRECONDITION'))
              ? 'Bạn đã có 20 bạn bè, không thể chấp nhận thêm'
              : 'Không thể chấp nhận lời mời. Thử lại sau.';
      // Rollback
      state = state.copyWith(
        pendingRequests: originalPending,
        errorMessage: msg,
      );
    }
  }

  Future<void> cancelFriendRequest(String requestId) async {
    // Optimistic: xóa khỏi pendingRequests nếu là incoming (nếu caller dùng
    // hàm này để hủy incoming — thường là declineFriendRequest, nhưng giữ
    // hàm này cho backward compat với repo interface).
    final originalPending = state.pendingRequests;
    state = state.copyWith(
      pendingRequests:
          originalPending.where((r) => r.requestId != requestId).toList(),
      errorMessage: null,
    );

    try {
      await ref
          .read(friendRequestRepositoryProvider)
          .cancelFriendRequest(requestId);
    } catch (error) {
      state = state.copyWith(
        pendingRequests: originalPending,
        errorMessage: 'Không thể hủy lời mời. Thử lại sau.',
      );
    }
  }

  /// Cancel ALL pending requests sent to [receiverUid]. Cleans up legacy
  /// duplicates (created before the send-side idempotent guard) so the UI
  /// state flips back correctly after a single tap.
  Future<void> cancelSentRequestsTo(String receiverUid) async {
    final targets =
        state.sentRequests.where((r) => r.receiverId == receiverUid).toList();
    if (targets.isEmpty) return;

    // Optimistic update: xóa ngay khỏi sentRequests để button flip về
    // "Thêm" tức thì, không đợi Firestore.
    final optimisticSent =
        state.sentRequests.where((r) => r.receiverId != receiverUid).toList();
    state = state.copyWith(sentRequests: optimisticSent, errorMessage: null);

    // Chỉ cancel doc thật trên Firestore. Optimistic placeholder
    // (__optimistic_*) chưa tồn tại trên server → update sẽ NOT_FOUND. Nếu
    // request thật đang bay (send chưa xong), stream sẽ re-add và user tap lại.
    final realIds = targets
        .map((r) => r.requestId)
        .where((id) => !id.startsWith('__optimistic_'))
        .toList();
    if (realIds.isEmpty) return;

    try {
      final repo = ref.read(friendRequestRepositoryProvider);
      await Future.wait(realIds.map(repo.cancelFriendRequest));
      // Stream sẽ tự xác nhận, không cần update thêm.
    } catch (error) {
      // Rollback: khôi phục lại targets
      state = state.copyWith(
        sentRequests: [...state.sentRequests, ...targets],
        errorMessage: 'Không thể hủy lời mời: $error',
      );
    }
  }

  Future<void> declineFriendRequest(String requestId) async {
    // Optimistic: xóa khỏi pendingRequests ngay để row biến mất tức thì.
    final originalPending = state.pendingRequests;
    state = state.copyWith(
      pendingRequests:
          originalPending.where((r) => r.requestId != requestId).toList(),
      errorMessage: null,
    );

    try {
      await ref
          .read(friendRequestRepositoryProvider)
          .declineFriendRequest(requestId);
    } catch (error) {
      state = state.copyWith(
        pendingRequests: originalPending,
        errorMessage: 'Không thể từ chối lời mời. Thử lại sau.',
      );
    }
  }

  Future<void> unfriend(String friendUid) async {
    final currentUid = ref.read(currentUidProvider).valueOrNull;
    if (currentUid == null) {
      state = state.copyWith(errorMessage: 'Chưa đăng nhập');
      return;
    }

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
