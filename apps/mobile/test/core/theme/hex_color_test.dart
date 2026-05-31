import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/core/theme/hex_color.dart';

void main() {
  group('hexToColor', () {
    test('parse hex có dấu #', () {
      expect(hexToColor('#FF5733'), const Color(0xFFFF5733));
    });

    test('parse hex không dấu #', () {
      expect(hexToColor('00DEEE'), const Color(0xFF00DEEE));
    });

    test('lowercase OK', () {
      expect(hexToColor('#abcdef'), const Color(0xFFABCDEF));
    });

    test('trim whitespace', () {
      expect(hexToColor('  #FF5733  '), const Color(0xFFFF5733));
    });

    test('sai độ dài → fallback', () {
      expect(hexToColor('#FFF'), const Color(0xFF656C6D));
      expect(hexToColor('#FF573300'), const Color(0xFF656C6D));
    });

    test('ký tự lạ → fallback', () {
      expect(hexToColor('#GGGGGG'), const Color(0xFF656C6D));
      expect(hexToColor('not-a-color'), const Color(0xFF656C6D));
    });

    test('chuỗi rỗng → fallback', () {
      expect(hexToColor(''), const Color(0xFF656C6D));
    });

    test('custom fallback', () {
      expect(
        hexToColor('bad', fallback: const Color(0xFF000000)),
        const Color(0xFF000000),
      );
    });
  });
}
