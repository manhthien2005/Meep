import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/diary/data/diary_content_block.dart';
import 'package:meep/features/diary/data/diary_entry.dart';
import 'package:meep/features/diary/data/firebase_diary_repository.dart';

void main() {
  const ownerUid = 'uid-owner';
  const otherUid = 'uid-other';

  late FakeFirebaseFirestore firestore;
  late _StubDiaryStorageClient storage;
  late FirebaseDiaryRepository repo;

  DiaryEntry buildEntry({
    String entryId = '',
    String authorUid = ownerUid,
    MoodTemplate mood = MoodTemplate.happy,
    String coverImageUrl = 'https://cdn/cover.jpg',
    String moodCaption = 'Happy!',
    List<DiaryContentBlock> content = const [],
    DiaryPrivacy privacy = DiaryPrivacy.private,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      entryId: entryId,
      authorUid: authorUid,
      moodTemplate: mood,
      coverImageUrl: coverImageUrl,
      moodCaption: moodCaption,
      content: content.isEmpty
          ? const [DiaryContentBlock.text(value: 'Hôm nay đi chơi')]
          : content,
      privacy: privacy,
      createdAt: createdAt ?? DateTime.utc(2026, 5, 22),
      updatedAt: updatedAt ?? DateTime.utc(2026, 5, 22),
    );
  }

  Future<void> seedEntry(
    String entryId, {
    required String authorUid,
    DiaryPrivacy privacy = DiaryPrivacy.private,
    String moodCaption = 'Title',
    List<DiaryContentBlock> content = const [
      DiaryContentBlock.text(value: 'Body content'),
    ],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final entry = buildEntry(
      entryId: entryId,
      authorUid: authorUid,
      privacy: privacy,
      moodCaption: moodCaption,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
    await firestore.doc('diary/$entryId').set(<String, dynamic>{
      'entryId': entryId,
      'authorUid': entry.authorUid,
      'moodTemplate': entry.moodTemplate.name,
      'coverImageUrl': entry.coverImageUrl,
      'moodCaption': entry.moodCaption,
      'content': entry.content.map((b) => b.toJson()).toList(),
      'privacy': entry.privacy.name,
      'createdAt': Timestamp.fromDate(entry.createdAt),
      'updatedAt': Timestamp.fromDate(entry.updatedAt),
    });
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    storage = _StubDiaryStorageClient();
    repo = FirebaseDiaryRepository(
      firestore: firestore,
      storageClient: storage,
    );
  });

  group('createEntry', () {
    test('Firestore auto-ID + trả entry với entryId server-generated',
        () async {
      final draft = buildEntry();

      final created = await repo.createEntry(draft);

      expect(created.entryId, isNotEmpty);
      final snap = await firestore.doc('diary/${created.entryId}').get();
      expect(snap.exists, true);
      expect(snap.data()!['authorUid'], ownerUid);
      expect(snap.data()!['moodTemplate'], 'happy');
    });

    test('set createdAt + updatedAt qua serverTimestamp', () async {
      final draft = buildEntry();

      final created = await repo.createEntry(draft);

      final data =
          (await firestore.doc('diary/${created.entryId}').get()).data()!;
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['updatedAt'], isA<Timestamp>());
    });

    test('ghi authorUid vào field document để query đọc lại', () async {
      final draft = buildEntry();

      final created = await repo.createEntry(draft);

      final data =
          (await firestore.doc('diary/${created.entryId}').get()).data()!;
      expect(data['authorUid'], ownerUid);
      expect(
        data.containsKey('entryId'),
        false,
        reason: 'entryId là snap.id, không lưu trùng vào field',
      );
    });

    test('throws ValidationError khi moodCaption > 50 chars', () async {
      final draft = buildEntry(moodCaption: 'x' * 51);

      await expectLater(
        repo.createEntry(draft),
        throwsA(
          isA<ValidationError>()
              .having((e) => e.code, 'code', 'diary/mood-caption-too-long'),
        ),
      );
    });

    test('throws ValidationError khi content > 20 blocks', () async {
      final blocks = List.generate(
        21,
        (i) => DiaryContentBlock.text(value: 'block $i'),
      );
      final draft = buildEntry(content: blocks);

      await expectLater(
        repo.createEntry(draft),
        throwsA(
          isA<ValidationError>()
              .having((e) => e.code, 'code', 'diary/too-many-blocks'),
        ),
      );
    });
  });

  group('watchEntries', () {
    test('emit chỉ entries của authorUid theo createdAt DESC', () async {
      await seedEntry(
        'e-old',
        authorUid: ownerUid,
        createdAt: DateTime.utc(2026, 5, 20),
      );
      await seedEntry(
        'e-new',
        authorUid: ownerUid,
        createdAt: DateTime.utc(2026, 5, 22),
      );
      await seedEntry(
        'e-other',
        authorUid: otherUid,
        createdAt: DateTime.utc(2026, 5, 21),
      );

      final first = await repo.watchEntries(ownerUid).first;

      expect(first.map((e) => e.entryId).toList(), ['e-new', 'e-old']);
    });

    test('emit list rỗng khi user chưa có entry nào', () async {
      final first = await repo.watchEntries(ownerUid).first;
      expect(first, isEmpty);
    });

    test('emit lại khi entry mới được thêm', () async {
      final values = <int>[];
      final sub = repo
          .watchEntries(ownerUid)
          .listen((entries) => values.add(entries.length));

      await Future<void>.delayed(Duration.zero);
      await seedEntry('e-1', authorUid: ownerUid);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(values.last, 1);
    });
  });

  group('getEntry', () {
    test('trả entry khi doc tồn tại', () async {
      await seedEntry('e-1', authorUid: ownerUid, moodCaption: 'Loaded');

      final entry = await repo.getEntry('e-1');

      expect(entry, isNotNull);
      expect(entry!.entryId, 'e-1');
      expect(entry.moodCaption, 'Loaded');
    });

    test('trả null khi doc không tồn tại', () async {
      final entry = await repo.getEntry('missing');
      expect(entry, isNull);
    });

    test('throws ValidationError khi entryId rỗng', () async {
      await expectLater(
        repo.getEntry(''),
        throwsA(
          isA<ValidationError>()
              .having((e) => e.code, 'code', 'diary/entry-id-required'),
        ),
      );
    });
  });

  group('getPublicEntries — Profile cross-module', () {
    test('chỉ trả entries privacy == public của authorUid', () async {
      await seedEntry(
        'e-pub-1',
        authorUid: ownerUid,
        privacy: DiaryPrivacy.public,
        createdAt: DateTime.utc(2026, 5, 22),
      );
      await seedEntry(
        'e-pub-2',
        authorUid: ownerUid,
        privacy: DiaryPrivacy.public,
        createdAt: DateTime.utc(2026, 5, 20),
      );
      await seedEntry(
        'e-priv',
        authorUid: ownerUid,
        privacy: DiaryPrivacy.private,
      );
      await seedEntry(
        'e-other-pub',
        authorUid: otherUid,
        privacy: DiaryPrivacy.public,
      );

      final result = await repo.getPublicEntries(ownerUid);

      expect(result.map((e) => e.entryId).toList(), ['e-pub-1', 'e-pub-2']);
    });

    test('trả list rỗng khi user không có public entry', () async {
      await seedEntry('e-priv', authorUid: ownerUid);

      final result = await repo.getPublicEntries(ownerUid);
      expect(result, isEmpty);
    });
  });

  group('searchEntries — client-side filter', () {
    setUp(() async {
      await seedEntry(
        'e-1',
        authorUid: ownerUid,
        moodCaption: 'Đà Lạt sương mù',
        content: const [
          DiaryContentBlock.text(value: 'Đi cafe Tùng buổi sáng'),
        ],
        createdAt: DateTime.utc(2026, 5, 22),
      );
      await seedEntry(
        'e-2',
        authorUid: ownerUid,
        moodCaption: 'Mưa Sài Gòn',
        content: const [DiaryContentBlock.text(value: 'Nhớ Đà Lạt quá')],
        createdAt: DateTime.utc(2026, 5, 21),
      );
      await seedEntry(
        'e-3',
        authorUid: ownerUid,
        moodCaption: 'Bình thường',
        content: const [DiaryContentBlock.text(value: 'Nothing special')],
      );
      await seedEntry(
        'e-other',
        authorUid: otherUid,
        moodCaption: 'Đà Lạt',
      );
    });

    test('match qua moodCaption', () async {
      final result = await repo.searchEntries(
        authorUid: ownerUid,
        query: 'sài gòn',
      );

      expect(result.map((e) => e.entryId).toList(), ['e-2']);
    });

    test('match qua text content block', () async {
      final result = await repo.searchEntries(
        authorUid: ownerUid,
        query: 'cafe tùng',
      );

      expect(result.map((e) => e.entryId).toList(), ['e-1']);
    });

    test('case-insensitive', () async {
      final result = await repo.searchEntries(
        authorUid: ownerUid,
        query: 'NHỚ',
      );

      expect(result.map((e) => e.entryId).toList(), ['e-2']);
    });

    test('không match cross-user entries', () async {
      final result = await repo.searchEntries(
        authorUid: ownerUid,
        query: 'Đà Lạt',
      );

      final ids = result.map((e) => e.entryId).toList();
      expect(ids, containsAll(['e-1', 'e-2']));
      expect(ids, isNot(contains('e-other')));
    });

    test('trả list rỗng khi query không match', () async {
      final result = await repo.searchEntries(
        authorUid: ownerUid,
        query: 'không có gì',
      );
      expect(result, isEmpty);
    });

    test('trả list rỗng khi query toàn whitespace', () async {
      final result = await repo.searchEntries(
        authorUid: ownerUid,
        query: '   ',
      );
      expect(result, isEmpty);
    });
  });

  group('updateEntry', () {
    test('cập nhật field cho phép + set updatedAt', () async {
      await seedEntry('e-1', authorUid: ownerUid, moodCaption: 'Old');
      final updated = buildEntry(
        entryId: 'e-1',
        moodCaption: 'New',
        content: const [DiaryContentBlock.text(value: 'New body')],
      );

      await repo.updateEntry(updated);

      final data = (await firestore.doc('diary/e-1').get()).data()!;
      expect(data['moodCaption'], 'New');
      expect(data['updatedAt'], isA<Timestamp>());
    });

    test('throws khi entryId rỗng', () async {
      final draft = buildEntry(entryId: '');

      await expectLater(
        repo.updateEntry(draft),
        throwsA(
          isA<ValidationError>()
              .having((e) => e.code, 'code', 'diary/entry-id-required'),
        ),
      );
    });

    test('không cho đổi authorUid', () async {
      await seedEntry('e-1', authorUid: ownerUid);
      final hijack = buildEntry(entryId: 'e-1', authorUid: otherUid);

      await expectLater(
        repo.updateEntry(hijack),
        throwsA(
          isA<ValidationError>()
              .having((e) => e.code, 'code', 'diary/author-immutable'),
        ),
      );

      final data = (await firestore.doc('diary/e-1').get()).data()!;
      expect(data['authorUid'], ownerUid);
    });

    test('throws NotFoundError khi entry không tồn tại', () async {
      final draft = buildEntry(entryId: 'missing');

      await expectLater(
        repo.updateEntry(draft),
        throwsA(isA<NotFoundError>()),
      );
    });

    test('throws ValidationError khi moodCaption > 50', () async {
      await seedEntry('e-1', authorUid: ownerUid);
      final draft = buildEntry(entryId: 'e-1', moodCaption: 'x' * 51);

      await expectLater(
        repo.updateEntry(draft),
        throwsA(isA<ValidationError>()),
      );
    });
  });

  group('updatePrivacy', () {
    test('chỉ update field privacy + updatedAt, không đụng content', () async {
      await seedEntry(
        'e-1',
        authorUid: ownerUid,
        moodCaption: 'Keep',
        privacy: DiaryPrivacy.private,
      );

      await repo.updatePrivacy(
        entryId: 'e-1',
        privacy: DiaryPrivacy.public,
      );

      final data = (await firestore.doc('diary/e-1').get()).data()!;
      expect(data['privacy'], 'public');
      expect(data['moodCaption'], 'Keep');
      expect(data['updatedAt'], isA<Timestamp>());
    });

    test('throws ValidationError khi entryId rỗng', () async {
      await expectLater(
        repo.updatePrivacy(entryId: '', privacy: DiaryPrivacy.public),
        throwsA(
          isA<ValidationError>()
              .having((e) => e.code, 'code', 'diary/entry-id-required'),
        ),
      );
    });
  });

  group('deleteEntry', () {
    test('xoá Firestore doc', () async {
      await seedEntry('e-1', authorUid: ownerUid);

      await repo.deleteEntry('e-1');

      final snap = await firestore.doc('diary/e-1').get();
      expect(snap.exists, false);
    });

    test('gọi storage clear cho diary/{uid}/{entryId}', () async {
      await seedEntry('e-1', authorUid: ownerUid);

      await repo.deleteEntry('e-1');

      expect(storage.lastDeletedPrefix, 'diary/$ownerUid/e-1');
    });

    test('throws NotFoundError khi entry không tồn tại', () async {
      await expectLater(
        repo.deleteEntry('missing'),
        throwsA(isA<NotFoundError>()),
      );
      expect(storage.lastDeletedPrefix, isNull);
    });

    test('throws ValidationError khi entryId rỗng', () async {
      await expectLater(
        repo.deleteEntry(''),
        throwsA(isA<ValidationError>()),
      );
    });
  });
}

class _StubDiaryStorageClient implements DiaryStorageClient {
  String? lastDeletedPrefix;
  Exception? exceptionToThrow;

  @override
  Future<String> upload({
    required String uid,
    required String entryId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return 'https://stub/diary/$uid/$entryId/$fileName';
  }

  @override
  Future<void> deletePrefix(String prefix) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    lastDeletedPrefix = prefix;
  }
}
