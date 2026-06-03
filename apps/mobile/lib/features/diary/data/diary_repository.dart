import 'package:meep/features/diary/data/diary_entry.dart';

abstract class DiaryRepository {
  /// Stream of the current user's diary entries, newest first.
  Stream<List<DiaryEntry>> watchEntries(String authorUid);

  /// Returns a single entry by ID.
  Future<DiaryEntry?> getEntry(String entryId);

  /// Returns public entries for [authorUid] — used by Profile module.
  Future<List<DiaryEntry>> getPublicEntries(String authorUid);

  /// Search entries by mood caption or content text.
  Future<List<DiaryEntry>> searchEntries({
    required String authorUid,
    required String query,
  });

  /// Reserve a new entry ID without writing — controller dùng trước upload
  /// Storage để Storage path `diary/{uid}/{entryId}/...` khớp Firestore doc.
  String reserveEntryId();

  /// Create a new entry. Returns the created entry with server timestamps.
  /// If [entry.entryId] is non-empty, the value is used (e.g. ID reserved
  /// via [reserveEntryId]). If empty, an auto-generated ID is assigned.
  Future<DiaryEntry> createEntry(DiaryEntry entry);

  /// Update an existing entry.
  Future<void> updateEntry(DiaryEntry entry);

  /// Update only the privacy setting of an entry.
  Future<void> updatePrivacy({
    required String entryId,
    required DiaryPrivacy privacy,
  });

  /// Permanently delete an entry and its Storage assets.
  Future<void> deleteEntry(String entryId);
}
