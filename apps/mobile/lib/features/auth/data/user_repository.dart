import 'package:meep/features/auth/data/user_profile.dart';

abstract class UserRepository {
  Future<void> createProfile(UserProfile profile);
  Future<UserProfile?> getProfile(String uid);
  Future<bool> isUsernameAvailable(String username);
}
