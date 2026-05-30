import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:meep/features/feed/data/storage_repository.dart';

class FirebaseStorageRepository implements StorageRepository {
  FirebaseStorageRepository(this._storage);

  final FirebaseStorage _storage;

  static const _maxBytes = 5 * 1024 * 1024; // 5 MB

  @override
  Future<String> uploadImage({
    required String uid,
    required String postId,
    required List<int> bytes,
    required String mimeType,
    String fileName = 'photo.jpg',
  }) async {
    if (bytes.length > _maxBytes) {
      throw ArgumentError(
        'Image exceeds 5 MB limit (${bytes.length} bytes)',
      );
    }

    final ref = _storage.ref('posts/$uid/$postId/$fileName');
    final metadata = SettableMetadata(contentType: mimeType);
    await ref.putData(Uint8List.fromList(bytes), metadata);
    return ref.getDownloadURL();
  }

  @override
  Future<void> deleteImage(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
    } on FirebaseException catch (e) {
      // object-not-found is acceptable (CF may have deleted first)
      if (e.code != 'object-not-found') rethrow;
    }
  }
}
