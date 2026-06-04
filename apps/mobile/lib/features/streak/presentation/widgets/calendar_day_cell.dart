import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Một ô trong [StreakCalendar]. Match Figma `269:1990` cell variants.
///
/// 4 trạng thái (priority): empty (other month) → today+post → today → post → no-post.
/// - `imageUrl != null`: render thumbnail (CachedNetworkImage) cornerRadius 7
/// - `imageUrl == null && isInMonth`: render dot 11×11 ở center
/// - `!isInMonth`: render spacer (transparent)
/// - `isToday`: overlay stroke 1px `#656565` (over thumbnail hoặc background light)
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.isInMonth,
    required this.isToday,
    this.imageUrl,
    this.onTap,
  });

  /// Day thuộc tháng đang xem (false = padding day từ tháng khác).
  final bool isInMonth;

  /// Ngày hôm nay (local timezone).
  final bool isToday;

  /// URL ảnh thumbnail nếu day có post; null = no post.
  final String? imageUrl;

  /// Tap handler. Null khi cell không tappable (empty / no-post).
  final VoidCallback? onTap;

  static const _dotColor = Color(0x6E585754);
  static const _todayStroke = Color(0xFF656565);
  static const _todayFill = Color(0xFFC4C4C4);

  @override
  Widget build(BuildContext context) {
    if (!isInMonth) {
      return const SizedBox(width: 37, height: 35);
    }

    final hasPost = imageUrl != null && imageUrl!.isNotEmpty;
    Widget content;

    if (hasPost) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: _todayFill),
          errorWidget: (_, __, ___) => Container(color: _todayFill),
        ),
      );
    } else if (isToday) {
      content = Container(
        decoration: BoxDecoration(
          color: _todayFill,
          borderRadius: BorderRadius.circular(7),
        ),
      );
    } else {
      content = Center(
        child: Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: _dotColor,
            borderRadius: BorderRadius.circular(7),
          ),
        ),
      );
    }

    final cell = SizedBox(
      width: 37,
      height: 35,
      child: Stack(
        children: [
          Positioned.fill(child: content),
          if (isToday)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: _todayStroke, width: 1),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return cell;
    return Semantics(
      button: true,
      label: 'Xem ảnh ngày',
      child: GestureDetector(onTap: onTap, child: cell),
    );
  }
}
