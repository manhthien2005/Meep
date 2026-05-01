import 'package:meep/core/error/app_error.dart';

/// Repository for authentication operations.
///
/// Implementations convert Firebase exceptions into [AppError] at the boundary.
/// UI / controllers should not depend on `firebase_auth` types directly.
abstract class AuthRepository {
  /// Returns the currently signed-in user's uid, or null.
  String? get currentUid;

  /// Stream of auth state — emits new uid (or null) on every change.
  Stream<String?> watchUid();

  /// Sign in with email + password. Throws [UnauthenticatedError] on bad creds.
  Future<void> signInWithEmail({required String email, required String password});

  /// Sign in with Apple. Throws [UnauthenticatedError] on cancel.
  Future<void> signInWithApple();

  /// Sign in with Google. Throws [UnauthenticatedError] on cancel.
  Future<void> signInWithGoogle();

  /// Sign out the current user.
  Future<void> signOut();
}

// TODO(impl): create FirebaseAuthRepository implementing this interface.
//
// class FirebaseAuthRepository implements AuthRepository {
//   FirebaseAuthRepository({required FirebaseAuth auth}) : _auth = auth;
//   final FirebaseAuth _auth;
//
//   @override
//   String? get currentUid => _auth.currentUser?.uid;
//
//   @override
//   Stream<String?> watchUid() => _auth.authStateChanges().map((u) => u?.uid);
//
//   ... (catch FirebaseAuthException, throw AppError subclass)
// }
