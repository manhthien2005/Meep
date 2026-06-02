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

  /// Sign in with Google.
  ///
  /// Throws [OperationCancelledError] when the user dismisses the picker —
  /// controllers should treat this as a silent no-op. Other failures map to
  /// [UnauthenticatedError] / [NetworkError] / [UnexpectedError].
  Future<void> signInWithGoogle();

  /// Send a password reset email.
  Future<void> sendPasswordResetEmail({required String email});

  /// Lấy email từ oobCode trước khi reset — dùng để auto-sign-in sau reset.
  Future<String> verifyPasswordResetCode({required String oobCode});

  /// Xác nhận reset mật khẩu với oobCode từ deep link email.
  Future<void> confirmPasswordReset({
    required String oobCode,
    required String newPassword,
  });

  /// Trả về true nếu email chưa được đăng ký với bất kỳ provider nào.
  ///
  /// Yêu cầu "Email Enumeration Protection" TẮT trong Firebase Console
  /// (Authentication > Settings > User Actions).
  /// Nếu protection bật, method này luôn trả về true (không dùng được).
  Future<bool> isEmailAvailable(String email);

  /// Sign out the current user.
  Future<void> signOut();

  /// Đồng bộ cached session với server: nếu Firebase Auth user đã bị delete
  /// hoặc disable server-side (vd qua Firebase Console), token cached trên
  /// device vẫn valid cho tới khi tự refresh (~1h) → app cho user vào /home
  /// sai. Method này gọi `user.reload()` để trigger validate ngay; nếu fail
  /// với mã session-invalid → tự gọi [signOut] để clear cached state.
  ///
  /// Network/transient errors → swallow, giữ session (app vẫn dùng offline).
  /// Gọi 1 lần khi app khởi động trước `runApp`.
  Future<void> revalidateSession();

  /// Delete the current user's Firebase Auth account.
  /// Used for rollback when Firestore batch write fails after createUser.
  Future<void> deleteCurrentUser();

  /// Re-authenticate before sensitive operations (email change, delete account).
  ///
  /// Implementations must wrap Firebase errors:
  /// - `wrong-password` / `invalid-credential` → [UnauthenticatedError] ("Mật khẩu không đúng")
  /// - `user-mismatch` → [UnauthenticatedError] ("Thông tin xác thực không khớp tài khoản")
  /// - `requires-recent-login` → [UnauthenticatedError] với `code: 'requires-recent-login'`
  /// - `network-request-failed` → [NetworkError]
  Future<void> reauthenticateWithCredential(AuthCredential credential);

  /// Helper: reauthenticate current email/password user.
  ///
  /// Widgets/controllers KHÔNG được tự build [EmailAuthProvider.credential]
  /// (layering rule — không touch Firebase types). Method này wrap construction
  /// + reauth.
  ///
  /// Throws [UnauthenticatedError] nếu user chưa login hoặc không có email.
  Future<void> reauthenticateWithPassword(String password);

  /// Helper: reauthenticate current Google user.
  ///
  /// Trigger Google account picker → lấy credential → reauth. Throws
  /// [OperationCancelledError] nếu user dismiss picker (silent no-op upstream,
  /// match `signInWithGoogle`).
  Future<void> reauthenticateWithGoogle();

  /// Returns the primary provider ID của user hiện tại — 'password',
  /// 'google.com', etc. Returns null nếu chưa login hoặc providerData rỗng.
  ///
  /// MVP Meep chỉ hỗ trợ 1 provider per account (không link). Tương lai có
  /// thể return list providers.
  String? get currentProviderId;

  /// Update the email address of the current user.
  Future<void> updateEmail(String newEmail);

  /// Cascade-delete user account qua Cloud Function `deleteAccount`.
  ///
  /// Server (Admin SDK) xóa Storage prefixes + Firestore subcollections +
  /// documents + Firebase Auth account theo thứ tự đảm bảo retry-safe (xem
  /// `firebase/functions/src/settings/deleteAccount.ts`).
  ///
  /// Khi server xóa Auth thành công, client local session tự invalidate qua
  /// [watchUid] → router auth listener redirect về `/intro`.
  ///
  /// Pre-condition: caller (DeleteAccountDialog) phải gọi
  /// [reauthenticateWithCredential] trước để xác nhận identity. CF dùng Admin
  /// SDK bypass token freshness, nhưng UX yêu cầu reauth.
  Future<void> deleteAccountCascade();
}
