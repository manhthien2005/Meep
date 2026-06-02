import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'friend_request.freezed.dart';
part 'friend_request.g.dart';

enum FriendRequestStatus { pending, accepted, declined, cancelled }

@freezed
class FriendRequest with _$FriendRequest {
  const factory FriendRequest({
    required String requestId,
    required String senderId,
    required String receiverId,
    required FriendRequestStatus status,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _FriendRequest;

  factory FriendRequest.fromJson(Map<String, dynamic> json) =>
      _$FriendRequestFromJson(json);
}

/// Converts Firestore [Timestamp] ↔ [DateTime].
/// Object? (nullable) để xử lý pending serverTimestamp: khi Firestore client
/// emit snapshot trước server confirm, trường createdAt/updatedAt có thể là null.
/// Fallback: DateTime.now() — chỉ ảnh hưởng snapshot tạm thời 0.3-0.5s,
/// emit tiếp theo sẽ có giá trị thật từ server.
class TimestampConverter implements JsonConverter<DateTime, Object?> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object? json) {
    if (json == null) return DateTime.now();
    if (json is Timestamp) return json.toDate();
    if (json is String) return DateTime.parse(json);
    return DateTime.fromMillisecondsSinceEpoch(json as int);
  }

  @override
  Object toJson(DateTime date) => Timestamp.fromDate(date);
}
