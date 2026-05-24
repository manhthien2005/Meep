import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'space_member.freezed.dart';
part 'space_member.g.dart';

enum SpaceRole { creator, member }

@freezed
class SpaceMember with _$SpaceMember {
  const factory SpaceMember({
    required String uid,
    required SpaceRole role,
    @TimestampConverter() required DateTime joinedAt,
  }) = _SpaceMember;

  factory SpaceMember.fromJson(Map<String, dynamic> json) =>
      _$SpaceMemberFromJson(json);
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
