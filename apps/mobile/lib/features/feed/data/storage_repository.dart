abstract class StorageRepository {
  /// Upload image bytes and return the download URL.
  ///
  /// [fileName] selects the object name under the post folder.
  /// Single mode uses the default `photo.jpg`; dual mode passes
  /// `back.jpg` / `front.jpg` to store both lenses under one postId.
  Future<String> uploadImage({
    required String uid,
    required String postId,
    required List<int> bytes,
    required String mimeType,
    String fileName,
  });

  /// Delete image at [storagePath].
  Future<void> deleteImage(String storagePath);
}
