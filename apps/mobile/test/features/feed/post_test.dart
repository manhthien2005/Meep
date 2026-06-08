import 'package:flutter_test/flutter_test.dart';
import 'package:meep/shared/models/post.dart';

Post _single({String imageUrl = 'https://example.com/photo.jpg'}) => Post(
      postId: 'p1',
      authorId: 'uid1',
      authorName: 'Test User',
      imageUrl: imageUrl,
      audienceType: AudienceType.all,
      createdAt: DateTime(2026, 5, 31),
    );

Post _dual({
  String back = 'https://example.com/back.jpg',
  String front = 'https://example.com/front.jpg',
}) =>
    Post(
      postId: 'p2',
      authorId: 'uid1',
      authorName: 'Test User',
      backImageUrl: back,
      frontImageUrl: front,
      isDualCamera: true,
      audienceType: AudienceType.all,
      createdAt: DateTime(2026, 5, 31),
    );

void main() {
  group('isDualCamera default', () {
    test('single post defaults isDualCamera to false', () {
      expect(_single().isDualCamera, isFalse);
    });
  });

  group('coverImageUrl', () {
    test('single mode returns imageUrl', () {
      expect(_single().coverImageUrl, 'https://example.com/photo.jpg');
    });

    test('dual mode returns back lens as cover', () {
      expect(_dual().coverImageUrl, 'https://example.com/back.jpg');
    });

    test('falls back to front when only front present', () {
      final post = Post(
        postId: 'p3',
        authorId: 'uid1',
        authorName: 'Test User',
        frontImageUrl: 'https://example.com/front.jpg',
        isDualCamera: true,
        audienceType: AudienceType.all,
        createdAt: DateTime(2026, 5, 31),
      );
      expect(post.coverImageUrl, 'https://example.com/front.jpg');
    });

    test('returns empty string when no image present', () {
      final post = Post(
        postId: 'p4',
        authorId: 'uid1',
        authorName: 'Test User',
        audienceType: AudienceType.all,
        createdAt: DateTime(2026, 5, 31),
      );
      expect(post.coverImageUrl, '');
    });
  });

  group('json round-trip', () {
    test('dual post serializes both lenses and isDualCamera flag', () {
      final json = _dual().toJson();
      expect(json['backImageUrl'], 'https://example.com/back.jpg');
      expect(json['frontImageUrl'], 'https://example.com/front.jpg');
      expect(json['isDualCamera'], isTrue);
      expect(json['imageUrl'], isNull);
      // coverImageUrl is a getter, must not leak into serialized data.
      expect(json.containsKey('coverImageUrl'), isFalse);
    });

    test('dual post survives fromJson(toJson())', () {
      final restored = Post.fromJson(_dual().toJson());
      expect(restored.isDualCamera, isTrue);
      expect(restored.backImageUrl, 'https://example.com/back.jpg');
      expect(restored.frontImageUrl, 'https://example.com/front.jpg');
      expect(restored.imageUrl, isNull);
    });

    test('single post survives fromJson(toJson())', () {
      final restored = Post.fromJson(_single().toJson());
      expect(restored.isDualCamera, isFalse);
      expect(restored.imageUrl, 'https://example.com/photo.jpg');
      expect(restored.backImageUrl, isNull);
      expect(restored.frontImageUrl, isNull);
    });

    test('legacy doc without dual fields defaults isDualCamera false', () {
      // Simulates posts created before dual camera shipped.
      final restored = Post.fromJson({
        'postId': 'legacy',
        'authorId': 'uid1',
        'authorName': 'Test User',
        'imageUrl': 'https://example.com/old.jpg',
        'audienceType': 'all',
        'audienceUids': <String>[],
        'createdAt': '2026-05-01T00:00:00.000',
      });
      expect(restored.isDualCamera, isFalse);
      expect(restored.coverImageUrl, 'https://example.com/old.jpg');
    });
  });
}
