import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferences {
  NotificationPreferences({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const _bannerSuppressedKey = 'notification_banner_suppressed';

  bool get isBannerSuppressed => _prefs.getBool(_bannerSuppressedKey) ?? false;

  Future<void> setBannerSuppressed(bool value) =>
      _prefs.setBool(_bannerSuppressedKey, value);
}
