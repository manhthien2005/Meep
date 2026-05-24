import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

/// Notification types persisted to Firestore.
/// NOTE: new_post is NOT here — push only, no doc saved per spec.
enum NotificationType { friendRequest, friendAccepted, reaction }

@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String notifId,
    required NotificationType type,
    required String title,
    required String body,
    @Default({}) Map<String, String> data,
    @Default(false) bool read,
    @TimestampConverter() required DateTime createdAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
}

class TimestampConverter implements JsonConverter<DateTime, Object> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object json) {
    if (json is Timestamp) return json.toDate();
    if (json is String) return DateTime.parse(json);
    return DateTime.fromMillisecondsSinceEpoch(json as int);
  }

  @override
  Object toJson(DateTime date) => Timestamp.fromDate(date);
}
