import 'package:firebase_auth/firebase_auth.dart';
import 'package:meep/core/error/app_error.dart';

/// Repository for authentication operations.
///
/// Implementations convert Firebase exceptions into [AppError] at the boundary.
/// UI / controllers should not depend on raw Firebase types directly.
abstract class AuthRepository {
  /// Returns the currently signed-in user's uid, or null.
  String? get currentUid;

  /// Returns the currently signed-in user's email, or null.
  String? get currentEmail;

  /// Returns the currently signed-in user's display name, or null.
  String? get currentDisplayName;

  /// Stream of auth state — emits new uid (or null) on every change.
  Stream<String?> watchUid();

  /// Create a new account with email + password.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Sign in with email + password. Throws [UnauthenticatedError] on bad creds.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign in with Google. Throws [UnauthenticatedError] on cancel.
  Future<void> signInWithGoogle();

  /// Sign in with Apple. Throws [UnauthenticatedError] on cancel.
  Future<void> signInWithApple();

  /// Send a password reset email.
  Future<void> sendPasswordResetEmail({required String email});

  /// Lấy email từ oobCode trước khi reset — dùng để auto-sign-in sau reset.
  Future<String> verifyPasswordResetCode({required String oobCode});

  /// Xác nhận reset mật khẩu với oobCode từ deep link email.
  Future<void> confirmPasswordReset({
    required String oobCode,
    required String newPassword,
  });

  /// Sign out the current user.
  Future<void> signOut();

  /// Delete the current user's Firebase Auth account.
  /// Used for rollback when Firestore batch write fails after createUser.
  Future<void> deleteCurrentUser();

  /// Re-authenticate before sensitive operations (email change, delete account).
  Future<void> reauthenticateWithCredential(AuthCredential credential);

  /// Update the email address of the current user.
  Future<void> updateEmail(String newEmail);

  // TODO(A/T3/KhoaLND): implement FirebaseAuthRepository — see docs/plans/2026-05-04-auth.md
}
