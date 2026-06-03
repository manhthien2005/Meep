import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/feed/data/post.dart';
import 'package:meep/features/streak/data/streak_repository.dart';

/// Firestore implementation of [StreakRepository].
///
/// Streak module read-only từ `/posts` — không có collection riêng, không
/// có Cloud Function. Filter `spaceId == null` server-side (Firestore null
/// equality match docs có explicit null hoặc field absent). Convert
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

    return _db
        .collection(_posts)
        .where('authorId', isEqualTo: uid)
        .where('spaceId', isNull: true)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
        )
        .where('createdAt', isLessThan: Timestamp.fromDate(startOfNextMonth))
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Post.fromJson({...doc.data(), 'postId': doc.id}))
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
          .where('spaceId', isNull: true)
          .orderBy('createdAt', descending: true)
          .get();

      final dayKeys = <DateTime>{};
      for (final doc in snap.docs) {
        final raw = doc.data()['createdAt'];
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
