import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

enum ConversationType { direct, space }

enum ConversationStatus {
  active,

  /// One participant has blocked the other — conversation is read-only.
  blocked,

  /// Friendship was removed — conversation is read-only.
  unfriended,
}

@freezed
class Conversation with _$Conversation {
  const factory Conversation({
    required String conversationId,
    required ConversationType type,
    required List<String> participantIds,
    String? spaceId,

    /// Preview of last message (max 50 chars).
    @Default('') String lastMessage,
    @TimestampConverter() required DateTime lastMessageAt,
    @Default('') String lastSenderId,
    @Default(ConversationStatus.active) ConversationStatus status,
    @TimestampConverter() required DateTime createdAt,

    /// Per-user "last read" timestamp keyed by uid. Empty map = nobody đã đọc.
    /// Unread count derive: lastMessageAt > lastReadAt[uid] → có unread.
    /// Update qua [ConversationRepository.markAsRead] khi user mở chat screen
    /// hoặc nhận msg mới trong screen.
    @TimestampMapConverter()
    @Default(<String, DateTime>{})
    Map<String, DateTime> lastReadAt,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
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

/// Converter cho `Map<String, DateTime>` field — Firestore lưu
/// `Map<String, Timestamp>`. Tolerant với 3 type giống [TimestampConverter]
/// để fake_cloud_firestore tests (dùng `Timestamp.fromDate(DateTime)`) +
/// production Firestore (raw `Timestamp`).
class TimestampMapConverter
    implements JsonConverter<Map<String, DateTime>, Object?> {
  const TimestampMapConverter();

  @override
  Map<String, DateTime> fromJson(Object? json) {
    if (json == null) return <String, DateTime>{};
    final raw = json as Map<dynamic, dynamic>;
    return <String, DateTime>{
      for (final entry in raw.entries)
        entry.key as String: _parseDate(entry.value),
    };
  }

  @override
  Object toJson(Map<String, DateTime> map) => <String, Object>{
        for (final entry in map.entries)
          entry.key: Timestamp.fromDate(entry.value),
      };

  static DateTime _parseDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.fromMillisecondsSinceEpoch(value! as int);
  }
}
