import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/diary/application/diary_controller.dart';
import 'package:meep/features/diary/data/diary_content_block.dart';
import 'package:meep/features/diary/data/diary_entry.dart';
import 'package:meep/features/diary/data/diary_repository.dart';
import 'package:meep/features/diary/data/firebase_diary_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockDiaryRepository extends Mock implements DiaryRepository {}

class _FakeDiaryEntry extends Fake implements DiaryEntry {}

class _StubStorageClient implements DiaryStorageClient {
  /// Predefined URLs trả về theo thứ tự upload. `null` slot → throw.
  List<String?> urls = const [];
  int uploadCount = 0;
  final uploads = <Map<String, dynamic>>[];
  String? lastDeletedPrefix;

  @override
  Future<String> upload({
    required String uid,
    required String entryId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final idx = uploadCount;
    uploadCount++;
    uploads.add({
      'uid': uid,
      'entryId': entryId,
      'fileName': fileName,
      'bytes': bytes.length,
    });
    if (idx >= urls.length || urls[idx] == null) {
      throw FirebaseException(
        plugin: 'storage',
        code: 'unavailable',
      );
    }
    return urls[idx]!;
  }

  @override
  Future<void> deletePrefix(String prefix) async {
    lastDeletedPrefix = prefix;
  }
}

void main() {
  const uid = 'uid-owner';

  late _MockDiaryRepository repo;
  late _StubStorageClient storage;

  DiaryEntry draftEntry({
    String entryId = '',
    String moodCaption = 'Hôm nay',
    List<DiaryContentBlock> content = const [
      DiaryContentBlock.text(value: 'Body'),
    ],
    DiaryPrivacy privacy = DiaryPrivacy.private,
  }) {
    return DiaryEntry(
      entryId: entryId,
      authorUid: uid,
      moodTemplate: MoodTemplate.happy,
      coverImageUrl: '', // placeholder, controller sẽ replace
      moodCaption: moodCaption,
      content: content,
      privacy: privacy,
      createdAt: DateTime.utc(2026, 5, 22),
      updatedAt: DateTime.utc(2026, 5, 22),
    );
  }

  DiaryEntry savedEntry(String id) => draftEntry().copyWith(
        entryId: id,
        coverImageUrl: 'https://cdn/cover',
      );

  setUpAll(() {
    registerFallbackValue(_FakeDiaryEntry());
  });

  setUp(() {
    repo = _MockDiaryRepository();
    storage = _StubStorageClient();
    // Default reserve ID — tests có thể override khi cần verify cụ thể.
    when(() => repo.reserveEntryId()).thenReturn('reserved-id');
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [
        diaryRepositoryProvider.overrideWithValue(repo),
        diaryStorageClientProvider.overrideWithValue(storage),
      ],
    );
    // Giữ provider alive xuyên suốt test — autoDispose tear-down giữa các
    // c.read() làm mất state (giống profile_controller_test pattern).
    final sub = c.listen(diaryControllerProvider, (_, __) {});
    addTearDown(sub.close);
    addTearDown(c.dispose);
    return c;
  }

  group('build — initial state', () {
    test('default state: empty entries, isLoading=false, mode=create', () {
      final c = makeContainer();
      final state = c.read(diaryControllerProvider);

      expect(state.entries, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isSaving, isFalse);
      expect(state.currentEntry, isNull);
      expect(state.mode, DiaryCanvasMode.create);
      expect(state.searchResults, isEmpty);
      expect(state.errorMessage, isNull);
    });
  });

  group('loadEntries', () {
    test('subscribe stream + emit entries vào state', () async {
      final ctrl = StreamController<List<DiaryEntry>>();
      when(() => repo.watchEntries(uid)).thenAnswer((_) => ctrl.stream);

      final c = makeContainer();
      c.read(diaryControllerProvider.notifier).loadEntries(uid);

      // isLoading=true ngay lập tức
      expect(c.read(diaryControllerProvider).isLoading, isTrue);

      ctrl.add([savedEntry('e-1'), savedEntry('e-2')]);
      await Future<void>.delayed(Duration.zero);

      final state = c.read(diaryControllerProvider);
      expect(state.entries.map((e) => e.entryId), ['e-1', 'e-2']);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      await ctrl.close();
    });

    test('stream error → errorMessage set, isLoading=false', () async {
      when(() => repo.watchEntries(uid)).thenAnswer(
        (_) => Stream.error(const NetworkError(message: 'mất mạng')),
      );

      final c = makeContainer();
      c.read(diaryControllerProvider.notifier).loadEntries(uid);
      await Future<void>.delayed(Duration.zero);

      final state = c.read(diaryControllerProvider);
      expect(state.errorMessage, 'mất mạng');
      expect(state.isLoading, isFalse);
    });
  });

  group('saveEntry — create mode', () {
    test('upload cover → upload inline → createEntry (đúng sequence)',
        () async {
      storage.urls = ['https://cdn/cover.jpg', 'https://cdn/img1.jpg'];
      when(() => repo.createEntry(any()))
          .thenAnswer((_) async => savedEntry('e-new'));

      final c = makeContainer();
      await c.read(diaryControllerProvider.notifier).saveEntry(
        draft: draftEntry(
          content: const [
            DiaryContentBlock.text(value: 'Mở đầu'),
            DiaryContentBlock.image(imageUrl: 'placeholder:0'),
          ],
        ),
        coverBytes: Uint8List.fromList(List.filled(100, 0xAB)),
        inlineImageBytes: [Uint8List.fromList(List.filled(50, 0xCD))],
      );

      expect(storage.uploadCount, 2);
      expect(storage.uploads[0]['fileName'], 'cover.jpg');
      expect(storage.uploads[0]['entryId'], 'reserved-id');
      expect(storage.uploads[1]['fileName'], 'img_1.jpg');
      expect(storage.uploads[1]['entryId'], 'reserved-id');
      verify(() => repo.createEntry(any())).called(1);

      final state = c.read(diaryControllerProvider);
      expect(state.isSaving, isFalse);
      expect(state.currentEntry?.entryId, 'e-new');
    });

    test('coverBytes null → skip cover upload, chỉ upload inline', () async {
      storage.urls = ['https://cdn/img1.jpg'];
      when(() => repo.createEntry(any()))
          .thenAnswer((_) async => savedEntry('e-new'));

      final c = makeContainer();
      await c.read(diaryControllerProvider.notifier).saveEntry(
        draft: draftEntry(
          content: const [DiaryContentBlock.image(imageUrl: 'placeholder:0')],
        ),
        coverBytes: null,
        inlineImageBytes: [Uint8List.fromList(List.filled(50, 0xCD))],
      );

      expect(storage.uploadCount, 1);
      expect(
        storage.uploads[0]['fileName'],
        'img_1.jpg',
        reason: 'cover upload bị skip, chỉ upload inline',
      );
      verify(() => repo.createEntry(any())).called(1);
      final state = c.read(diaryControllerProvider);
      expect(state.currentEntry?.entryId, 'e-new');
    });

    test('cover upload fail → KHÔNG gọi inline upload, KHÔNG tạo Firestore doc',
        () async {
      storage.urls = const [null]; // cover fail
      when(() => repo.createEntry(any()))
          .thenAnswer((_) async => savedEntry('e-new'));

      final c = makeContainer();
      await c.read(diaryControllerProvider.notifier).saveEntry(
        draft: draftEntry(),
        coverBytes: Uint8List(100),
        inlineImageBytes: [Uint8List(50)],
      );

      expect(storage.uploadCount, 1, reason: 'fail ở cover, không gọi inline');
      verifyNever(() => repo.createEntry(any()));
      final state = c.read(diaryControllerProvider);
      expect(state.errorMessage, contains('Tải ảnh bìa thất bại'));
      expect(state.isSaving, isFalse);
    });

    test('inline upload fail giữa chừng → KHÔNG tạo Firestore doc', () async {
      storage.urls = ['https://cdn/cover.jpg', null]; // cover OK, inline fail

      final c = makeContainer();
      await c.read(diaryControllerProvider.notifier).saveEntry(
        draft: draftEntry(),
        coverBytes: Uint8List(100),
        inlineImageBytes: [Uint8List(50)],
      );

      expect(storage.uploadCount, 2);
      verifyNever(() => repo.createEntry(any()));
      final state = c.read(diaryControllerProvider);
      expect(state.errorMessage, contains('thất bại'));
    });

    test('Firestore createEntry fail → state.errorMessage set', () async {
      storage.urls = ['https://cdn/cover.jpg'];
      when(() => repo.createEntry(any())).thenThrow(
        const NetworkError(message: 'Firestore down'),
      );

      final c = makeContainer();
      await c.read(diaryControllerProvider.notifier).saveEntry(
            draft: draftEntry(),
            coverBytes: Uint8List(100),
          );

      final state = c.read(diaryControllerProvider);
      expect(state.errorMessage, 'Firestore down');
      expect(state.isSaving, isFalse);
    });
  });

  group('saveEntry — preserve existing image URLs (edit)', () {
    test(
      'image block với URL Firestore cũ KHÔNG bị ghi đè bởi inlineUrls',
      () async {
        storage.urls = ['https://cdn/new_img.jpg'];
        when(() => repo.updateEntry(any())).thenAnswer((_) async {});

        final c = makeContainer();
        c.read(diaryControllerProvider.notifier).setMode(DiaryCanvasMode.edit);

        // Draft: 1 text + 1 image cũ (URL) + 1 placeholder (ảnh mới pick).
        await c.read(diaryControllerProvider.notifier).saveEntry(
          draft: draftEntry(
            entryId: 'e-existing',
            content: const [
              DiaryContentBlock.text(value: 'Nội dung'),
              DiaryContentBlock.image(imageUrl: 'https://cdn/old_img.jpg'),
              DiaryContentBlock.image(imageUrl: 'placeholder:0'),
            ],
          ),
          inlineImageBytes: [Uint8List(50)],
        );

        // Verify chỉ 1 upload (cho placeholder), không upload cho URL cũ.
        expect(storage.uploadCount, 1);

        // Verify updateEntry nhận đúng content: URL cũ giữ + placeholder
        // thay bằng URL mới.
        final captured = verify(() => repo.updateEntry(captureAny()))
            .captured
            .single as DiaryEntry;
        expect(captured.content.length, 3);
        expect(
          captured.content[1].maybeWhen(
            image: (url) => url,
            orElse: () => '',
          ),
          'https://cdn/old_img.jpg',
          reason: 'URL cũ giữ nguyên',
        );
        expect(
          captured.content[2].maybeWhen(
            image: (url) => url,
            orElse: () => '',
          ),
          'https://cdn/new_img.jpg',
          reason: 'placeholder được thay bằng URL mới upload',
        );
      },
    );
  });

  group('saveEntry — edit mode', () {
    test('mode=edit → gọi updateEntry, KHÔNG gọi createEntry', () async {
      storage.urls = ['https://cdn/cover.jpg'];
      when(() => repo.updateEntry(any())).thenAnswer((_) async {});

      final c = makeContainer();
      c.read(diaryControllerProvider.notifier).setMode(DiaryCanvasMode.edit);

      await c.read(diaryControllerProvider.notifier).saveEntry(
            draft: draftEntry(entryId: 'e-existing'),
            coverBytes: Uint8List(100),
          );

      verify(() => repo.updateEntry(any())).called(1);
      verifyNever(() => repo.createEntry(any()));
    });
  });

  group('updatePrivacy', () {
    test('gọi repo.updatePrivacy + cập nhật currentEntry nếu match entryId',
        () async {
      when(
        () => repo.updatePrivacy(
          entryId: 'e-1',
          privacy: DiaryPrivacy.public,
        ),
      ).thenAnswer((_) async {});

      final c = makeContainer();
      c
          .read(diaryControllerProvider.notifier)
          .setCurrentEntry(savedEntry('e-1'));

      await c.read(diaryControllerProvider.notifier).updatePrivacy(
            entryId: 'e-1',
            privacy: DiaryPrivacy.public,
          );

      verify(
        () => repo.updatePrivacy(
          entryId: 'e-1',
          privacy: DiaryPrivacy.public,
        ),
      ).called(1);
      final state = c.read(diaryControllerProvider);
      expect(state.currentEntry?.privacy, DiaryPrivacy.public);
      expect(state.isSaving, isFalse);
    });

    test('KHÔNG đổi currentEntry nếu entryId khác', () async {
      when(
        () => repo.updatePrivacy(
          entryId: 'e-2',
          privacy: DiaryPrivacy.public,
        ),
      ).thenAnswer((_) async {});

      final c = makeContainer();
      c
          .read(diaryControllerProvider.notifier)
          .setCurrentEntry(savedEntry('e-1'));

      await c.read(diaryControllerProvider.notifier).updatePrivacy(
            entryId: 'e-2',
            privacy: DiaryPrivacy.public,
          );

      final state = c.read(diaryControllerProvider);
      // currentEntry e-1 không bị đụng (vẫn private)
      expect(state.currentEntry?.entryId, 'e-1');
      expect(state.currentEntry?.privacy, DiaryPrivacy.private);
    });

    test('repo fail → errorMessage set', () async {
      when(
        () => repo.updatePrivacy(
          entryId: 'e-1',
          privacy: DiaryPrivacy.public,
        ),
      ).thenThrow(const NetworkError(message: 'mất mạng'));

      final c = makeContainer();
      await c.read(diaryControllerProvider.notifier).updatePrivacy(
            entryId: 'e-1',
            privacy: DiaryPrivacy.public,
          );

      final state = c.read(diaryControllerProvider);
      expect(state.errorMessage, 'mất mạng');
    });
  });

  group('searchEntries', () {
    test('delegate sang repo + lưu kết quả vào state.searchResults', () async {
      when(
        () => repo.searchEntries(
          authorUid: uid,
          query: 'đà lạt',
        ),
      ).thenAnswer((_) async => [savedEntry('e-1')]);

      final c = makeContainer();
      await c.read(diaryControllerProvider.notifier).searchEntries(
            authorUid: uid,
            query: 'đà lạt',
          );

      final state = c.read(diaryControllerProvider);
      expect(state.searchResults.map((e) => e.entryId), ['e-1']);
      expect(state.isLoading, isFalse);
    });

    test(
      'repo fail → errorMessage set, searchResults giữ giá trị cũ',
      () async {
        when(
          () => repo.searchEntries(
            authorUid: uid,
            query: any(named: 'query'),
          ),
        ).thenThrow(const NetworkError(message: 'mất mạng'));

        final c = makeContainer();
        await c.read(diaryControllerProvider.notifier).searchEntries(
              authorUid: uid,
              query: 'x',
            );

        final state = c.read(diaryControllerProvider);
        expect(state.errorMessage, 'mất mạng');
      },
    );
  });

  group('updateEntryNoImage', () {
    test('gọi repo.updateEntry + set currentEntry, không upload', () async {
      when(() => repo.updateEntry(any())).thenAnswer((_) async {});

      final c = makeContainer();
      final updated = savedEntry('e-1').copyWith(moodCaption: 'New title');

      await c
          .read(diaryControllerProvider.notifier)
          .updateEntryNoImage(updated);

      verify(() => repo.updateEntry(updated)).called(1);
      expect(storage.uploadCount, 0);
      final state = c.read(diaryControllerProvider);
      expect(state.currentEntry?.moodCaption, 'New title');
      expect(state.isSaving, isFalse);
    });

    test('repo fail → errorMessage set', () async {
      when(() => repo.updateEntry(any()))
          .thenThrow(const NetworkError(message: 'mất mạng'));

      final c = makeContainer();

      await c
          .read(diaryControllerProvider.notifier)
          .updateEntryNoImage(savedEntry('e-1'));

      final state = c.read(diaryControllerProvider);
      expect(state.errorMessage, 'mất mạng');
    });
  });

  group('loadEntry', () {
    test('fetch entry + set currentEntry', () async {
      when(() => repo.getEntry('e-1'))
          .thenAnswer((_) async => savedEntry('e-1'));

      final c = makeContainer();
      await c.read(diaryControllerProvider.notifier).loadEntry('e-1');

      verify(() => repo.getEntry('e-1')).called(1);
      final state = c.read(diaryControllerProvider);
      expect(state.currentEntry?.entryId, 'e-1');
      expect(state.isLoading, isFalse);
    });

    test('entry null (not found) → currentEntry null, error set', () async {
      when(() => repo.getEntry('missing')).thenAnswer((_) async => null);

      final c = makeContainer();
      await c.read(diaryControllerProvider.notifier).loadEntry('missing');

      final state = c.read(diaryControllerProvider);
      expect(state.currentEntry, isNull);
      expect(state.errorMessage, 'Không tìm thấy nhật ký');
      expect(state.isLoading, isFalse);
    });

    test('repo fail → errorMessage set', () async {
      when(() => repo.getEntry('e-1'))
          .thenThrow(const NetworkError(message: 'mất mạng'));

      final c = makeContainer();
      await c.read(diaryControllerProvider.notifier).loadEntry('e-1');

      final state = c.read(diaryControllerProvider);
      expect(state.errorMessage, 'mất mạng');
      expect(state.currentEntry, isNull);
    });
  });

  group('deleteEntry', () {
    test('gọi repo.deleteEntry + clear currentEntry', () async {
      when(() => repo.deleteEntry('e-1')).thenAnswer((_) async {});

      final c = makeContainer();
      c
          .read(diaryControllerProvider.notifier)
          .setCurrentEntry(savedEntry('e-1'));

      await c.read(diaryControllerProvider.notifier).deleteEntry('e-1');

      verify(() => repo.deleteEntry('e-1')).called(1);
      final state = c.read(diaryControllerProvider);
      expect(state.currentEntry, isNull);
      expect(state.isSaving, isFalse);
    });

    test('repo fail → errorMessage set, currentEntry giữ nguyên', () async {
      when(() => repo.deleteEntry('e-1'))
          .thenThrow(const NetworkError(message: 'mất mạng'));

      final c = makeContainer();
      c
          .read(diaryControllerProvider.notifier)
          .setCurrentEntry(savedEntry('e-1'));

      await c.read(diaryControllerProvider.notifier).deleteEntry('e-1');

      final state = c.read(diaryControllerProvider);
      expect(state.errorMessage, 'mất mạng');
      expect(state.currentEntry?.entryId, 'e-1');
    });
  });

  group('clearError + setMode + setCurrentEntry', () {
    test('clearError reset errorMessage về null', () async {
      when(() => repo.deleteEntry(any()))
          .thenThrow(const NetworkError(message: 'X'));

      final c = makeContainer();
      await c.read(diaryControllerProvider.notifier).deleteEntry('e-1');
      expect(c.read(diaryControllerProvider).errorMessage, isNotNull);

      c.read(diaryControllerProvider.notifier).clearError();
      expect(c.read(diaryControllerProvider).errorMessage, isNull);
    });

    test('setMode update state.mode', () {
      final c = makeContainer();
      c.read(diaryControllerProvider.notifier).setMode(DiaryCanvasMode.read);
      expect(c.read(diaryControllerProvider).mode, DiaryCanvasMode.read);
    });
  });
}
