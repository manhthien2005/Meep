import 'package:flutter/material.dart';

/// Parse hex color string ("#RRGGBB" hoặc "RRGGBB") → [Color].
///
/// Trả về [fallback] nếu chuỗi không hợp lệ (sai độ dài / ký tự lạ) thay vì
/// throw — tránh crash UI khi colorHex từ nguồn ngoài (Firestore, custom)
/// bị malformed.
Color hexToColor(String hex, {Color fallback = const Color(0xFF656C6D)}) {
  var cleaned = hex.trim();
  if (cleaned.startsWith('#')) cleaned = cleaned.substring(1);
  if (cleaned.length != 6) return fallback;
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return fallback;
  return Color(0xFF000000 | value);
}
