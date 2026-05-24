import 'dart:io';

import 'package:meep/features/auth/data/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile?> getUserProfile(String uid);
  Stream<UserProfile?> watchUserProfile(String uid);

  /// Update arbitrary profile fields (e.g. bio, displayName, dateOfBirth).
  Future<void> updateProfile(String uid, Map<String, dynamic> fields);

  /// Upload [imageFile] to Storage and update avatarUrl.
  Future<void> updateAvatar(String uid, File imageFile);

  /// Remove avatar from Storage and clear avatarUrl.
  Future<void> removeAvatar(String uid);

  // NOTE: isUsernameAvailable is NOT here — ProfileController injects
  // UserRepository from auth and delegates to it. See plan §H4.
}
