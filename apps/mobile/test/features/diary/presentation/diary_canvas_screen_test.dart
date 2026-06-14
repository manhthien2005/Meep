import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/diary/application/diary_controller.dart';
import 'package:meep/features/diary/data/diary_entry.dart';
import 'package:meep/features/diary/data/diary_repository.dart';
import 'package:meep/features/diary/data/firebase_diary_repository.dart';
import 'package:meep/features/diary/presentation/diary_canvas_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const uid = 'uid-owner';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget host(_FakeDiaryRepository repo) {
    return ProviderScope(
      overrides: [
        currentUidProvider.overrideWith((ref) => Stream.value(uid)),
        diaryRepositoryProvider.overrideWithValue(repo),
        diaryStorageClientProvider.overrideWithValue(_FakeStorageClient()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DiaryCanvasScreen(
                          mode: DiaryCanvasMode.create,
                          moodTemplate: MoodTemplate.happy,
                        ),
                      ),
                    );
                  },
                  child: const Text('OPEN_CANVAS'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> openCanvas(
    WidgetTester tester,
    _FakeDiaryRepository repo,
  ) async {
    await tester.pumpWidget(host(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_CANVAS'));
    await tester.pumpAndSettle();
  }

  Future<void> enterContentAndSave(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextField, 'Viết nhật ký của bạn...'),
      'Hôm nay trời đẹp',
    );
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Lưu'), warnIfMissed: false);
    await tester.pump();
  }

  testWidgets('saving hiện loading, chặn tap lặp, success quay về list',
      (tester) async {
    final repo = _FakeDiaryRepository(blockCreate: true);
    await openCanvas(tester, repo);

    await enterContentAndSave(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(repo.createCalls, 1);
    expect(repo.lastCreated?.privacy, DiaryPrivacy.private);

    await tester.tap(find.bySemanticsLabel('Lưu'), warnIfMissed: false);
    await tester.pump();

    expect(repo.createCalls, 1);

    repo.completeCreate();
    await tester.pumpAndSettle();

    expect(find.text('OPEN_CANVAS'), findsOneWidget);
  });

  testWidgets('chọn Công khai rồi lưu truyền DiaryPrivacy.public',
      (tester) async {
    final repo = _FakeDiaryRepository();
    await openCanvas(tester, repo);

    await tester.tap(find.bySemanticsLabel('Quyền riêng tư'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Công khai'));
    await tester.tap(find.text('Xong'));
    await tester.pumpAndSettle();

    await enterContentAndSave(tester);
    await tester.pumpAndSettle();

    expect(repo.createCalls, 1);
    expect(repo.lastCreated?.privacy, DiaryPrivacy.public);
  });
}

class _FakeDiaryRepository implements DiaryRepository {
  _FakeDiaryRepository({this.blockCreate = false});

  final bool blockCreate;
  final _entries = <DiaryEntry>[];
  Completer<void>? _createCompleter;
  int createCalls = 0;
  DiaryEntry? lastCreated;

  @override
  String reserveEntryId() => 'entry-new';

  @override
  Future<DiaryEntry> createEntry(DiaryEntry entry) async {
    createCalls++;
    lastCreated = entry;
    if (blockCreate) {
      _createCompleter ??= Completer<void>();
      await _createCompleter!.future;
    }
    _entries.add(entry);
    return entry;
  }

  void completeCreate() {
    _createCompleter?.complete();
  }

  @override
  Stream<List<DiaryEntry>> watchEntries(String authorUid) => Stream.value(
        _entries.where((e) => e.authorUid == authorUid).toList(),
      );

  @override
  Future<DiaryEntry?> getEntry(String entryId) async {
    for (final entry in _entries) {
      if (entry.entryId == entryId) return entry;
    }
    return null;
  }

  @override
  Future<List<DiaryEntry>> getPublicEntries(String authorUid) async => _entries
      .where(
        (e) => e.authorUid == authorUid && e.privacy == DiaryPrivacy.public,
      )
      .toList();

  @override
  Future<List<DiaryEntry>> searchEntries({
    required String authorUid,
    required String query,
  }) async =>
      const [];

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

class _FakeStorageClient implements DiaryStorageClient {
  @override
  Future<String> upload({
    required String uid,
    required String entryId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async =>
      'https://stub/$uid/$entryId/$fileName';

  @override
  Future<void> deletePrefix(String prefix) async {}
}
