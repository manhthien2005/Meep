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

  /// Create a new entry. Returns the created entry with server timestamps.
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
