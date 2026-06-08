import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meep/core/error/app_error.dart';
import 'package:meep/shared/models/post.dart';
import 'package:meep/features/streak/data/streak_repository.dart';

/// Firestore implementation of [StreakRepository].
///
/// Streak module read-only từ `/posts` — không có collection riêng, không
/// có Cloud Function. Filter All-friends posts (loại Space posts) bằng
/// **client-side** trên `spaceIds.isEmpty` — KHÔNG dùng `.where('spaceId',
/// isNull: true)` vì Post documents không có field `spaceId` (chỉ có
/// `spaceIds` plural). Firestore composite index yêu cầu field tồn tại
/// để match → query null trên field absent return empty trong production
/// (fake_cloud_firestore lenient nên test pass nhưng prod broken). Convert
/// `createdAt` về local timezone trước khi tính `dayKey` (timezone contract
/// spec §Data model).
class FirebaseStreakRepository implements StreakRepository {
  FirebaseStreakRepository(this._db);

  final FirebaseFirestore _db;

  static const _posts = 'posts';

  @override
  Stream<List<Post>> watchUserMonth(String uid, DateTime month) {
    final startOfMonth = DateTime(month.year, month.month);
    final startOfNextMonth = DateTime(month.year, month.month + 1);

    // OrderBy DESC để dùng index `(authorId, createdAt DESC)` đã có sẵn.
    // dayToPostIndex.putIfAbsent → khi 1 ngày có nhiều post, thumbnail
    // hiển thị post mới nhất của ngày đó (latest activity).
    return _db
        .collection(_posts)
        .where('authorId', isEqualTo: uid)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
        )
        .where('createdAt', isLessThan: Timestamp.fromDate(startOfNextMonth))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Post.fromJson({...doc.data(), 'postId': doc.id}))
              .where((p) => p.spaceIds.isEmpty)
              .toList(),
        )
        .handleError(_mapAndThrow);
  }

  @override
  Future<List<DateTime>> getUserAllDates(String uid) async {
    try {
      final snap = await _db
          .collection(_posts)
          .where('authorId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      final dayKeys = <DateTime>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        // Client-side filter Space posts (xem doc class).
        final spaceIds = data['spaceIds'];
        if (spaceIds is List && spaceIds.isNotEmpty) continue;
        final raw = data['createdAt'];
        if (raw is! Timestamp) continue;
        final local = raw.toDate().toLocal();
        dayKeys.add(DateTime(local.year, local.month, local.day));
      }
      // Sort DESC để controller dùng trực tiếp cho calculateStreak (newest first).
      final sorted = dayKeys.toList()..sort((a, b) => b.compareTo(a));
      return sorted;
    } on FirebaseException catch (e) {
      throw _mapStreakError(e);
    }
  }

  Never _mapAndThrow(Object e, [StackTrace? _]) {
    if (e is FirebaseException) throw _mapStreakError(e);
    throw AppError.fromUnknown(e, fallback: 'Không thể tải Kỷ niệm');
  }

  AppError _mapStreakError(FirebaseException e) => switch (e.code) {
        'permission-denied' => ForbiddenError('đọc bài viết'),
        'unavailable' || 'network-request-failed' => NetworkError(
            message: 'Không có kết nối mạng',
            cause: e,
          ),
        _ => UnexpectedError(
            message: e.message ?? 'Không thể tải Kỷ niệm',
            code: e.code,
            cause: e,
          ),
      };
}
