import 'package:meep/features/auth/data/user_profile.dart';

abstract class UserRepository {
  Future<void> createProfile(UserProfile profile);
  Future<UserProfile?> getProfile(String uid);
  Future<bool> isUsernameAvailable(String username);

  /// Real-time stream of a user's profile. Emits null when doc doesn't exist.
  Stream<UserProfile?> watchProfile(String uid);
}
