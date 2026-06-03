import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
class Message with _$Message {
  const factory Message({
    required String messageId,
    required String senderId,

    /// Max 500 chars.
    required String text,
    @TimestampConverter() required DateTime createdAt,

    /// Denormalized display name của sender — populated lúc gửi (client cache
    /// từ currentUser profile). Optional cho backward compat: messages tạo
    /// trước Bug #2 fix sẽ KHÔNG có field này → group chat fallback render
    /// 'Người dùng'. Rule cap 50 chars.
    String? senderDisplayName,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
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
