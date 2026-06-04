import 'package:flutter/material.dart';

/// Pill stats bottom của StreakScreen — match Figma `269:1992`.
///
/// Layout: " N Meep | Xd chuỗi"
/// - Số (N / Xd): WHITE Nunito Bold 12
/// - Chữ (Meep / chuỗi): WHITE 48% alpha Nunito Bold 12
/// - Separator "|": Inter SemiBold 10 WHITE 48% alpha
/// - Container: bg `#5857546e`, cornerRadius 12, padding 8/11
class StreakStatsPill extends StatelessWidget {
  const StreakStatsPill({
    super.key,
    required this.totalMoments,
    required this.currentStreak,
  });

  final int totalMoments;
  final int currentStreak;

  static const _bgFill = Color(0x6E585754);
  static const _muted = Color(0x7AFFFFFF); // white 48%

  static const _numberStyle = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 16 / 12,
    color: Color(0xFFFFFFFF),
  );

  static const _labelStyle = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 16 / 12,
    color: _muted,
  );

  static const _sepStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: _muted,
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$totalMoments Meep, chuỗi $currentStreak ngày',
      child: Container(
        decoration: BoxDecoration(
          color: _bgFill,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        child: RichText(
          text: TextSpan(
            style: _numberStyle,
            children: [
              TextSpan(text: ' $totalMoments'),
              const TextSpan(text: ' Meep ', style: _labelStyle),
              const TextSpan(text: '|', style: _sepStyle),
              TextSpan(text: ' ${currentStreak}d'),
              const TextSpan(text: ' chuỗi ', style: _labelStyle),
            ],
          ),
        ),
      ),
    );
  }
}
