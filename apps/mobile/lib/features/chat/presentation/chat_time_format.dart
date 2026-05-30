/// Timestamp formatting for chat surfaces (inbox preview + thread header).
///
/// Vietnamese, matches Figma: recent → "Vừa xong" / "x phút" / "x giờ",
/// older → "DD thg M".
library;

String formatInboxTimestamp(DateTime time, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final diff = ref.difference(time);

  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
  if (diff.inHours < 24 && ref.day == time.day) return '${diff.inHours} giờ';
  return '${time.day} thg ${time.month}';
}

/// Full date + time for the quoted-photo block header, e.g. "11 thg 4 lúc 14:30".
String formatQuotedPhotoTimestamp(DateTime time) {
  final hh = time.hour.toString().padLeft(2, '0');
  final mm = time.minute.toString().padLeft(2, '0');
  return '${time.day} thg ${time.month} lúc $hh:$mm';
}

/// Gap between two consecutive messages above which a centered time separator
/// is shown in the thread (Messenger/iMessage convention).
const threadSeparatorGap = Duration(hours: 1);

/// Centered time separator shown between message clusters in a thread.
///
/// Same day → "HH:mm"; older → "DD thg M lúc HH:mm".
String formatThreadSeparator(DateTime time, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final hh = time.hour.toString().padLeft(2, '0');
  final mm = time.minute.toString().padLeft(2, '0');
  final sameDay =
      ref.year == time.year && ref.month == time.month && ref.day == time.day;
  if (sameDay) return '$hh:$mm';
  return '${time.day} thg ${time.month} lúc $hh:$mm';
}
