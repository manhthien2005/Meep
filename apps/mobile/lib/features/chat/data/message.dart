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

    /// Reply-to post id. Pattern FB story reply / Locket: mỗi message reply
    /// gắn với 1 post → ChatThreadView render mini thumbnail card phía trên
    /// bubble cho message này (KHÔNG dùng conversation-level header). User
    /// reply nhiều posts khác nhau trong cùng chat → mỗi reply có thumbnail
    /// riêng.
    String? quotedPostId,
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
