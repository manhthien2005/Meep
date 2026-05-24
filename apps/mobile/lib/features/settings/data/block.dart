import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'block.freezed.dart';
part 'block.g.dart';

/// A block record. Doc ID = `{blockerUid}_{blockedUid}` — NOT sorted.
/// This is asymmetric: blocker initiates, blocked is the target.
@freezed
class Block with _$Block {
  const factory Block({
    required String blockId,
    required String blockerUid,
    required String blockedUid,
    @TimestampConverter() required DateTime createdAt,
  }) = _Block;

  factory Block.fromJson(Map<String, dynamic> json) => _$BlockFromJson(json);
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
