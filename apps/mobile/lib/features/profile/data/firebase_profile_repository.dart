import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/profile/data/profile_repository.dart';

/// Firebase-backed implementation of [ProfileRepository].
///
/// Storage upload tách qua [AvatarStorageClient] để test inject stub (mocktail
/// hard-to-use với `UploadTask extends Future`). Compress tách qua
/// [AvatarCompressor] để control output bytes trong test.
///
/// Storage và Firestore là 2 boundary tách biệt — nếu Storage OK nhưng
/// Firestore update fail, file orphan ở `avatars/{uid}/avatar.jpg` (chấp nhận:
/// lần upload tới overwrite cùng path).
class FirebaseProfileRepository implements ProfileRepository {
  FirebaseProfileRepository({
    required FirebaseFirestore firestore,
    required AvatarStorageClient storageClient,
    AvatarCompressor? compressor,
  })  : _firestore = firestore,
        _storageClient = storageClient,
        _compressor = compressor ?? const _FlutterAvatarCompressor();

  /// Convenience factory: wire FirebaseStorage instance trực tiếp.
  /// main.dart dùng factory này; tests dùng constructor với stub.
  factory FirebaseProfileRepository.firebase({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    AvatarCompressor? compressor,
  }) {
    return FirebaseProfileRepository(
      firestore: firestore,
      storageClient: _FirebaseAvatarStorageClient(storage),
      compressor: compressor,
    );
  }

  final FirebaseFirestore _firestore;
  final AvatarStorageClient _storageClient;
  final AvatarCompressor _compressor;

  /// Whitelist khớp với Firestore rule `/users/{uid}` update (firestore.rules):
  /// uid/email/createdAt + 3 counter (postCount/friendCount/spaceCount) +
  /// username là server-only → KHÔNG nằm trong list.
  ///
  /// username change đi qua Firestore transaction riêng (`/usernames/{username}`
  /// uniqueness doc + batch update `/users/{uid}.username`) — sẽ wire ở T5
  /// (#110) qua UserRepository, KHÔNG qua updateProfile path này.
  static const Set<String> _allowedFields = {
    'displayName',
    'avatarUrl',
    'bio',
    'dateOfBirth',
    'phoneNumber',
    'gender',
  };

  /// Hard ceiling theo issue #109 acceptance criteria.
  /// Note: storage.rules hiện ship 2MB (firebase/storage.rules:23); T9 (#114)
  /// sẽ sync rule lên 5MB cùng rules tests.
  static const int _maxAvatarBytes = 5 * 1024 * 1024;

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final snap = await _firestore.doc('users/$uid').get();
      if (!snap.exists) return null;
      return UserProfile.fromJson(snap.data()!);
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e);
    }
  }

  @override
  Stream<UserProfile?> watchUserProfile(String uid) {
    return _firestore.doc('users/$uid').snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserProfile.fromJson(snap.data()!);
    });
  }

  @override
  Future<void> updateProfile(String uid, Map<String, dynamic> fields) async {
    if (fields.isEmpty) {
      throw const ValidationError(
        message: 'Không có thay đổi nào để cập nhật',
        code: 'profile/empty-update',
      );
    }
    final invalid =
        fields.keys.where((k) => !_allowedFields.contains(k)).toList();
    if (invalid.isNotEmpty) {
      throw ValidationError(
        message: 'Không được phép cập nhật: ${invalid.join(', ')}',
        code: 'profile/field-not-allowed',
      );
    }
    try {
      await _firestore.doc('users/$uid').update({
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e);
    }
  }

  @override
  Future<void> updateAvatar(String uid, File imageFile) async {
    final compressed = await _compressor.compress(imageFile);
    if (compressed.lengthInBytes > _maxAvatarBytes) {
      throw const ValidationError(
        message: 'Ảnh quá lớn (giới hạn 5MB)',
        code: 'profile/avatar-too-large',
      );
    }

    final String url;
    try {
      url = await _storageClient.upload(uid: uid, bytes: compressed);
    } on FirebaseException catch (e) {
      throw _mapStorageError(e);
    }

    try {
      await _firestore.doc('users/$uid').update({
        'avatarUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e);
    }
  }

  @override
  Future<void> removeAvatar(String uid) async {
    try {
      await _firestore.doc('users/$uid').update({
        'avatarUrl': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e);
    }
  }

  AppError _mapFirestoreError(FirebaseException e) => switch (e.code) {
        'permission-denied' => ForbiddenError('truy cập hồ sơ'),
        'not-found' => NotFoundError('Hồ sơ'),
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
          ForbiddenError('tải lên ảnh đại diện'),
        'object-not-found' => NotFoundError('Ảnh đại diện'),
        'quota-exceeded' => const UnexpectedError(
            message: 'Bộ nhớ đã đầy, vui lòng thử lại sau',
            code: 'quota-exceeded',
          ),
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

/// Uploads avatar bytes và trả về download URL. Tách interface để unit-test
/// inject stub deterministic — mocktail không tự stub Future-implementing
/// classes như `UploadTask`.
abstract class AvatarStorageClient {
  /// Upload `bytes` lên `avatars/{uid}/avatar.jpg` (overwrite) và trả URL.
  /// Throws [FirebaseException] khi Storage lỗi — repository map sang AppError.
  Future<String> upload({required String uid, required Uint8List bytes});
}

class _FirebaseAvatarStorageClient implements AvatarStorageClient {
  _FirebaseAvatarStorageClient(this._storage);

  final FirebaseStorage _storage;

  @override
  Future<String> upload({
    required String uid,
    required Uint8List bytes,
  }) async {
    final ref = _storage.ref('avatars/$uid/avatar.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}

/// Pluggable image compressor — extracted để test inject stub deterministic.
/// `flutter_image_compress` cần platform plugin; tests dùng compressor giả.
abstract class AvatarCompressor {
  Future<Uint8List> compress(File file);
}

class _FlutterAvatarCompressor implements AvatarCompressor {
  const _FlutterAvatarCompressor();

  @override
  Future<Uint8List> compress(File file) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: 512,
      minHeight: 512,
      quality: 85,
      format: CompressFormat.jpeg,
    );
    if (result == null) {
      // Fallback: plugin trả null khi format/platform không hỗ trợ.
      // Caller vẫn enforce size cap trên raw bytes.
      return file.readAsBytes();
    }
    return result;
  }
}
