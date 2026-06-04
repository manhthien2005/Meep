import 'dart:async';
import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/diary/data/diary_content_block.dart';
import 'package:meep/features/diary/data/diary_entry.dart';
import 'package:meep/features/diary/data/diary_repository.dart';
import 'package:meep/features/diary/data/firebase_diary_repository.dart';
import 'package:meep/features/diary/data/image_picker_service.dart';

part 'diary_controller.freezed.dart';
part 'diary_controller.g.dart';

/// Mode of the diary canvas — mirrors presentation-layer enum cùng tên.
/// Định nghĩa ở application layer để [DiaryState] dùng trực tiếp,
/// presentation import từ đây (không reverse-dependency).
enum DiaryCanvasMode { create, read, edit }

@freezed
class DiaryState with _$DiaryState {
  const factory DiaryState({
    @Default([]) List<DiaryEntry> entries,
    DiaryEntry? currentEntry,
    @Default(false) bool isLoading,
    @Default(false) bool isSaving,
    String? errorMessage,
    @Default(DiaryCanvasMode.create) DiaryCanvasMode mode,
    @Default([]) List<DiaryEntry> searchResults,
  }) = _DiaryState;
}

@Riverpod(keepAlive: true)
DiaryRepository diaryRepository(DiaryRepositoryRef ref) =>
    throw UnimplementedError(
      'diaryRepositoryProvider must be overridden — '
      'wire FirebaseDiaryRepository in main.dart (TODO: D/T1/HanDHG)',
    );

@Riverpod(keepAlive: true)
DiaryStorageClient diaryStorageClient(DiaryStorageClientRef ref) =>
    throw UnimplementedError(
      'diaryStorageClientProvider must be overridden — '
      'wire FirebaseDiaryStorageClient in main.dart',
    );

@Riverpod(keepAlive: true)
ImagePickerService imagePickerService(ImagePickerServiceRef ref) =>
    throw UnimplementedError(
      'imagePickerServiceProvider must be overridden — '
      'wire FlutterImagePickerService in main.dart',
    );

@riverpod
class DiaryController extends _$DiaryController {
  StreamSubscription<List<DiaryEntry>>? _entriesSub;

  @override
  DiaryState build() {
    // Single dispose registration — tránh queue grow khi loadEntries gọi
    // nhiều lần (vd pull-to-refresh).
    ref.onDispose(() => _entriesSub?.cancel());
    return const DiaryState();
  }

  /// Subscribe `watchEntries(uid)` từ [DiaryRepository]. Stream emit tự động
  /// đẩy danh sách entries mới vào [state.entries]. Lỗi → errorMessage.
  void loadEntries(String authorUid) {
    unawaited(_entriesSub?.cancel());
    state = state.copyWith(isLoading: true, errorMessage: null);
    _entriesSub =
        ref.read(diaryRepositoryProvider).watchEntries(authorUid).listen(
              (entries) => state = state.copyWith(
                entries: entries,
                isLoading: false,
                errorMessage: null,
              ),
              onError: (Object e) => state = _afterFailure(e),
            );
  }

  /// Save entry — tạo mới hoặc cập nhật tuỳ [state.mode].
  ///
  /// Upload sequence (spec §Lưu nhật ký):
  /// 1. cover image → `diary/{uid}/{entryId}/cover.jpg` → coverUrl
  /// 2. inline images tuần tự → `diary/{uid}/{entryId}/img_N.jpg` → inlineUrls
  /// 3. TẤT CẢ URLs sẵn sàng → Firestore write với cùng entryId
  ///
  /// Tránh path mismatch: với create mode, controller reserve entryId TRƯỚC
  /// upload nên Storage path khớp Firestore doc.
  ///
  /// Upload fail bất kỳ bước → KHÔNG tạo/update Firestore doc.
  Future<void> saveEntry({
    required DiaryEntry draft,
    Uint8List? coverBytes,
    List<Uint8List> inlineImageBytes = const [],
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final storage = ref.read(diaryStorageClientProvider);
      final repo = ref.read(diaryRepositoryProvider);
      final uid = draft.authorUid;
      final mode = state.mode;

      // Reserve entryId: create mode → repository.reserveEntryId();
      // edit mode → dùng entryId của draft (đã có).
      final entryId = mode == DiaryCanvasMode.create
          ? repo.reserveEntryId()
          : draft.entryId;

      // Bước 1 — upload cover (skip nếu không đổi ảnh cover)
      String coverUrl = draft.coverImageUrl;
      if (coverBytes != null) {
        try {
          coverUrl = await storage.upload(
            uid: uid,
            entryId: entryId,
            fileName: 'cover.jpg',
            bytes: coverBytes,
            contentType: 'image/jpeg',
          );
        } catch (e) {
          state = _afterFailure(e, fallback: 'Tải ảnh bìa thất bại');
          return;
        }
      }

      // Bước 2 — upload inline images tuần tự
      final inlineUrls = <String>[];
      for (var i = 0; i < inlineImageBytes.length; i++) {
        try {
          final url = await storage.upload(
            uid: uid,
            entryId: entryId,
            fileName: 'img_${i + 1}.jpg',
            bytes: inlineImageBytes[i],
            contentType: 'image/jpeg',
          );
          inlineUrls.add(url);
        } catch (e) {
          state = _afterFailure(e, fallback: 'Tải ảnh thứ ${i + 1} thất bại');
          return;
        }
      }

      // Bước 3 — build entry với URLs thật + Firestore write.
      //
      // Inline image URL mapping: chỉ replace ImageBlock có sentinel
      // `placeholder:` (UI mới pick). ImageBlock với URL Firestore cũ giữ
      // nguyên — tránh edit mode ghi đè URL hợp lệ bằng URL mới (mất ảnh).
      var inlineIdx = 0;
      final contentBlocks = draft.content.map((b) {
        return b.when(
          text: (value, style) => DiaryContentBlock.text(
            value: value,
            style: style,
          ),
          image: (existingUrl) {
            if (existingUrl.startsWith('placeholder:')) {
              final url =
                  inlineIdx < inlineUrls.length ? inlineUrls[inlineIdx++] : '';
              return DiaryContentBlock.image(imageUrl: url);
            }
            // URL Firestore cũ — giữ nguyên.
            return DiaryContentBlock.image(imageUrl: existingUrl);
          },
        );
      }).toList();

      final realEntry = draft.copyWith(
        entryId: entryId,
        coverImageUrl: coverUrl,
        content: contentBlocks,
      );

      if (mode == DiaryCanvasMode.create) {
        final created = await repo.createEntry(realEntry);
        state = state.copyWith(
          isSaving: false,
          currentEntry: created,
        );
      } else {
        await repo.updateEntry(realEntry);
        state = state.copyWith(
          isSaving: false,
          currentEntry: realEntry,
        );
      }
    } catch (e) {
      state = _afterFailure(e);
    }
  }

  /// Update chỉ field `privacy` + `updatedAt` — không kéo cả doc.
  Future<void> updatePrivacy({
    required String entryId,
    required DiaryPrivacy privacy,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await ref
          .read(diaryRepositoryProvider)
          .updatePrivacy(entryId: entryId, privacy: privacy);
      // Cập nhật local state nếu currentEntry đang mở
      if (state.currentEntry?.entryId == entryId) {
        state = state.copyWith(
          isSaving: false,
          currentEntry: state.currentEntry?.copyWith(privacy: privacy),
        );
      } else {
        state = state.copyWith(isSaving: false);
      }
    } catch (e) {
      state = _afterFailure(e);
    }
  }

  /// Search entries của [authorUid] — delegate sang repository, lưu kết quả
  /// vào [state.searchResults].
  Future<void> searchEntries({
    required String authorUid,
    required String query,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final results = await ref
          .read(diaryRepositoryProvider)
          .searchEntries(authorUid: authorUid, query: query);
      state = state.copyWith(
        isLoading: false,
        searchResults: results,
      );
    } catch (e) {
      state = _afterFailure(e);
    }
  }

  /// Update entry fields KHÔNG đổi ảnh — dùng bởi `DiaryCanvasScreen` edit
  /// mode khi user chỉ đổi text/caption/privacy. Tránh upload sequence
  /// (caller path saveEntry yêu cầu coverBytes).
  Future<void> updateEntryNoImage(DiaryEntry entry) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await ref.read(diaryRepositoryProvider).updateEntry(entry);
      state = state.copyWith(
        isSaving: false,
        currentEntry: entry,
      );
    } catch (e) {
      state = _afterFailure(e);
    }
  }

  /// Fetch entry theo entryId → set vào [state.currentEntry].
  /// Dùng bởi `DiaryCanvasScreen` read/edit mode khi push qua entryId.
  Future<void> loadEntry(String entryId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final entry = await ref.read(diaryRepositoryProvider).getEntry(entryId);
      if (entry == null) {
        state = state.copyWith(
          isLoading: false,
          currentEntry: null,
          errorMessage: 'Không tìm thấy nhật ký',
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        currentEntry: entry,
      );
    } catch (e) {
      state = _afterFailure(e);
    }
  }

  /// Xoá entry + Storage assets (gọi repository.deleteEntry).
  Future<void> deleteEntry(String entryId) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await ref.read(diaryRepositoryProvider).deleteEntry(entryId);
      state = state.copyWith(
        isSaving: false,
        currentEntry: null,
      );
    } catch (e) {
      state = _afterFailure(e);
    }
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  /// Reset `searchResults` về empty mà không qua repo. Dùng khi user xoá
  /// query trong DiarySearchScreen — tránh Firestore round-trip thừa.
  void clearSearchResults() {
    if (state.searchResults.isNotEmpty) {
      state = state.copyWith(searchResults: const []);
    }
  }

  void setMode(DiaryCanvasMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setCurrentEntry(DiaryEntry? entry) {
    state = state.copyWith(currentEntry: entry);
  }

  DiaryState _afterFailure(
    Object e, {
    String fallback = 'Đã có lỗi xảy ra',
  }) {
    final err = AppError.fromUnknown(e, fallback: fallback);
    return state.copyWith(
      isLoading: false,
      isSaving: false,
      errorMessage: err is OperationCancelledError ? null : err.message,
    );
  }
}
