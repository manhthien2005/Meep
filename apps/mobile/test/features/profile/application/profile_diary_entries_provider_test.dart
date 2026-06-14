import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/diary/application/diary_controller.dart';
import 'package:meep/features/diary/data/diary_content_block.dart';
import 'package:meep/features/diary/data/diary_entry.dart';
import 'package:meep/features/diary/data/diary_repository.dart';
import 'package:meep/features/profile/application/profile_diary_entries_provider.dart';

void main() {
  ProviderContainer makeContainer(_FakeDiaryRepository repo) {
    final c = ProviderContainer(
      overrides: [diaryRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    return c;
  }

  DiaryEntry entry({
    required String id,
    required DateTime createdAt,
    String authorUid = 'uid-alice',
  }) =>
      DiaryEntry(
        entryId: id,
        authorUid: authorUid,
        moodTemplate: MoodTemplate.happy,
        coverImageUrl: '',
        moodCaption: id,
        content: const [DiaryContentBlock.text(value: 'Body')],
        privacy: DiaryPrivacy.public,
        createdAt: createdAt,
        updatedAt: createdAt,
      );

  test('uid rỗng trả list rỗng và không gọi repository', () async {
    final repo = _FakeDiaryRepository([]);
    final c = makeContainer(repo);

    final result = await c.read(profileDiaryEntriesProvider('').future);

    expect(result, isEmpty);
    expect(repo.requestedUids, isEmpty);
  });

  test('gọi getPublicEntries(uid) và sort createdAt DESC', () async {
    final repo = _FakeDiaryRepository([
      entry(id: 'old', createdAt: DateTime.utc(2026, 5, 1)),
      entry(id: 'new', createdAt: DateTime.utc(2026, 5, 22)),
      entry(id: 'mid', createdAt: DateTime.utc(2026, 5, 10)),
    ]);
    final c = makeContainer(repo);

    final result =
        await c.read(profileDiaryEntriesProvider('uid-alice').future);

    expect(repo.requestedUids, ['uid-alice']);
    expect(result.map((e) => e.entryId).toList(), ['new', 'mid', 'old']);
  });
}

class _FakeDiaryRepository implements DiaryRepository {
  _FakeDiaryRepository(this.entries);

  final List<DiaryEntry> entries;
  final requestedUids = <String>[];

  @override
  Future<List<DiaryEntry>> getPublicEntries(String authorUid) async {
    requestedUids.add(authorUid);
    return entries.where((e) => e.authorUid == authorUid).toList();
  }

  @override
  Stream<List<DiaryEntry>> watchEntries(String authorUid) =>
      Stream.value(const []);

  @override
  Future<DiaryEntry?> getEntry(String entryId) async => null;

  @override
  Future<List<DiaryEntry>> searchEntries({
    required String authorUid,
    required String query,
  }) async =>
      const [];

  @override
  String reserveEntryId() => 'reserved-id';

  @override
  Future<DiaryEntry> createEntry(DiaryEntry entry) async => entry;

  @override
  Future<void> updateEntry(DiaryEntry entry) async {}

  @override
  Future<void> updatePrivacy({
    required String entryId,
    required DiaryPrivacy privacy,
  }) async {}

  @override
  Future<void> deleteEntry(String entryId) async {}
}
