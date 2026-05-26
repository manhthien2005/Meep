abstract final class AppConfig {
  static const shareBaseUrl = 'meep://profile';

  // Google Sign-In server client ID (Firebase project: meep-staging)
  static const googleServerClientId =
      '96172476682-sun74ljt6a3q3376vn1fvsfev8o2qhgv.apps.googleusercontent.com';

  // Android package name — keep in sync với android/app/build.gradle applicationId
  static const androidPackageName = 'dev.meep.meep';

  // Runtime environment: truyền qua --dart-define=FIREBASE_ENV=prod khi build prod.
  // Default: staging. Dùng để chọn Firebase project-specific configs.
  static const _env =
      String.fromEnvironment('FIREBASE_ENV', defaultValue: 'staging');

  // Firebase email action handler — deep-link target cho password reset email.
  // TODO(Round C/ThienPDM): cập nhật _prodUrl khi có custom domain prod.
  static const _stagingUrl =
      'https://meep-staging.firebaseapp.com/login/reset-password';
  static const _prodUrl = _stagingUrl; // placeholder — thay bằng prod domain
  static const passwordResetActionUrl = _env == 'prod' ? _prodUrl : _stagingUrl;
}
