import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:meep/core/config/app_config.dart';
import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/auth/data/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required FirebaseAuth auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
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
    // TODO(A/T7/ThienPDM): implement — needed by Profile/Settings for sensitive ops
    throw UnimplementedError('reauthenticateWithCredential — implement at T7');
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    // TODO(A/T7/ThienPDM): implement — needed by Profile for email change
    throw UnimplementedError('updateEmail — implement at T7');
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

  static bool _isSessionPermanentlyInvalid(String code) =>
      code == 'user-not-found' ||
      code == 'user-disabled' ||
      code == 'user-token-expired' ||
      code == 'invalid-user-token';
}
