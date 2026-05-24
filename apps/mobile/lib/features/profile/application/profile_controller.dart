import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/profile/data/profile_repository.dart';

part 'profile_controller.freezed.dart';
part 'profile_controller.g.dart';

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
ProfileRepository profileRepository(ProfileRepositoryRef ref) =>
    throw UnimplementedError(
      'profileRepositoryProvider must be overridden — '
      'wire FirestoreProfileRepository in main.dart (TODO: P/T1/TBD)',
    );

@riverpod
class ProfileController extends _$ProfileController {
  @override
  ProfileState build(String uid) => const ProfileState();

  Future<void> loadProfile() async {
    // TODO(P/T2/TBD): implement loadProfile
    throw UnimplementedError('loadProfile — TODO: P/T2/TBD');
  }

  Future<void> updateProfile(Map<String, dynamic> fields) async {
    // TODO(P/T3/TBD): implement updateProfile
    throw UnimplementedError('updateProfile — TODO: P/T3/TBD');
  }

  Future<void> updateAvatar() async {
    // TODO(P/T4/TBD): pick image + updateAvatar via ProfileRepository
    throw UnimplementedError('updateAvatar — TODO: P/T4/TBD');
  }

  Future<void> removeAvatar() async {
    // TODO(P/T5/TBD): implement removeAvatar
    throw UnimplementedError('removeAvatar — TODO: P/T5/TBD');
  }
}
