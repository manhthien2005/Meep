import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferences {
  NotificationPreferences({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const _bannerSuppressedKey = 'notification_banner_suppressed';
  static const _fcmTokenKeyPrefix = 'fcm_token_saved_';

  bool get isBannerSuppressed => _prefs.getBool(_bannerSuppressedKey) ?? false;

  Future<void> setBannerSuppressed(bool value) =>
      _prefs.setBool(_bannerSuppressedKey, value);

  /// Token FCM đã ghi Firestore thành công cho [uid] (null nếu chưa ghi).
  /// Keyed theo uid để user B login cùng device không bị skip ghi khi token
  /// trùng token của user A (NOTIF-PERF-001).
  String? cachedFcmToken(String uid) =>
      _prefs.getString('$_fcmTokenKeyPrefix$uid');

  Future<void> setCachedFcmToken(String uid, String token) =>
      _prefs.setString('$_fcmTokenKeyPrefix$uid', token);

  Future<void> clearCachedFcmToken(String uid) =>
      _prefs.remove('$_fcmTokenKeyPrefix$uid');
}
