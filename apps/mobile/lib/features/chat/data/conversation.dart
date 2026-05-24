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

    /// postId that triggered this conversation, if any.
    String? quotedPostId,

    /// Preview of last message (max 50 chars).
    @Default('') String lastMessage,
    @TimestampConverter() required DateTime lastMessageAt,
    @Default('') String lastSenderId,
    @Default(ConversationStatus.active) ConversationStatus status,
    @TimestampConverter() required DateTime createdAt,
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
