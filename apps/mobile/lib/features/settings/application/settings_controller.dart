import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/core/config/app_config.dart';
import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/notification/application/notification_controller.dart';
import 'package:meep/features/settings/application/settings_state.dart';
import 'package:meep/features/settings/data/block_repository.dart';

part 'settings_controller.g.dart';

@Riverpod(keepAlive: true)
BlockRepository blockRepository(Ref ref) => throw UnimplementedError(
      'blockRepositoryProvider must be overridden — '
      'wire FirebaseBlockRepository in main.dart',
    );

@riverpod
class SettingsController extends _$SettingsController {
  @override
  SettingsState build() => const SettingsState();

  /// Copy Meep profile deep-link vào clipboard.
  /// URL format: `${AppConfig.shareBaseUrl}/{username}` (vd meep://profile/ngantran).
  Future<void> copyProfileLink(String username) async {
    final link = '${AppConfig.shareBaseUrl}/$username';
    await Clipboard.setData(ClipboardData(text: link));
  }

  Future<void> blockUser(String targetUid) async {
    final blockerUid = ref.read(authRepositoryProvider).currentUid;
    if (blockerUid == null) {
      state = state.copyWith(
        errorMessage: 'Bạn cần đăng nhập để thực hiện thao tác này',
      );
      return;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(blockRepositoryProvider).blockUser(
            blockerUid: blockerUid,
            targetUid: targetUid,
          );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = _afterFailure(e);
    }
  }

  Future<void> unblockUser(String targetUid) async {
    final blockerUid = ref.read(authRepositoryProvider).currentUid;
    if (blockerUid == null) {
      state = state.copyWith(
        errorMessage: 'Bạn cần đăng nhập để thực hiện thao tác này',
      );
      return;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(blockRepositoryProvider).unblockUser(
            blockerUid: blockerUid,
            targetUid: targetUid,
          );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = _afterFailure(e);
    }
  }

  /// Logout flow:
  /// 1. Best-effort `deleteFcmToken(uid)` — Notification module có thể chưa
  ///    wire (#103 OPEN) hoặc offline → swallow lỗi, vẫn tiếp tục signOut.
  /// 2. `AuthRepository.signOut()` — error sẽ surface lên state.errorMessage.
  /// Router auth listener tự redirect về /intro khi uid → null.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final auth = ref.read(authRepositoryProvider);
    final uid = auth.currentUid;
    if (uid != null) {
      try {
        await ref.read(notificationRepositoryProvider).deleteFcmToken(uid);
      } catch (_) {
        // Swallow: FCM cleanup là best-effort, không block logout.
      }
    }
    try {
      await auth.signOut();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = _afterFailure(e);
    }
  }

  Future<void> deleteAccount() async {
    // TODO(T6/NganTNK): implement deleteAccount (re-auth + cascade) — scope #119
    throw UnimplementedError('deleteAccount — TODO T6 #119');
  }

  /// Reset isLoading + map error to message (null for [OperationCancelledError]).
  /// Pattern theo `login_controller._afterFailure`.
  SettingsState _afterFailure(Object e) {
    final err = AppError.fromUnknown(e);
    return state.copyWith(
      isLoading: false,
      errorMessage: err is OperationCancelledError ? null : err.message,
    );
  }
}
