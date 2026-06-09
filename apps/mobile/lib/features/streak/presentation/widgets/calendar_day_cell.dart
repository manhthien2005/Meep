import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';

/// Một ô trong [StreakCalendar]. Match Figma `269:1990` cell variants.
///
/// Priority render: empty (other month) → post thumbnail → today CTA
/// (turquoise + dấu cộng nếu hôm nay chưa chụp) → today no-CTA highlight →
/// dot (no post other day).
/// - `imageUrl != null`: render thumbnail (CachedNetworkImage) cornerRadius 7
/// - `isToday && imageUrl == null`: render khối turquoise + icon `add` —
///   CTA "chụp hôm nay", tap → callback (parent điều hướng về camera).
/// - `imageUrl == null && isInMonth && !isToday`: dot 11×11 ở center
/// - `!isInMonth`: spacer (transparent)
/// - Khi `isToday` có post: overlay stroke 1px `#656565` cho rõ ngày hiện tại.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.isInMonth,
    required this.isToday,
    this.imageUrl,
    this.onTap,
    this.isLoading = false,
    this.width = 37,
    this.height = 35,
  });

  /// Day thuộc tháng đang xem (false = padding day từ tháng khác).
  final bool isInMonth;

  /// Ngày hôm nay (local timezone).
  final bool isToday;

  /// URL ảnh thumbnail nếu day có post; null = no post.
  final String? imageUrl;

  /// Render placeholder thay vì trạng thái thật trong lúc tải tháng.
  final bool isLoading;

  final double width;
  final double height;

  /// Tap handler:
  /// - Day có post → mở PhotoDetailScreen.
  /// - Today no-post → điều hướng về `/home` (camera).
  /// - Day khác no-post → null (cell không tappable).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (!isInMonth) {
      return SizedBox(width: width, height: height);
    }

    final hasPost = imageUrl != null && imageUrl!.isNotEmpty;
    final showTodayCta = isToday && !hasPost;
    Widget content;

    if (isLoading) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.bw700.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(7),
        ),
      );
    } else if (hasPost) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              Container(color: AppColors.turquoise600.withValues(alpha: 0.2)),
          errorWidget: (_, __, ___) =>
              Container(color: AppColors.turquoise600.withValues(alpha: 0.2)),
        ),
      );
    } else if (showTodayCta) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.bw800.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.turquoise500, width: 1.2),
        ),
        child: const Center(
          child: Icon(Icons.add, size: 18, color: AppColors.turquoise400),
        ),
      );
    } else {
      content = Center(
        child: Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: AppColors.bw700.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(7),
          ),
        ),
      );
    }

    // Stroke chỉ vẽ khi today có post — để phân biệt ngày hôm nay trong dãy
    // thumbnail. Today CTA đã có màu turquoise nổi bật, không cần stroke.
    final showStroke = isToday && hasPost && !isLoading;

    final cell = SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(child: content),
          if (showStroke)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.turquoise500, width: 1),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
        ],
      ),
    );

    if (isLoading || onTap == null) return cell;
    final label = showTodayCta ? 'Chụp khoảnh khắc hôm nay' : 'Xem ảnh ngày';
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(onTap: onTap, child: cell),
    );
  }
}
