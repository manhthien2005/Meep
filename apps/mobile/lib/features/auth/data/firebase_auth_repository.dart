import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:meep/core/config/app_config.dart';
import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/auth/data/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required FirebaseAuth auth,
    FirebaseFunctions? functions,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth,
        _functions = functions,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;

  /// Optional — chỉ [deleteAccountCascade] cần. Existing tests construct
  /// FirebaseAuthRepository chỉ với `auth:` nên giữ optional, throw rõ ràng
  /// nếu method dùng tới mà chưa wire.
  final FirebaseFunctions? _functions;
  final GoogleSignIn _googleSignIn;

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  String? get currentEmail => _auth.currentUser?.email;

  @override
  String? get currentDisplayName => _auth.currentUser?.displayName;

  @override
  Stream<String?> watchUid() =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapSignUpError(e);
    }
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapSignInError(e);
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // User dismissed the account picker — silent no-op upstream.
      throw const OperationCancelledError();
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    try {
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _mapSignInError(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      final settings = ActionCodeSettings(
        url: AppConfig.passwordResetActionUrl,
        handleCodeInApp: true,
        androidPackageName: AppConfig.androidPackageName,
        androidInstallApp: true,
        androidMinimumVersion: '21',
      );
      await _auth.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: settings,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapGenericError(e);
    }
  }

  @override
  Future<String> verifyPasswordResetCode({required String oobCode}) async {
    try {
      return await _auth.verifyPasswordResetCode(oobCode);
    } on FirebaseAuthException catch (e) {
      throw _mapGenericError(e);
    }
  }

  @override
  Future<void> confirmPasswordReset({
    required String oobCode,
    required String newPassword,
  }) async {
    try {
      await _auth.confirmPasswordReset(code: oobCode, newPassword: newPassword);
    } on FirebaseAuthException catch (e) {
      throw _mapGenericError(e);
    }
  }

  @override
  Future<bool> isEmailAvailable(String email) async {
    try {
      // `fetchSignInMethodsForEmail` đã bị Firebase deprecate vì lý do
      // anti-enumeration. Pre-check chỉ chính xác khi Firebase Console >
      // Authentication > Settings > **Email Enumeration Protection** đang TẮT.
      //
      // Khi protection BẬT: method này luôn trả `true` (Firebase trả về []),
      // duplicate email sẽ được phát hiện ở `createUserWithEmailAndPassword`
      // (step cuối flow signup) qua mã `email-already-in-use`.
      //
      // Auth spec hiện tại giả định protection TẮT để UX báo lỗi sớm.
      // ignore: deprecated_member_use
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isEmpty;
    } on FirebaseAuthException catch (e) {
      throw _mapGenericError(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _mapGenericError(e);
    }
    // Best-effort: clear Google session để account picker hiện lại lần sau.
    // Không fail signOut nếu Google plugin throw (test env, không có Play
    // Services, hoặc chưa từng signIn qua Google).
    try {
      await _googleSignIn.signOut();
    } catch (_) {/* swallow */}
  }

  @override
  Future<void> revalidateSession() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.reload().timeout(const Duration(seconds: 5));
    } on FirebaseAuthException catch (e) {
      if (_isSessionPermanentlyInvalid(e.code)) {
        await signOut();
      }
      // else: transient (network-request-failed, internal-error, ...) → giữ
      // session, ops sau sẽ retry hoặc fail explicit.
    } on TimeoutException {
      // Mạng chậm → giữ session, offline-friendly.
    } catch (_) {
      // Unknown — conservative, không signOut.
    }
  }

  @override
  Future<void> deleteCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _mapGenericError(e);
    }
  }

  @override
  Future<void> reauthenticateWithCredential(AuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const UnauthenticatedError(
        message: 'Bạn cần đăng nhập để thực hiện thao tác này',
      );
    }
    try {
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _mapReauthError(e);
    }
  }

  @override
  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const UnauthenticatedError(
        message: 'Bạn cần đăng nhập với email để xác thực lại',
      );
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await reauthenticateWithCredential(credential);
  }

  @override
  Future<void> reauthenticateWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // User dismissed picker — silent no-op upstream (match signInWithGoogle).
      throw const OperationCancelledError();
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await reauthenticateWithCredential(credential);
  }

  @override
  String? get currentProviderId {
    final user = _auth.currentUser;
    if (user == null || user.providerData.isEmpty) return null;
    return user.providerData[0].providerId;
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const UnauthenticatedError(
        message: 'Bạn cần đăng nhập để đổi email',
      );
    }
    try {
      // Firebase Auth 5.x deprecate updateEmail() — dùng verifyBeforeUpdateEmail
      // để chống account takeover. Email chỉ đổi sau khi user click link
      // verification trong inbox của địa chỉ mới.
      await user.verifyBeforeUpdateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      throw _mapUpdateEmailError(e);
    }
  }

  @override
  Future<void> deleteAccountCascade() async {
    final functions = _functions;
    if (functions == null) {
      // Misconfiguration: main.dart phải pass `functions:` vào constructor.
      throw const UnexpectedError(
        message:
            'FirebaseFunctions chưa wire — kiểm tra FirebaseAuthRepository init trong main.dart',
      );
    }
    if (_auth.currentUser == null) {
      throw const UnauthenticatedError(
        message: 'Bạn cần đăng nhập để xóa tài khoản',
      );
    }
    try {
      final callable = functions.httpsCallable('deleteAccount');
      await callable.call<void>();
    } on FirebaseFunctionsException catch (e) {
      throw _mapDeleteAccountError(e);
    }
  }

  // ── Error mapping ─────────────────────────────────────────────────────────

  AppError _mapSignUpError(FirebaseAuthException e) => switch (e.code) {
        'email-already-in-use' =>
          const ValidationError(message: 'Email này đã được sử dụng'),
        'weak-password' => const ValidationError(
            message: 'Mật khẩu quá ngắn (tối thiểu 8 ký tự)',
          ),
        'invalid-email' => const ValidationError(message: 'Email không hợp lệ'),
        'network-request-failed' =>
          const NetworkError(message: 'Không có kết nối mạng'),
        _ => UnexpectedError(message: e.message ?? e.code, cause: e),
      };

  AppError _mapSignInError(FirebaseAuthException e) => switch (e.code) {
        'wrong-password' ||
        'invalid-credential' =>
          const UnauthenticatedError(message: 'Mật khẩu không đúng'),
        'user-not-found' => const UnauthenticatedError(
            message: 'Không tìm thấy tài khoản với email này',
          ),
        'user-disabled' =>
          const UnauthenticatedError(message: 'Tài khoản đã bị vô hiệu hóa'),
        'too-many-requests' => const UnauthenticatedError(
            message: 'Quá nhiều lần thử. Vui lòng thử lại sau',
          ),
        'network-request-failed' =>
          const NetworkError(message: 'Không có kết nối mạng'),
        _ => UnexpectedError(message: e.message ?? e.code, cause: e),
      };

  AppError _mapGenericError(FirebaseAuthException e) => switch (e.code) {
        'network-request-failed' =>
          const NetworkError(message: 'Không có kết nối mạng'),
        _ => UnexpectedError(message: e.message ?? e.code, cause: e),
      };

  /// `verifyBeforeUpdateEmail` có thể fail vì email invalid, đã tồn tại,
  /// hoặc session quá cũ (`requires-recent-login`) — caller phải gọi
  /// `reauthenticateWithPassword` / `reauthenticateWithGoogle` trước.
  AppError _mapUpdateEmailError(FirebaseAuthException e) => switch (e.code) {
        'invalid-email' => const ValidationError(message: 'Email không hợp lệ'),
        'email-already-in-use' =>
          const ValidationError(message: 'Email này đã được sử dụng'),
        'requires-recent-login' => UnauthenticatedError(
            message: 'Phiên đăng nhập hết hạn. Vui lòng xác thực lại',
            code: e.code,
            cause: e,
          ),
        'too-many-requests' => const UnauthenticatedError(
            message: 'Quá nhiều lần thử. Vui lòng thử lại sau',
          ),
        'network-request-failed' =>
          const NetworkError(message: 'Không có kết nối mạng'),
        _ => UnexpectedError(message: e.message ?? e.code, cause: e),
      };

  /// Reauth có thể fail vì credential sai (wrong-password), provider mismatch
  /// (user-mismatch khi GoogleAuthProvider credential nhưng account email),
  /// hoặc session quá cũ (requires-recent-login — extremely rare ở reauth path
  /// nhưng giữ để safety).
  AppError _mapReauthError(FirebaseAuthException e) => switch (e.code) {
        'wrong-password' ||
        'invalid-credential' =>
          const UnauthenticatedError(message: 'Mật khẩu không đúng'),
        'user-mismatch' => const UnauthenticatedError(
            message: 'Thông tin xác thực không khớp tài khoản hiện tại',
          ),
        'user-not-found' => const UnauthenticatedError(
            message: 'Không tìm thấy tài khoản',
          ),
        'too-many-requests' => const UnauthenticatedError(
            message: 'Quá nhiều lần thử. Vui lòng thử lại sau',
          ),
        'requires-recent-login' => UnauthenticatedError(
            message: 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại',
            code: e.code,
            cause: e,
          ),
        'network-request-failed' =>
          const NetworkError(message: 'Không có kết nối mạng'),
        _ => UnexpectedError(message: e.message ?? e.code, cause: e),
      };

  /// CF `deleteAccount` có thể fail: unauthenticated (token expired giữa
  /// reauth và call), unavailable (CF cold start timeout), default
  /// (cascade partial fail — retry-safe theo CF impl, surface lỗi UI).
  AppError _mapDeleteAccountError(FirebaseFunctionsException e) =>
      switch (e.code) {
        'unauthenticated' => UnauthenticatedError(
            message: e.message ?? 'Cần đăng nhập để xóa tài khoản',
            code: e.code,
            cause: e,
          ),
        'unavailable' || 'deadline-exceeded' => NetworkError(
            message: e.message ?? 'Mất kết nối khi xóa tài khoản. Thử lại sau.',
            code: e.code,
            cause: e,
          ),
        _ => UnexpectedError(
            message: e.message ?? 'Không thể xóa tài khoản. Thử lại sau.',
            code: e.code,
            cause: e,
          ),
      };

  static bool _isSessionPermanentlyInvalid(String code) =>
      code == 'user-not-found' ||
      code == 'user-disabled' ||
      code == 'user-token-expired' ||
      code == 'invalid-user-token';
}
