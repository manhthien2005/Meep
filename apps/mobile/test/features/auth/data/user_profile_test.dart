import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/auth/data/user_profile.dart';

void main() {
  group('UserProfile', () {
    final baseJson = {
      'uid': 'uid-123',
      'email': 'alice@example.com',
      'displayName': 'Alice Nguyen',
      'username': 'alice',
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
    };

    test('fromJson với Firestore Timestamp → DateTime', () {
      final profile = UserProfile.fromJson(baseJson);
      expect(profile.createdAt, DateTime(2026, 1, 1));
      expect(profile.updatedAt, DateTime(2026, 1, 2));
    });

    test('fromJson với String ISO → DateTime', () {
      final json = {
        ...baseJson,
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-02T00:00:00.000',
      };
      final profile = UserProfile.fromJson(json);
      expect(profile.createdAt, DateTime(2026, 1, 1));
    });

    test('counter fields default to 0 khi không có trong json', () {
      final profile = UserProfile.fromJson(baseJson);
      expect(profile.postCount, 0);
      expect(profile.friendCount, 0);
      expect(profile.spaceCount, 0);
    });

    test('nullable fields trả null khi không có trong json', () {
      final profile = UserProfile.fromJson(baseJson);
      expect(profile.avatarUrl, isNull);
      expect(profile.bio, isNull);
      expect(profile.dateOfBirth, isNull);
      expect(profile.phoneNumber, isNull);
      expect(profile.gender, isNull);
    });

    test('toJson → Timestamp cho DateTime fields', () {
      final profile = UserProfile.fromJson(baseJson);
      final json = profile.toJson();
      expect(json['createdAt'], isA<Timestamp>());
      expect(json['updatedAt'], isA<Timestamp>());
    });

    test('fromJson/toJson round-trip không mất data', () {
      final original = UserProfile(
        uid: 'uid-1',
        email: 'test@example.com',
        displayName: 'Test User',
        username: 'testuser',
        avatarUrl: 'https://example.com/avatar.jpg',
        bio: 'Hello world',
        postCount: 5,
        friendCount: 10,
        spaceCount: 2,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );
      final json = original.toJson();
      final restored = UserProfile.fromJson(json);
      expect(restored.uid, original.uid);
      expect(restored.email, original.email);
      expect(restored.displayName, original.displayName);
      expect(restored.username, original.username);
      expect(restored.avatarUrl, original.avatarUrl);
      expect(restored.bio, original.bio);
      expect(restored.postCount, original.postCount);
      expect(restored.friendCount, original.friendCount);
      expect(restored.spaceCount, original.spaceCount);
    });

    test('copyWith chỉ thay đổi field được chỉ định', () {
      final profile = UserProfile.fromJson(baseJson);
      final updated = profile.copyWith(bio: 'New bio');
      expect(updated.bio, 'New bio');
      expect(updated.uid, profile.uid);
      expect(updated.email, profile.email);
    });
  });
}
