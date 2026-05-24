import 'package:meep/features/notification/data/app_notification.dart';

abstract class NotificationRepository {
  /// Save (or replace) the FCM token for [uid].
  Future<void> saveFcmToken(String uid, String token);

  /// Delete all FCM tokens for [uid] on logout.
  Future<void> deleteFcmToken(String uid);

  /// Get notification history for [uid], newest first.
  Future<List<AppNotification>> getNotifications(String uid);

  /// Mark a notification as read.
  Future<void> markAsRead(String notifId);
}
