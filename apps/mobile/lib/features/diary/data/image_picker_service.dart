import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

/// Abstract image picker — wraps gallery pick + compress + return bytes.
///
/// Tách interface để test inject stub deterministic — `image_picker` cần
/// platform plugin, không stub được trong unit test. Pattern mirror với
/// `AvatarStorageClient`/`AvatarCompressor` ở Profile module.
abstract class ImagePickerService {
  /// Open gallery, user pick → compress → return bytes.
  /// Returns null khi user cancel.
  Future<Uint8List?> pickImage();
}

/// Production impl: gallery pick → `flutter_image_compress` → bytes.
class FlutterImagePickerService implements ImagePickerService {
  const FlutterImagePickerService();

  @override
  Future<Uint8List?> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    final compressed = await FlutterImageCompress.compressWithFile(
      picked.path,
      minWidth: 1024,
      minHeight: 1024,
      quality: 85,
      format: CompressFormat.jpeg,
    );
    if (compressed != null) return compressed;

    // Fallback: plugin trả null khi platform không hỗ trợ — caller enforce
    // size cap trên raw bytes.
    return picked.readAsBytes();
  }
}

/// Test fake: predictable behavior cho widget/controller test.
///
/// - `nextBytes`: trả bytes này; null mặc định = simulate cancel.
/// - `exceptionToThrow`: throw exception nếu set (test error path).
/// - `callCount`: track số lần `pickImage` được gọi.
class FakeImagePickerService implements ImagePickerService {
  Uint8List? nextBytes;
  Exception? exceptionToThrow;
  int callCount = 0;

  @override
  Future<Uint8List?> pickImage() async {
    callCount++;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return nextBytes;
  }
}
