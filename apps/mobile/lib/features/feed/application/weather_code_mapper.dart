abstract final class WeatherCodeMapper {
  static String toEmoji(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code == 45 || code == 48) return '🌫️';
    if (code >= 51 && code <= 67) return '🌧️';
    if (code >= 71 && code <= 77) return '❄️';
    if (code >= 80 && code <= 82) return '🌦️';
    if (code >= 95) return '⛈️';
    return '🌤️';
  }

  static String toLabel(int code) {
    if (code == 0) return 'Nắng';
    if (code <= 3) return 'Có mây';
    if (code == 45 || code == 48) return 'Sương mù';
    if (code >= 51 && code <= 67) return 'Mưa';
    if (code >= 71 && code <= 77) return 'Tuyết';
    if (code >= 80 && code <= 82) return 'Mưa rào';
    if (code >= 95) return 'Dông';
    return 'Trời đẹp';
  }
}
