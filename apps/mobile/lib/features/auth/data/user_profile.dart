import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// Full user profile — source of truth is Profile spec.
/// Auth creates the doc with initial values; Profile module owns the full schema.
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String uid,
    required String email,
    required String displayName,
    required String username,
    String? avatarUrl,
    String? bio,
    String? dateOfBirth,
    String? phoneNumber,

    /// 'male' | 'female' | 'other'
    String? gender,

    /// Denormalized counters — updated by Cloud Functions.
    @Default(0) int postCount,
    @Default(0) int friendCount,
    @Default(0) int spaceCount,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
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
