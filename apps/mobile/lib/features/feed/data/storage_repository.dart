abstract class StorageRepository {
  /// Upload image bytes and return the download URL.
  Future<String> uploadImage({
    required String uid,
    required String postId,
    required List<int> bytes,
    required String mimeType,
  });

  /// Delete image at [storagePath].
  Future<void> deleteImage(String storagePath);
}
