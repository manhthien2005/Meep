import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';
part 'post.g.dart';

enum CaptionType { text, location, weather, music, star, time, streak }

enum AudienceType { all, select }

@freezed
class Post with _$Post {
  const factory Post({
    required String postId,
    required String authorId,
    required String authorName,
    String? authorAvatarUrl,
    required String imageUrl,
    String? caption,
    CaptionType? captionType,
    required AudienceType audienceType,
    @Default([]) List<String> audienceUids,

    /// Reserved for Space module. Null = all-friends post.
    /// When set: broadcast to all Space members; audienceType/audienceUids ignored.
    String? spaceId,
    @TimestampConverter() required DateTime createdAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
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
