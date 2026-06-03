import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/core/config/app_config.dart';
import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/profile/data/profile_repository.dart';

part 'profile_controller.freezed.dart';
part 'profile_controller.g.dart';

/// Spec acceptance — bio tối đa 150 chars (xem docs/specs/2026-05-22-profile.md).
const int _kBioMaxLength = 150;

@freezed
class ProfileState with _$ProfileState {
  const factory ProfileState({
    UserProfile? profile,
    @Default(false) bool isLoading,
    @Default(false) bool isSaving,
    String? errorMessage,
  }) = _ProfileState;
}

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) => throw UnimplementedError(
      'profileRepositoryProvider must be overridden — '
      'wire FirebaseProfileRepository.firebase(...) in main.dart',
    );

@riverpod
class ProfileController extends _$ProfileController {
  StreamSubscription<UserProfile?>? _sub;

  @override
  ProfileState build(String uid) {
    ref.onDispose(() => _sub?.cancel());
    _watchProfile(uid);
    return const ProfileState(isLoading: true);
  }

  /// Subscribe `watchUserProfile(uid)` từ ProfileRepository — Firestore stream
  /// đẩy update mới về [state.profile] tự động. Lỗi stream → errorMessage.
  void _watchProfile(String uid) {
    _sub?.cancel();
    _sub = ref.read(profileRepositoryProvider).watchUserProfile(uid).listen(
      (profile) {
        state = state.copyWith(
          profile: profile,
          isLoading: false,
          errorMessage: null,
        );
      },
      onError: (Object e) {
        state = _afterFailure(e, fallback: 'Không tải được hồ sơ');
      },
    );
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  /// Validate bio length ≤ [_kBioMaxLength] trước repository call (issue #110
  /// acceptance). Other fields delegate trực tiếp sang [updateProfile].
  Future<void> updateField(String field, Object? value) async {
    if (field == 'bio' && value is String && value.length > _kBioMaxLength) {
      state = state.copyWith(
        errorMessage: 'Tiểu sử tối đa $_kBioMaxLength ký tự',
      );
      return;
    }
    await updateProfile({field: value});
  }

  Future<void> updateProfile(Map<String, dynamic> fields) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(uid, fields);
      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = _afterFailure(e);
    }
  }

  /// Avatar upload fail → rollback `state.profile.avatarUrl` về giá trị cũ
  /// (issue #110 acceptance). Success path: Firestore stream qua [_watchProfile]
  /// sẽ tự sync URL mới.
  Future<void> updateAvatar(File imageFile) async {
    final originalUrl = state.profile?.avatarUrl;
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await ref.read(profileRepositoryProvider).updateAvatar(uid, imageFile);
      state = state.copyWith(isSaving: false);
    } catch (e) {
      // Rollback avatarUrl: nếu UI/state đã optimistic-update sang URL mới,
      // restore lại URL cũ trước khi report error.
      final current = state.profile;
      final rollback = current != null && current.avatarUrl != originalUrl
          ? current.copyWith(avatarUrl: originalUrl)
          : current;
      state = _afterFailure(e, fallback: 'Tải ảnh thất bại').copyWith(
        profile: rollback,
      );
    }
  }

  Future<void> removeAvatar() async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await ref.read(profileRepositoryProvider).removeAvatar(uid);
      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = _afterFailure(e);
    }
  }

  /// Delegate sang `UserRepository.isUsernameAvailable` (auth module) —
  /// KHÔNG call Firestore trực tiếp trong controller per spec §H4.
  Future<bool> isUsernameAvailable(String username) async {
    try {
      return await ref
          .read(userRepositoryProvider)
          .isUsernameAvailable(username);
    } catch (e) {
      state = _afterFailure(e);
      return false;
    }
  }

  /// Share URL = `AppConfig.shareBaseUrl/{username}` — không hardcode (spec Q3
  /// chốt deep link `meep://profile/{username}`).
  String shareProfileUrl(String username) {
    return '${AppConfig.shareBaseUrl}/$username';
  }

  ProfileState _afterFailure(
    Object e, {
    String fallback = 'Đã có lỗi xảy ra',
  }) {
    final err = AppError.fromUnknown(e, fallback: fallback);
    return state.copyWith(
      isLoading: false,
      isSaving: false,
      errorMessage: err is OperationCancelledError ? null : err.message,
    );
  }
}
