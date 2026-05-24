import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/diary/data/diary_entry.dart';
import 'package:meep/features/diary/data/diary_repository.dart';

part 'diary_controller.freezed.dart';
part 'diary_controller.g.dart';

@freezed
class DiaryState with _$DiaryState {
  const factory DiaryState({
    @Default([]) List<DiaryEntry> entries,
    @Default(false) bool isLoading,
    @Default(false) bool isSaving,
    String? errorMessage,
  }) = _DiaryState;
}

@Riverpod(keepAlive: true)
DiaryRepository diaryRepository(DiaryRepositoryRef ref) =>
    throw UnimplementedError(
      'diaryRepositoryProvider must be overridden — '
      'wire FirebaseDiaryRepository in main.dart (TODO: D/T1/TBD)',
    );

@riverpod
class DiaryController extends _$DiaryController {
  @override
  DiaryState build() => const DiaryState();

  Future<void> loadEntries(String authorUid) async {
    // TODO(D/T2/TBD): implement loadEntries
    throw UnimplementedError('loadEntries — TODO: D/T2/TBD');
  }

  Future<void> saveEntry(DiaryEntry entry) async {
    // TODO(D/T3/TBD): implement saveEntry — decides create vs update by entryId
    throw UnimplementedError('saveEntry — TODO: D/T3/TBD');
  }

  Future<void> updatePrivacy({
    required String entryId,
    required DiaryPrivacy privacy,
  }) async {
    // TODO(D/T4/TBD): implement updatePrivacy
    throw UnimplementedError('updatePrivacy — TODO: D/T4/TBD');
  }

  Future<List<DiaryEntry>> searchEntries({
    required String authorUid,
    required String query,
  }) async {
    // TODO(D/T5/TBD): implement searchEntries
    throw UnimplementedError('searchEntries — TODO: D/T5/TBD');
  }

  Future<void> deleteEntry(String entryId) async {
    // TODO(D/T6/TBD): implement deleteEntry
    throw UnimplementedError('deleteEntry — TODO: D/T6/TBD');
  }
}
