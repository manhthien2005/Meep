import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/streak/data/firebase_streak_repository.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirebaseStreakRepository repo;

  const uid = 'uid-alice';

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirebaseStreakRepository(db);
  });

  Future<void> seedPost({
    required String postId,
    required String authorId,
    required DateTime createdAt,
    List<String> spaceIds = const [],
  }) {
    return db.collection('posts').doc(postId).set({
      'postId': postId,
      'authorId': authorId,
      'authorName': 'Author $authorId',
      'imageUrl': 'https://example.com/$postId.jpg',
      'audienceType': 'all',
      'audienceUids': <String>[],
      'spaceIds': spaceIds,
      'createdAt': Timestamp.fromDate(createdAt),
    });
  }

  group('watchUserMonth', () {
    test('trả posts trong tháng + spaceId == null only', () async {
      // Tháng đang xem: 2026-05
      final month = DateTime(2026, 5);

      // 2 in-month, spaceId null → expect
      await seedPost(
        postId: 'p1',
        authorId: uid,
        createdAt: DateTime(2026, 5, 3, 10),
      );
      await seedPost(
        postId: 'p2',
        authorId: uid,
        createdAt: DateTime(2026, 5, 20, 14),
      );

      // 1 in-month nhưng spaceIds non-empty (Space post) → loại
      await seedPost(
        postId: 'p3',
        authorId: uid,
        createdAt: DateTime(2026, 5, 10),
        spaceIds: ['space-x'],
      );

      // 1 in-month nhưng author khác → loại
      await seedPost(
        postId: 'p4',
        authorId: 'uid-bob',
        createdAt: DateTime(2026, 5, 15),
      );

      // 1 ngoài tháng → loại
      await seedPost(
        postId: 'p5',
        authorId: uid,
        createdAt: DateTime(2026, 4, 30),
      );

      final stream = repo.watchUserMonth(uid, month);
      final posts = await stream.first;

      expect(posts.length, 2);
      expect(posts.map((p) => p.postId).toSet(), {'p1', 'p2'});
      // ORDER BY createdAt DESC — dùng index hiện có; thumbnail = post mới nhất/ngày
      expect(posts.first.postId, 'p2');
    });

    test('tháng không có post → empty list', () async {
      final month = DateTime(2026, 5);
      await seedPost(
        postId: 'p1',
        authorId: uid,
        createdAt: DateTime(2026, 3, 15),
      );

      final posts = await repo.watchUserMonth(uid, month).first;
      expect(posts, isEmpty);
    });
  });

  group('getUserAllDates', () {
    test('dedupe per day (2 posts cùng ngày → 1 entry)', () async {
      await seedPost(
        postId: 'p1',
        authorId: uid,
        createdAt: DateTime(2026, 5, 22, 8),
      );
      await seedPost(
        postId: 'p2',
        authorId: uid,
        createdAt: DateTime(2026, 5, 22, 20),
      );
      await seedPost(
        postId: 'p3',
        authorId: uid,
        createdAt: DateTime(2026, 5, 23, 12),
      );

      final dates = await repo.getUserAllDates(uid);
      expect(dates.length, 2);
      // Sort DESC (newest first) — dùng cho calculateStreak
      expect(dates[0], DateTime(2026, 5, 23));
      expect(dates[1], DateTime(2026, 5, 22));
    });

    test(
        'filter All-friends posts only (loại Space posts qua spaceIds non-empty)',
        () async {
      await seedPost(
        postId: 'p1',
        authorId: uid,
        createdAt: DateTime(2026, 5, 22),
      );
      await seedPost(
        postId: 'p2',
        authorId: uid,
        createdAt: DateTime(2026, 5, 23),
        spaceIds: ['space-x'],
      );

      final dates = await repo.getUserAllDates(uid);
      expect(dates.length, 1);
      expect(dates.first, DateTime(2026, 5, 22));
    });

    test('chưa có post → empty list', () async {
      final dates = await repo.getUserAllDates(uid);
      expect(dates, isEmpty);
    });

    test('filter authorId — không lấy của user khác', () async {
      await seedPost(
        postId: 'p1',
        authorId: uid,
        createdAt: DateTime(2026, 5, 22),
      );
      await seedPost(
        postId: 'p2',
        authorId: 'uid-bob',
        createdAt: DateTime(2026, 5, 23),
      );

      final dates = await repo.getUserAllDates(uid);
      expect(dates.length, 1);
      expect(dates.first, DateTime(2026, 5, 22));
    });
  });
}
