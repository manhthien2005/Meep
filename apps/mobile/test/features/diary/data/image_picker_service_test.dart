import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/diary/data/image_picker_service.dart';

void main() {
  group('FakeImagePickerService — test contract', () {
    test('returns null khi cancel', () async {
      final svc = FakeImagePickerService();
      final result = await svc.pickImage();
      expect(result, isNull);
    });

    test('returns predefined bytes khi set', () async {
      final svc = FakeImagePickerService();
      final bytes = Uint8List.fromList(List.filled(100, 0xAB));
      svc.nextBytes = bytes;

      final result = await svc.pickImage();

      expect(result, isNotNull);
      expect(result!.lengthInBytes, 100);
    });

    test('throws khi exceptionToThrow set', () async {
      final svc = FakeImagePickerService();
      svc.exceptionToThrow = Exception('picker fail');

      expect(svc.pickImage, throwsException);
    });

    test('counts pickImage calls', () async {
      final svc = FakeImagePickerService();
      svc.nextBytes = Uint8List(50);

      await svc.pickImage();
      await svc.pickImage();

      expect(svc.callCount, 2);
    });
  });
}
