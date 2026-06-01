import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/space/data/space.dart';
import 'package:meep/features/space/data/space_repository.dart';

part 'space_controller.freezed.dart';
part 'space_controller.g.dart';

@freezed
class SpaceState with _$SpaceState {
  const factory SpaceState({
    @Default([]) List<Space> spaces,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _SpaceState;
}

@Riverpod(keepAlive: true)
SpaceRepository spaceRepository(Ref ref) => throw UnimplementedError(
      'spaceRepositoryProvider must be overridden — '
      'wire FirebaseSpaceRepository in main.dart',
    );

/// Current Space context cho Camera. `null` = "All friends" (mặc định).
///
/// Set: `ref.read(currentSpaceProvider.notifier).select(space)` khi user
/// chọn Space từ [SpaceContextBottomSheet] (T4). Reset về null khi chọn
/// "All friends" (`.clear()`) hoặc khi user signout.
///
/// `keepAlive: true` để Space context persist khi user qua lại Camera/Feed
/// — không reset chỉ vì page rebuild. Disposed cùng app lifetime.
///
/// Watch bởi `CameraSection` (KhoaLND) để đổi viền + nút chụp theo
/// `space.colorHex` + hiển thị badge "Đang gửi: [SpaceName]".
@Riverpod(keepAlive: true)
class CurrentSpace extends _$CurrentSpace {
  @override
  Space? build() => null;

  void select(Space? space) => state = space;

  void clear() => state = null;
}

/// Family controller — instance per uid. Sheet/screen lấy uid từ
/// [currentUidProvider] trước khi watch để đảm bảo signed-in.
@riverpod
class SpaceController extends _$SpaceController {
  StreamSubscription<List<Space>>? _spacesSub;

  // Self-healing retry timer. Firestore snapshot streams terminate
  // permanently on error (e.g. permission-denied during rules-deploy window).
  // Without re-subscribing, the list stays broken for the whole app session
  // và server-side fixes không surface đến khi full restart. Timer re-listen
  // sau backoff để UI tự khôi phục.
  Timer? _spacesRetry;
  bool _disposed = false;

  // Per-stream error flag. Chỉ clear errorMessage on recovery (error→success),
  // không clear trên emission bình thường — tránh emission đầu tiên wipe error
  // set bởi mutation (createSpace, leaveSpace, ...).
  bool _spacesHadError = false;

  static const _retryDelay = Duration(seconds: 3);

  @override
  SpaceState build(String uid) {
    ref.onDispose(() {
      _disposed = true;
      _spacesSub?.cancel();
      _spacesRetry?.cancel();
    });
    _listenSpaces(uid);
    return const SpaceState();
  }

  void _listenSpaces(String uid) {
    if (_disposed) return;
    _spacesSub?.cancel();
    _spacesSub = ref.read(spaceRepositoryProvider).watchMySpaces(uid).listen(
      (spaces) {
        final clearError = _spacesHadError;
        _spacesHadError = false;
        state = clearError
            ? state.copyWith(spaces: spaces, errorMessage: null)
            : state.copyWith(spaces: spaces);
      },
      onError: (Object _) {
        _spacesHadError = true;
        state = state.copyWith(
          errorMessage: 'Không thể tải danh sách Space. Thử lại sau.',
        );
        _spacesRetry?.cancel();
        _spacesRetry = Timer(_retryDelay, () => _listenSpaces(uid));
      },
    );
  }

  Space? _findSpace(String spaceId) {
    for (final s in state.spaces) {
      if (s.spaceId == spaceId) return s;
    }
    return null;
  }

  /// Validate + delegate `createSpace` CF. Server enforces server-side
  /// invariants (member-count, creator-only, etc.) — client guards là
  /// fail-fast UX, không phải security boundary.
  Future<void> createSpace({
    required String name,
    required String iconEmoji,
    required String colorHex,
    required List<String> friendUids,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(errorMessage: 'Tên Space không được trống');
      return;
    }
    if (trimmed.length > 30) {
      state = state.copyWith(errorMessage: 'Tên Space tối đa 30 ký tự');
      return;
    }
    if (friendUids.length > 9) {
      state = state.copyWith(
        errorMessage: 'Space tối đa 10 người (bao gồm bạn)',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(spaceRepositoryProvider).createSpace(
            name: trimmed,
            iconEmoji: iconEmoji,
            colorHex: colorHex,
            friendUids: friendUids,
          );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      final err = AppError.fromUnknown(e, fallback: 'Không thể tạo Space');
      state = state.copyWith(isLoading: false, errorMessage: err.message);
    }
  }

  Future<void> leaveSpace(String spaceId) async {
    final currentUid = ref.read(currentUidProvider).valueOrNull;
    if (currentUid == null) {
      state = state.copyWith(errorMessage: 'Chưa đăng nhập');
      return;
    }

    final space = _findSpace(spaceId);
    if (space != null && space.creatorId == currentUid) {
      state = state.copyWith(
        errorMessage: 'Chọn người quản trị mới trước khi rời Space',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(spaceRepositoryProvider).leaveSpace(spaceId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      final err = AppError.fromUnknown(e, fallback: 'Không thể rời Space');
      state = state.copyWith(isLoading: false, errorMessage: err.message);
    }
  }

  Future<void> deleteSpace(String spaceId) async {
    final currentUid = ref.read(currentUidProvider).valueOrNull;
    if (currentUid == null) {
      state = state.copyWith(errorMessage: 'Chưa đăng nhập');
      return;
    }

    final space = _findSpace(spaceId);
    if (space != null && space.creatorId != currentUid) {
      state = state.copyWith(
        errorMessage: 'Chỉ creator mới có quyền xoá Space',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(spaceRepositoryProvider).deleteSpace(spaceId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      final err = AppError.fromUnknown(e, fallback: 'Không thể xoá Space');
      state = state.copyWith(isLoading: false, errorMessage: err.message);
    }
  }

  Future<void> kickMember(String spaceId, String targetUid) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(spaceRepositoryProvider).kickMember(
            spaceId: spaceId,
            targetUid: targetUid,
          );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      final err = AppError.fromUnknown(e, fallback: 'Không thể xoá thành viên');
      state = state.copyWith(isLoading: false, errorMessage: err.message);
    }
  }

  Future<void> transferOwnership(String spaceId, String newCreatorUid) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(spaceRepositoryProvider).transferOwnership(
            spaceId: spaceId,
            newCreatorUid: newCreatorUid,
          );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      final err = AppError.fromUnknown(
        e,
        fallback: 'Không thể chuyển quyền quản trị',
      );
      state = state.copyWith(isLoading: false, errorMessage: err.message);
    }
  }
}
