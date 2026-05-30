import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:meep/features/feed/application/caption_service.dart';
import 'package:meep/features/feed/application/weather_code_mapper.dart';
import 'package:meep/features/feed/data/post.dart';

class CaptionServiceImpl implements CaptionService {
  // Session-level geocode cache: last (lat, lng) → address string
  double? _cachedLat;
  double? _cachedLng;
  String? _cachedAddress;

  static const _geocodeCacheThresholdM = 100.0;
  static const _timeoutSeconds = 5;

  @override
  Future<String> resolve(CaptionType type) async {
    switch (type) {
      case CaptionType.text:
        return '';
      case CaptionType.time:
        return DateFormat('HH:mm').format(DateTime.now());
      case CaptionType.location:
        return _resolveLocation();
      case CaptionType.weather:
        return _resolveWeather();
      case CaptionType.music:
        return '♪ Đang phát nhạc';
      case CaptionType.star:
        return '⭐ Ngôi sao';
      case CaptionType.streak:
        return '🔥 Streak'; // TODO: link Streak module
    }
  }

  Future<String> _resolveLocation() async {
    try {
      final pos = await _getPosition();
      if (pos == null) return '📍 ...';
      return await _geocode(pos.latitude, pos.longitude);
    } catch (_) {
      return '📍 ...';
    }
  }

  Future<String> _resolveWeather() async {
    try {
      final pos = await _getPosition();
      if (pos == null) return '🌤️ ...';

      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${pos.latitude}&longitude=${pos.longitude}'
        '&current_weather=true',
      );
      final res =
          await http.get(uri).timeout(const Duration(seconds: _timeoutSeconds));
      if (res.statusCode != 200) return '🌤️ ...';

      final body = json.decode(res.body) as Map<String, dynamic>;
      final cw = body['current_weather'] as Map<String, dynamic>;
      final code = (cw['weathercode'] as num).toInt();
      final temp = (cw['temperature'] as num).round();
      return '${WeatherCodeMapper.toEmoji(code)} ${WeatherCodeMapper.toLabel(code)} $temp°C';
    } catch (_) {
      return '🌤️ ...';
    }
  }

  Future<Position?> _getPosition() async {
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: _timeoutSeconds),
      ),
    );
  }

  Future<String> _geocode(double lat, double lng) async {
    // Use cached result if position hasn't moved significantly
    if (_cachedLat != null && _cachedLng != null && _cachedAddress != null) {
      final dist = Geolocator.distanceBetween(
        _cachedLat!,
        _cachedLng!,
        lat,
        lng,
      );
      if (dist < _geocodeCacheThresholdM) return _cachedAddress!;
    }

    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?lat=$lat&lon=$lng&format=json&accept-language=vi',
    );
    final res = await http.get(
      uri,
      headers: {'User-Agent': 'Meep-App/1.0'},
    ).timeout(const Duration(seconds: _timeoutSeconds));

    if (res.statusCode != 200) return '📍 ...';

    final body = json.decode(res.body) as Map<String, dynamic>;
    final address = body['address'] as Map<String, dynamic>? ?? {};

    final suburb = address['suburb'] as String?;
    final district = address['city_district'] as String?;
    final city = address['city'] as String? ?? address['state'] as String?;

    final parts = [suburb ?? district, city]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .take(2)
        .toList();

    final result = parts.isNotEmpty ? parts.join(', ') : '📍 ...';
    _cachedLat = lat;
    _cachedLng = lng;
    _cachedAddress = result;
    return result;
  }
}
