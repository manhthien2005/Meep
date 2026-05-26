/// Centralized validators cho auth flow.
/// Tất cả validation logic ở đây để controller + UI share cùng một nguồn truth.
abstract final class AuthValidators {
  // Email — RFC 5322 simplified: local@domain.tld (tld ≥ 2 ký tự).
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  // Username — lowercase alphanumeric + underscore, 3..20 ký tự.
  static final _usernameRegex = RegExp(r'^[a-z0-9_]+$');

  // Min length cho password (Firebase Auth yêu cầu ≥ 6, ta dùng 8 cho strength).
  static const passwordMinLength = 8;

  // Min length cho displayName (Họ + Tên gộp).
  static const displayNameMinLength = 2;

  static const usernameMinLength = 3;
  static const usernameMaxLength = 20;

  /// Trả về `true` nếu email hợp lệ. Trim trước khi check.
  static bool isEmailValid(String email) {
    return _emailRegex.hasMatch(email.trim());
  }

  /// Trả về `true` nếu password đạt min length.
  static bool isPasswordValid(String password) {
    return password.length >= passwordMinLength;
  }

  /// Trả về `true` nếu displayName đạt min length sau khi trim.
  static bool isDisplayNameValid(String displayName) {
    return displayName.trim().length >= displayNameMinLength;
  }

  /// Trả về `true` nếu username đúng format (lowercase, alphanumeric + _, 3..20).
  /// Caller phải lowercase + trim trước khi gọi.
  static bool isUsernameFormatValid(String username) {
    return username.length >= usernameMinLength &&
        username.length <= usernameMaxLength &&
        _usernameRegex.hasMatch(username);
  }
}
