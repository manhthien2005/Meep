import 'package:flutter/material.dart';

/// Parse 7-char hex string `#RRGGBB` thành [Color]. Trả `null` nếu input
/// null hoặc malformed.
///
/// Defensive — Space `colorHex` được server-validate (CF createSpace) nên
/// thực tế hiếm khi malformed. Tuy nhiên client vẫn handle gracefully để
/// không crash UI khi gặp data legacy/manual edit.
///
/// Caller cung cấp fallback theo context: badge dùng accent default,
/// list tile dùng bw700 placeholder, camera section dùng null (no border).
Color? parseHexColor(String? hex) {
  if (hex == null) return null;
  try {
    final clean = hex.replaceFirst('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  } catch (_) {
    return null;
  }
}
