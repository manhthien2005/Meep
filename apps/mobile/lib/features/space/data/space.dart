import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'space.freezed.dart';
part 'space.g.dart';

@freezed
class Space with _$Space {
  const factory Space({
    required String spaceId,

    /// Max 30 chars.
    required String name,

    /// Single emoji char, default "👥".
    required String iconEmoji,

    /// 7-char hex color e.g. "#00DEEE".
    required String colorHex,
    required String creatorId,

    /// Denormalized count — max 10.
    @Default(0) int memberCount,

    /// Denormalized for array-contains queries.
    @Default([]) List<String> memberIds,
    @TimestampConverter() required DateTime createdAt,

    /// Null = active; non-null = soft-deleted.
    @TimestampConverter() DateTime? deletedAt,
  }) = _Space;

  factory Space.fromJson(Map<String, dynamic> json) => _$SpaceFromJson(json);
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
