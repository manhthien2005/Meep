import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:meep/features/diary/data/diary_content_block.dart';

part 'diary_entry.freezed.dart';
part 'diary_entry.g.dart';

/// Mood template — determines background shape + cover clip shape in Mood zone.
enum MoodTemplate { happy, bored, tired, shy, sad }

/// Privacy level for a diary entry.
enum DiaryPrivacy { private, public }

@freezed
class DiaryEntry with _$DiaryEntry {
  const factory DiaryEntry({
    required String entryId,
    required String authorUid,
    required MoodTemplate moodTemplate,
    required String coverImageUrl,

    /// Title shown in Mood zone. Max 50 chars.
    required String moodCaption,

    /// Ordered content blocks (text + images). Max 20 blocks.
    required List<DiaryContentBlock> content,
    @Default(DiaryPrivacy.private) DiaryPrivacy privacy,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _DiaryEntry;

  factory DiaryEntry.fromJson(Map<String, dynamic> json) =>
      _$DiaryEntryFromJson(json);
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
