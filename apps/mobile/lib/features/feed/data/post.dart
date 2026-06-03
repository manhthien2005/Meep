import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';
part 'post.g.dart';

enum CaptionType { text, location, weather, music, star, time, streak }

enum AudienceType { all, select }

@freezed
class Post with _$Post {
  const Post._();

  const factory Post({
    required String postId,
    required String authorId,
    required String authorName,
    String? authorAvatarUrl,

    /// Single camera mode: imageUrl is set, backImageUrl/frontImageUrl are null.
    /// Dual camera mode: backImageUrl/frontImageUrl are set, imageUrl is null.
    String? imageUrl,
    String? backImageUrl,
    String? frontImageUrl,
    @Default(false) bool isDualCamera,
    String? caption,
    CaptionType? captionType,
    required AudienceType audienceType,
    @Default([]) List<String> audienceUids,

    /// Reserved for Space module. Null = all-friends post.
    /// When set: broadcast to all Space members; audienceType/audienceUids ignored.
    String? spaceId,

    /// Denormalized snapshot của Space.memberIds tại thời điểm tạo post.
    /// Dùng cho Firestore rule check `memberIds.hasAny([uid])` ở collection
    /// query (`WHERE spaceId == X`) — Firestore rules engine cần điều kiện
    /// expressible từ resource.data, không dùng get()/exists() cross-doc.
    /// Null khi post All-friends. Stale acceptable cho MVP (member rời/kick
    /// vẫn đọc được post cũ — không phải security issue, chỉ là cosmetic).
    @Default(<String>[]) List<String> memberIds,
    @TimestampConverter() required DateTime createdAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  /// Representative image for single-image contexts (grid thumbnail, share).
  /// Single mode → imageUrl. Dual mode → back lens (the "scene" photo).
  String get coverImageUrl => imageUrl ?? backImageUrl ?? frontImageUrl ?? '';
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
