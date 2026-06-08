import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:meep/features/auth/data/user_profile.dart';

part 'public_profile.freezed.dart';
part 'public_profile.g.dart';

/// Minimal profile safe for public friend discovery.
@freezed
class PublicProfile with _$PublicProfile {
  const factory PublicProfile({
    required String uid,
    required String displayName,
    required String username,
    String? avatarUrl,
    String? bio,
    @Default(true) bool isSearchable,
    @TimestampConverter() required DateTime updatedAt,
  }) = _PublicProfile;

  factory PublicProfile.fromJson(Map<String, dynamic> json) =>
      _$PublicProfileFromJson(json);

  factory PublicProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data();
    if (data == null) {
      throw StateError('Public profile ${snap.reference.path} is missing data');
    }

    return PublicProfile.fromJson({
      ...data,
      'uid': data['uid'] ?? snap.reference.parent.parent?.id,
    });
  }
}
