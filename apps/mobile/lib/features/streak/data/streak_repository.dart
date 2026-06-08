import 'package:meep/shared/models/post.dart';

/// Read-only queries for Streak/Kỷ niệm Module.
///
/// Spec: `docs/specs/2026-05-22-streak.md` (v2, 2026-06-04)
/// Streak KHÔNG có Firestore collection riêng — read-only từ `/posts`.
abstract class StreakRepository {
  /// Watch posts của [uid] trong [month] (local timezone), loại bỏ Space posts.
  ///
  /// Query:
  ///   WHERE authorId == uid
  ///   AND   spaceId  == null
  ///   AND   createdAt >= startOfMonthLocal([month])
  ///   AND   createdAt <  startOfNextMonthLocal([month])
  ///   ORDER BY createdAt ASC
  ///
  /// Throws [AppError] khi Firestore failure (mapped tại impl boundary).
  Stream<List<Post>> watchUserMonth(String uid, DateTime month);

  /// Read once tất cả ngày user đã post (dedupe per day, local timezone).
  ///
  /// Query:
  ///   WHERE authorId == uid
  ///   AND   spaceId  == null
  ///   ORDER BY createdAt DESC
  ///
  /// Cached trong [StreakController] — chỉ refetch khi mở màn hoặc sau
  /// `postController.deletePost()` trigger invalidate.
  Future<List<DateTime>> getUserAllDates(String uid);
}
