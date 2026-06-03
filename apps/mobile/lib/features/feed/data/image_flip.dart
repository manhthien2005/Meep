import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Lật ngang (mirror) ảnh tại [path] in-place, ghi đè file gốc bằng
/// PNG đã flip.
///
/// Dùng cho ảnh chụp cam trước: Android `CameraController.takePicture()`
/// lưu file un-mirror (đúng physical scene), trong khi preview lại
/// selfie-mirror. Để file khớp với preview ng user thấy, flip lại bằng
/// `dart:ui` Canvas — KHÔNG cần `image` package.
///
/// File output là PNG (không phải JPEG). Pipeline `PostController.submit`
/// sau đó sẽ re-encode JPEG qua `flutter_image_compress`, nên format trung
/// gian PNG không ảnh hưởng output cuối.
///
/// Returns true nếu flip thành công, false nếu decode/encode fail (gọi
/// vẫn tiếp tục flow với file gốc un-mirror).
Future<bool> flipImageHorizontallyInPlace(String path) async {
  try {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final src = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.translate(src.width.toDouble(), 0);
    canvas.scale(-1, 1);
    canvas.drawImage(src, Offset.zero, Paint());
    final picture = recorder.endRecording();

    final flipped = await picture.toImage(src.width, src.height);
    final png = await flipped.toByteData(format: ui.ImageByteFormat.png);
    src.dispose();
    flipped.dispose();
    picture.dispose();

    if (png == null) return false;
    await File(path).writeAsBytes(png.buffer.asUint8List());
    return true;
  } catch (e) {
    debugPrint('[flipImageHorizontallyInPlace] failed: $e');
    return false;
  }
}
