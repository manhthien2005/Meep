import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Scrub PII khỏi error message trước khi gửi lên Crashlytics.
///
/// Meep handle ảnh + friend graph cá nhân; CLAUDE.md §PII handling cấm log
/// email/caption/displayName. Crashlytics message có thể chứa các field này khi
/// FirebaseException bọc data — redact trước khi report.
class CrashlyticsHelper {
  CrashlyticsHelper(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  // Email: local@domain.tld
  static final _emailPattern = RegExp(
    r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}',
  );
  // Số điện thoại VN/quốc tế đơn giản: optional +, 9-15 digit.
  static final _phonePattern = RegExp(r'(\+?\d[\d\s-]{8,14}\d)');
  // Key-value nhạy cảm: caption=..., displayName: "...", email='...'
  static final _sensitiveKvPattern = RegExp(
    r'(caption|displayname|display_name|email|phone|token|fcmtoken|fcm_token)'
    r'''\s*[:=]\s*("[^"]*"|'[^']*'|[^\s,}]+)''',
    caseSensitive: false,
  );

  /// Trả về message đã redact PII. Pure — test riêng.
  static String scrub(String input) {
    var out = input;
    out = out.replaceAllMapped(
      _sensitiveKvPattern,
      (m) => '${m.group(1)}=[REDACTED]',
    );
    out = out.replaceAll(_emailPattern, '[EMAIL]');
    out = out.replaceAll(_phonePattern, '[PHONE]');
    return out;
  }

  /// Record error với message đã scrub. Stack giữ nguyên (không chứa PII data).
  Future<void> recordScrubbedError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) {
    return _crashlytics.recordError(
      _ScrubbedError(scrub(error.toString())),
      stack,
      fatal: fatal,
    );
  }
}

/// Wrapper giữ message đã scrub làm `toString()` cho Crashlytics đọc.
class _ScrubbedError {
  _ScrubbedError(this._message);
  final String _message;
  @override
  String toString() => _message;
}
