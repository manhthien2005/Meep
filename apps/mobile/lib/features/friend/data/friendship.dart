import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'friendship.freezed.dart';
part 'friendship.g.dart';

/// Bidirectional friendship between two users.
/// Doc ID = [pairIdOf] result: `min(uid1, uid2)_max(uid1, uid2)`.
@freezed
class Friendship with _$Friendship {
  const factory Friendship({
    required String uid1,
    required String uid2,

    /// Both UIDs — convenience for Firestore array-contains queries.
    required List<String> members,
    @TimestampConverter() required DateTime createdAt,
  }) = _Friendship;

  factory Friendship.fromJson(Map<String, dynamic> json) =>
      _$FriendshipFromJson(json);
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
