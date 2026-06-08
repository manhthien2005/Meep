import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

Future<bool> fixOrientationInPlace(String path) async {
  try {
    // keepExif: true so Flutter's codec can read orientation and rotate pixels.
    // keepExif: false strips the tag without guaranteeing pixel rotation on Android.
    final compressed = await FlutterImageCompress.compressWithFile(
      path,
      minWidth: 1080,
      minHeight: 1080,
      quality: 100,
      keepExif: true,
      format: CompressFormat.jpeg,
    );
    if (compressed == null) {
      return false;
    }

    // Decode with Flutter's EXIF-aware codec → pixels are already rotated
    // to the correct portrait orientation at this point.
    final codec = await ui.instantiateImageCodec(compressed);
    final frame = await codec.getNextFrame();
    final src = frame.image;

    // Re-render onto a canvas to bake the orientation into the pixel data
    // so the saved file needs no EXIF tag for correct display.
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(src, Offset.zero, Paint());
    final picture = recorder.endRecording();
    final baked = await picture.toImage(src.width, src.height);
    final png = await baked.toByteData(format: ui.ImageByteFormat.png);
    src.dispose();
    baked.dispose();
    picture.dispose();

    if (png == null) {
      return false;
    }
    await File(path).writeAsBytes(png.buffer.asUint8List());
    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> flipImageHorizontallyInPlace(String path) async {
  try {
    // keepExif: true so instantiateImageCodec can apply EXIF rotation before
    // we flip. With keepExif: false the tag is stripped and the codec gets
    // raw sensor pixels (landscape), making the flip direction wrong.
    final oriented = await FlutterImageCompress.compressWithFile(
      path,
      minWidth: 1080,
      minHeight: 1080,
      quality: 100,
      keepExif: true,
      format: CompressFormat.jpeg,
    );
    final bytes = oriented ?? await File(path).readAsBytes();

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

    if (png == null) {
      return false;
    }
    await File(path).writeAsBytes(png.buffer.asUint8List());
    return true;
  } catch (e) {
    return false;
  }
}
