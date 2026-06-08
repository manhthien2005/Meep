import 'package:meep/features/auth/data/public_profile.dart';
import 'package:meep/features/auth/data/user_profile.dart';

abstract class UserRepository {
  Future<void> createProfile(UserProfile profile);
  Future<UserProfile?> getProfile(String uid);
  Future<PublicProfile?> getPublicProfile(String uid);
  Future<bool> isUsernameAvailable(String username);

  /// Real-time stream of a user's profile. Emits null when doc doesn't exist.
  Stream<UserProfile?> watchProfile(String uid);

  /// Real-time stream of public profile fields safe for stranger lookup.
  Stream<PublicProfile?> watchPublicProfile(String uid);
}
