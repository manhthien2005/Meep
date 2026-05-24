import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/features/auth/data/auth_repository.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/auth/data/user_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError(
    'authRepositoryProvider must be overridden — '
    'wire FirebaseAuthRepository in main.dart after Firebase.initializeApp',
  );
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  throw UnimplementedError(
    'userRepositoryProvider must be overridden — '
    'wire FirebaseUserRepository in main.dart after Firebase.initializeApp',
  );
});

/// Stream of the current user's uid (or null when signed out).
final currentUidProvider = StreamProvider<String?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.watchUid();
});

/// Stream of the current user's full profile (null when signed out or profile not yet created).
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(currentUidProvider).valueOrNull;
  if (uid == null) return Stream.value(null);
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchProfile(uid);
});

/// Convenience — true when there's a signed-in user.
final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUidProvider).maybeWhen(
        data: (uid) => uid != null,
        orElse: () => false,
      );
});
