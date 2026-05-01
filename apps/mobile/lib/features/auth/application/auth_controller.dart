import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/features/auth/data/auth_repository.dart';

/// Provider for [AuthRepository].
///
/// Override in tests with a fake implementation:
/// ```dart
/// ProviderScope(
///   overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository())],
///   child: ...,
/// )
/// ```
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError(
    'authRepositoryProvider must be overridden — '
    'wire FirebaseAuthRepository in main.dart after Firebase.initializeApp',
  );
});

/// Stream of the current user's uid (or null when signed out).
final currentUidProvider = StreamProvider<String?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.watchUid();
});

/// Convenience — true when there's a signed-in user.
final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUidProvider).maybeWhen(
        data: (uid) => uid != null,
        orElse: () => false,
      );
});

// TODO(impl): once auth flows are wired, add controllers per flow:
//   - SignInController (handles loading / error / success states)
//   - SignUpController
//   - PasswordResetController
//
// Each as a Riverpod `@riverpod class` once you enable code-gen.
