import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/diary/data/diary_content_block.dart';
import 'package:meep/features/diary/data/diary_entry.dart';
import 'package:meep/features/diary/data/diary_repository.dart';

/// Firebase-backed implementation of [DiaryRepository].
///
/// Storage upload/delete tách qua [DiaryStorageClient] để test inject stub —
/// `firebase_storage` upload trả `UploadTask extends Future`, khó mock.
/// Pattern mirror với `FirebaseProfileRepository` (avatars).
class FirebaseDiaryRepository implements DiaryRepository {
  FirebaseDiaryRepository({
    required FirebaseFirestore firestore,
    required DiaryStorageClient storageClient,
  })  : _firestore = firestore,
        _storageClient = storageClient;

  /// Convenience factory: wire FirebaseStorage trực tiếp. main.dart dùng
  /// factory này; tests dùng constructor với stub.
  factory FirebaseDiaryRepository.firebase({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) {
    return FirebaseDiaryRepository(
      firestore: firestore,
      storageClient: FirebaseDiaryStorageClient(storage),
    );
  }

  final FirebaseFirestore _firestore;
  final DiaryStorageClient _storageClient;

  static const _collection = 'diary';
  static const int _maxBlocks = 20;
  static const int _maxMoodCaptionChars = 50;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(_collection);

  @override
  Future<DiaryEntry> createEntry(DiaryEntry entry) async {
    _validateMoodCaption(entry.moodCaption);
    _validateBlockCount(entry.content);

    // Tôn trọng entryId nếu caller pre-generate (ví dụ Controller reserve ID
    // trước khi upload Storage để path khớp `diary/{uid}/{entryId}/...`).
    // Empty → Firestore auto-gen, mirror behavior cũ.
    final docRef = entry.entryId.isEmpty ? _col.doc() : _col.doc(entry.entryId);
    final entryWithId = entry.copyWith(entryId: docRef.id);
    final data = _serializeEntry(entryWithId)
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();

    try {
      await docRef.set(data);
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e);
    }
    return entryWithId;
  }

  /// Reserve a new Firestore document ID without writing — controller dùng
  /// trước upload Storage để Storage path `diary/{uid}/{entryId}/...` khớp
  /// với Firestore doc ID, tránh path mismatch + collision.
  @override
  String reserveEntryId() => _col.doc().id;

  @override
  Stream<List<DiaryEntry>> watchEntries(String authorUid) {
    return _col
        .where('authorUid', isEqualTo: authorUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map(_parseEntry).whereType<DiaryEntry>().toList(),
        );
  }

  @override
  Future<DiaryEntry?> getEntry(String entryId) async {
    if (entryId.isEmpty) {
      throw const ValidationError(
        message: 'Thiếu mã nhật ký',
        code: 'diary/entry-id-required',
      );
    }
    try {
      final snap = await _col.doc(entryId).get();
      if (!snap.exists) return null;
      return _parseEntry(snap);
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e);
    }
  }

  @override
  Future<List<DiaryEntry>> getPublicEntries(String authorUid) async {
    try {
      final snap = await _col
          .where('authorUid', isEqualTo: authorUid)
          .where('privacy', isEqualTo: 'public')
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map(_parseEntry).whereType<DiaryEntry>().toList();
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e);
    }
  }

  @override
  Future<List<DiaryEntry>> searchEntries({
    required String authorUid,
    required String query,
  }) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];

    try {
      final snap = await _col
          .where('authorUid', isEqualTo: authorUid)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map(_parseEntry).whereType<DiaryEntry>().where((entry) {
        if (entry.moodCaption.toLowerCase().contains(normalized)) return true;
        return entry.content.any(
          (block) => block.maybeWhen(
            text: (value, _) => value.toLowerCase().contains(normalized),
            orElse: () => false,
          ),
        );
      }).toList();
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e);
    }
  }

  @override
  Future<void> updateEntry(DiaryEntry entry) async {
    if (entry.entryId.isEmpty) {
      throw const ValidationError(
        message: 'Thiếu mã nhật ký',
        code: 'diary/entry-id-required',
      );
    }
    _validateMoodCaption(entry.moodCaption);
    _validateBlockCount(entry.content);

    final docRef = _col.doc(entry.entryId);
    final DocumentSnapshot<Map<String, dynamic>> snap;
    try {
      snap = await docRef.get();
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e);
    }
    if (!snap.exists) {
      throw NotFoundError('Nhật ký');
    }
    final existingAuthor = snap.data()?['authorUid'] as String?;
    if (existingAuthor != entry.authorUid) {
      throw const ValidationError(
        message: 'Không được đổi tác giả của nhật ký',
        code: 'diary/author-immutable',
      );
    }

    final data = _serializeEntry(entry)
      ..remove('createdAt')
      ..['updatedAt'] = FieldValue.serverTimestamp();

    try {
      await docRef.update(data);
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e);
    }
  }

  @override
  Future<void> updatePrivacy({
    required String entryId,
    required DiaryPrivacy privacy,
  }) async {
    if (entryId.isEmpty) {
      throw const ValidationError(
        message: 'Thiếu mã nhật ký',
        code: 'diary/entry-id-required',
      );
    }
    try {
      await _col.doc(entryId).update({
        'privacy': privacy.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e);
    }
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    if (entryId.isEmpty) {
      throw const ValidationError(
        message: 'Thiếu mã nhật ký',
        code: 'diary/entry-id-required',
      );
    }

    final docRef = _col.doc(entryId);
    final DocumentSnapshot<Map<String, dynamic>> snap;
    try {
      snap = await docRef.get();
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e);
    }
    if (!snap.exists) {
      throw NotFoundError('Nhật ký');
    }
    final ownerUid = snap.data()?['authorUid'] as String?;

    try {
      await docRef.delete();
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e);
    }

    if (ownerUid != null && ownerUid.isNotEmpty) {
      try {
        await _storageClient.deletePrefix('diary/$ownerUid/$entryId');
      } on FirebaseException catch (e) {
        throw _mapStorageError(e);
      }
    }
  }

  /// Convert entry → Firestore-ready map. Phải tự flatten `content` vì
  /// `json_serializable` generate cho freezed union để raw `_$TextBlockImpl`
  /// (không call `toJson()` từng phần tử), Firestore reject object lạ.
  ///
  /// KHÔNG lưu `entryId` vào doc field — `snap.id` là source of truth, mirror
  /// `FirebasePostRepository` pattern. `_parseEntry` inject `snap.id` lại khi
  /// đọc.
  Map<String, dynamic> _serializeEntry(DiaryEntry entry) {
    return <String, dynamic>{
      'authorUid': entry.authorUid,
      'moodTemplate': entry.moodTemplate.name,
      'coverImageUrl': entry.coverImageUrl,
      'moodCaption': entry.moodCaption,
      'content': entry.content.map((b) => b.toJson()).toList(),
      'privacy': entry.privacy.name,
      'createdAt': const TimestampConverter().toJson(entry.createdAt),
      'updatedAt': const TimestampConverter().toJson(entry.updatedAt),
    };
  }

  void _validateMoodCaption(String caption) {
    if (caption.length > _maxMoodCaptionChars) {
      throw const ValidationError(
        message: 'Tiêu đề nhật ký tối đa 50 ký tự',
        code: 'diary/mood-caption-too-long',
      );
    }
  }

  void _validateBlockCount(List<DiaryContentBlock> content) {
    if (content.length > _maxBlocks) {
      throw const ValidationError(
        message: 'Nhật ký tối đa 20 khối nội dung',
        code: 'diary/too-many-blocks',
      );
    }
  }

  DiaryEntry? _parseEntry(DocumentSnapshot<Map<String, dynamic>> snap) {
    final raw = snap.data();
    if (raw == null) return null;
    final data = Map<String, dynamic>.from(raw);
    data['entryId'] = snap.id;
    return DiaryEntry.fromJson(data);
  }

  AppError _mapFirestoreError(FirebaseException e) => switch (e.code) {
        'permission-denied' => ForbiddenError('truy cập nhật ký'),
        'not-found' => NotFoundError('Nhật ký'),
        'unavailable' ||
        'cancelled' ||
        'deadline-exceeded' =>
          NetworkError(message: 'Không có kết nối mạng', cause: e),
        _ => UnexpectedError(
            message: e.message ?? e.code,
            code: e.code,
            cause: e,
          ),
      };

  AppError _mapStorageError(FirebaseException e) => switch (e.code) {
        'unauthorized' ||
        'permission-denied' =>
          ForbiddenError('xoá ảnh nhật ký'),
        'object-not-found' => NotFoundError('Ảnh nhật ký'),
        'retry-limit-exceeded' ||
        'unavailable' ||
        'canceled' ||
        'cancelled' =>
          NetworkError(message: 'Không có kết nối mạng', cause: e),
        _ => UnexpectedError(
            message: e.message ?? e.code,
            code: e.code,
            cause: e,
          ),
      };
}

/// Storage boundary cho diary assets. Tách interface để test inject stub —
/// `UploadTask` implement `Future` nhưng có chain methods khó mock.
abstract class DiaryStorageClient {
  /// Upload `bytes` lên `diary/{uid}/{entryId}/{fileName}` và trả download URL.
  Future<String> upload({
    required String uid,
    required String entryId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  });

  /// Xoá toàn bộ object dưới `prefix` (vd `diary/{uid}/{entryId}`).
  /// No-op nếu prefix trống. Repository gọi sau khi delete Firestore doc.
  Future<void> deletePrefix(String prefix);
}

class FirebaseDiaryStorageClient implements DiaryStorageClient {
  FirebaseDiaryStorageClient(this._storage);

  final FirebaseStorage _storage;

  @override
  Future<String> upload({
    required String uid,
    required String entryId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final ref = _storage.ref('diary/$uid/$entryId/$fileName');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  @override
  Future<void> deletePrefix(String prefix) async {
    final dir = _storage.ref(prefix);
    final ListResult listing = await dir.listAll();
    await Future.wait([
      for (final item in listing.items) _safeDelete(item),
    ]);
  }

  Future<void> _safeDelete(Reference ref) async {
    try {
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }
}
